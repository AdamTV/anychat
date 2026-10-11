import 'dart:async';
import 'dart:collection';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/notifications/notifications_util.dart';
import 'package:anychat/widgets/chat_screen_utility_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disposables/disposables.dart';
import 'package:flutter/cupertino.dart';
import '../database/anychat_auth.dart';
import '../database/anychat_message.dart';
import '../database/anychat_user.dart';
import 'combined_locale_info.dart';
import '../database/conversation_info.dart';

class RemoteNotificationObserver extends ChangeNotifier
    with WidgetsBindingObserver, Disposable {
  final List<AnyChatConversationWidget> _conversationWidgets = [];

  UnmodifiableListView<AnyChatConversationWidget> get conversationWidgets =>
      UnmodifiableListView(_conversationWidgets);

  AppLifecycleState _notification = AppLifecycleState.resumed;

  StreamSubscription<QuerySnapshot>? _conversationSubscription;

  final Map<String, StreamSubscription<QuerySnapshot>?>
      _chatMessageSubscriptions = {};

  static final RemoteNotificationObserver _instance =
      RemoteNotificationObserver._internal();

  factory RemoteNotificationObserver() {
    return _instance;
  }
  RemoteNotificationObserver._internal();

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> cancelSubscriptions() async {
    await _conversationSubscription?.cancel();
    _chatMessageSubscriptions.forEach((key, value) async {
      await value?.cancel();
    });
  }

  @override
  void dispose() {
    logger.i('Disposing NotificationObserver');
    cancelSubscriptions().then((value) => {
          WidgetsBinding.instance.removeObserver(this),
          isDisposed = true,
          super.dispose()
        });
  }

  @override
  bool isDisposed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    logger.i('AppLifeCycle changed from $_notification to $state');
    _notification = state;
  }

  Future<void> initConversationSubscriptions() async {
    await initConversationInfo();
    _conversationSubscription ??=
        loadAllConversations().listen(_updateConversations);
  }

  Future<void> initChatSubscriptions() async {
    await initConversationInfo();
    for (var conversationInfo in AnyChatAuth.currentUser.conversations) {
      _chatMessageSubscriptions.putIfAbsent(
          conversationInfo.id,
          () => loadAllChatMessages(conversationInfo.id)
              .listen(_updateChatMessages));
    }
  }

  Stream<QuerySnapshot> loadAllConversations() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: AnyChatAuth.currentUser.id)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> loadAllChatMessages(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> initConversationInfo() async {
    AnyChatAuth.currentUser.conversations =
        await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser.id);
  }

  Future<void> _updateChatMessages(QuerySnapshot snapshot) async {
    var messages = snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).toList();
    AnyChatMessage message;
    if (messages.isNotEmpty) {
      message = messages.last;
    } else {
      logger.i("messages are empty");
      return;
    }
    var conversation = Conversation.fromSnapshot(
        await snapshot.docs.last.reference.parent.parent!.get());
    logger.i(
        'user ${AnyChatAuth.currentUser.id} received notification for ${conversation.id} while applicationLifeCycle = $_notification');
    final userIds = <String>{...conversation.participants, message.senderId};
    final loadedUsers = await AnyChatUser.getUsersByIds(userIds);
    final usersById = {for (final user in loadedUsers) user.id: user};
    for (final userId in userIds) {
      usersById.putIfAbsent(userId, () => AnyChatUser.deletedUser(userId));
    }
    final chatters =
        conversation.participants.map((userId) => usersById[userId]!).toList();
    final sender = usersById[message.senderId]!;
    _conversationWidgets
        .add(AnyChatConversationWidget(chatters, conversation, message));
    notifyListeners();

    if (message.senderId != AnyChatAuth.currentUser.id &&
        _notification != AppLifecycleState.resumed) {
      _sendNotification(conversation, sender, message.text);
    }
  }

  void addChatMessageSubscription(String conversationId) {
    _chatMessageSubscriptions.putIfAbsent(conversationId,
        () => loadAllChatMessages(conversationId).listen(_updateChatMessages));
  }

  Future<void> loadConversations() async {
    AnyChatAuth.currentUser.conversations =
        await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser.id);
    final conversations = await Conversation.getConversationsByIds(
      AnyChatAuth.currentUser.conversations.map((info) => info.id),
    );
    final conversationsById = {
      for (final conversation in conversations) conversation.id: conversation,
    };
    final orderedConversations = AnyChatAuth.currentUser.conversations
        .map((info) => conversationsById[info.id])
        .whereType<Conversation>()
        .toList();
    final currentUserId = AnyChatAuth.currentUser.id;
    final userIds = orderedConversations
        .expand((conversation) => conversation.participants)
        .where((id) => id != currentUserId)
        .toSet();

    final loadedUsers = await AnyChatUser.getUsersByIds(userIds);
    final usersById = {for (final user in loadedUsers) user.id: user};
    for (final userId in userIds) {
      usersById.putIfAbsent(userId, () => AnyChatUser.deletedUser(userId));
    }

    var addedConversation = false;
    for (final conversation in orderedConversations) {
      final chatters = conversation.participants
          .where((id) => id != currentUserId)
          .map((id) => usersById[id]!)
          .toList();
      if (chatters.isEmpty || conversation.timestamp == null) {
        continue;
      }

      final message =
          await Conversation.getLatestMessageByConversationId(conversation.id);
      if (message == null) {
        continue;
      }
      _conversationWidgets
          .add(AnyChatConversationWidget(chatters, conversation, message));
      addedConversation = true;
    }
    if (addedConversation) {
      notifyListeners();
    }
  }

  /// Loads the chatters of [conversation] (participants other than the
  /// current user) in one batched read; unknown users become placeholder
  /// records.
  static Future<List<AnyChatUser>> loadChatters(
      Conversation conversation) async {
    final currentUserId = AnyChatAuth.currentUser.id;
    final chatterIds =
        conversation.participants.where((id) => id != currentUserId).toSet();
    final loadedUsers = await AnyChatUser.getUsersByIds(chatterIds);
    final usersById = {for (final user in loadedUsers) user.id: user};
    for (final id in chatterIds) {
      usersById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
    }
    return chatterIds.map((id) => usersById[id]!).toList();
  }

  Future<void> _updateConversations(QuerySnapshot snapshot) async {
    final conversations = getConversationsFromQuery(snapshot);
    if (conversations.isEmpty) {
      return;
    }
    final conversation = conversations.last;
    final currentUserId = AnyChatAuth.currentUser.id;
    if (!conversation.participants.contains(currentUserId)) {
      logger.d('conversation does not include current user $currentUserId');
      return;
    }

    final chatters = await loadChatters(conversation);
    final firstChatter =
        chatters.isEmpty ? AnyChatAuth.currentUser : chatters.first;

    if (!AnyChatAuth.currentUser.conversations
        .any((element) => element.id == conversation.id)) {
      AnyChatAuth.currentUser.conversations.add(ConversationInfo(
        conversation.id,
        AnyChatAuth.currentUser.language,
        firstChatter.language,
      ));
    }

    var message =
        await Conversation.getLatestMessageByConversationId(conversation.id);
    if (message == null) {
      await RemoteNotificationObserver().initChatSubscriptions();
      message = AnyChatMessage(
        '',
        Timestamp.now(),
        firstChatter.id,
        localizationOf(Utilities().globalKey.currentContext).newConversation,
        null,
      );
    }

    if (chatters.isNotEmpty && conversation.timestamp != null) {
      _conversationWidgets
          .add(AnyChatConversationWidget(chatters, conversation, message));
      notifyListeners();
    }
  }

  List<Conversation> getConversationsFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return Conversation.fromSnapshot(doc);
    }).toList();
  }

  void _sendNotification(
      Conversation conversation, AnyChatUser sender, String text) async {
    if (text.contains(localizationOf(Utilities().globalKey.currentContext!)
        .isCallingYouOnAnyChat)) {
      await NotificationUtils.showCallNotification(
          text, conversation.id.hashCode, 42, conversation.id);
    } else {
      await NotificationUtils.createMessagingNotification(
        channelKey: 'chats',
        groupKey: conversation.id,
        chatName: localizationOf(null).newMessage,
        username: sender.displayName,
        largeIcon: sender.photoUrl,
        message: text,
      );
    }
  }
}
