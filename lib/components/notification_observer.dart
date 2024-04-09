import 'dart:async';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/services/notifications/notifications_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disposables/disposables.dart';
import 'package:flutter/cupertino.dart';
import '../database/anychat_auth.dart';
import '../database/anychat_message.dart';
import '../database/anychat_user.dart';
import 'combined_locale_info.dart';
import '../database/conversation_info.dart';

class NotificationObserver with WidgetsBindingObserver, Disposable {
  AppLifecycleState _notification = AppLifecycleState.resumed;
  StreamSubscription<QuerySnapshot>? _conversationSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>?>
      _chatMessageSubscriptions = {};

  static final NotificationObserver _instance =
      NotificationObserver._internal();
  factory NotificationObserver() {
    return _instance;
  }
  NotificationObserver._internal();

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    logger.i('Disposing NotificationObserver');
    WidgetsBinding.instance.removeObserver(this);
    isDisposed = true;
  }

  @override
  bool isDisposed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    logger.i('AppLifeCycle changed from $_notification to $state');
    _notification = state;
  }

  Future<void> initConversationSubscriptions(
      Future<void> Function(QuerySnapshot snapshot)
          updateConversationCallback) async {
    _conversationSubscription ??=
        loadAllConversations().listen(updateConversationCallback);
  }

  Future<void> initChatSubscriptions() async {
    await initConversationInfo();
    for (var conversationInfo in AnyChatAuth.currentUser.conversations) {
      _chatMessageSubscriptions.putIfAbsent(
          conversationInfo.id,
          () => loadAllChatMessages(conversationInfo.id)
              .listen(_sendNotification));
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

  Future<void> _sendNotification(QuerySnapshot snapshot) async {
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
    await handleDbUpdates(conversation, message);
    if (message.senderId != AnyChatAuth.currentUser.id) {
      var sender = await AnyChatUser.getUserById(message.senderId);
      var text = conversation.participants.contains(message.senderId)
          ? "${message.text}\n\n"
              "${await Utilities().getGoogleTranslation(AnyChatAuth.currentUser.language, message.text)}"
          : localizationOf(Utilities().globalKey.currentContext!)
              .thisPersonHasLeftConversation;
      if (_notification != AppLifecycleState.resumed) {
        if (text.contains(localizationOf(Utilities().globalKey.currentContext!)
            .isCallingYouOnAnyChat)) {
          await NotificationUtils.showCallNotification(
              message.text,
              conversation.id.hashCode, 42, conversation.id);
        } else {
          await NotificationUtils.createMessagingNotification(
            channelKey: 'chats',
            groupKey: conversation.id,
            chatName: localizationOf(null).newMessage,
            username: sender.displayName,
            largeIcon: sender.photoUrl,
            message: message.text,
          );
        }
      }
    }
  }

  Future<void> handleDbUpdates(
      Conversation conversation, AnyChatMessage message) async {
    if (AnyChatAuth.currentUser.conversations
        .any((element) => element.id == conversation.id)) {
      var chatters = <AnyChatUser>[];
      if (conversation.participants.length == 1) {
        try {
          chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
              .collection("users")
              .doc(message.senderId)
              .get()));
        } catch (e) {
          chatters.add(AnyChatUser.deletedUser(message.senderId));
        }
        // }
      } else {
        var chatterIds = conversation.participants
            .where((element) => element != AnyChatAuth.currentUser.id);
        for (var id in chatterIds) {
          if (chatters.where((element) => element.id == id).isEmpty) {
            try {
              chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore
                  .instance
                  .collection("users")
                  .doc(id)
                  .get()));
            } catch (e) {
              chatters.add(AnyChatUser.deletedUser(message.senderId));
            }
          }
        }
        if (AnyChatAuth.currentUser.conversations
            .any((element) => element.id == conversation.id)) {
          var info = AnyChatAuth.currentUser.conversations
              .firstWhere((element) => element.id == conversation.id);
          final language = message.senderId == AnyChatAuth.currentUser.id
              ? info.outgoingLanguage
              : info.incomingLanguage;
          var truncatedText = message.text;
          if (truncatedText.length > 20) {
            truncatedText = "${truncatedText.substring(0, 19)}...";
          }
          final text = conversation.participants.contains(message.senderId)
              ? "$truncatedText\n\n"
                  "${await Utilities().getGoogleTranslation(language ?? localeName, truncatedText)}"
              : localizationOf(Utilities().globalKey.currentContext)
                  .thisPersonHasLeftConversation;

          if (chatters.isNotEmpty && conversation.timestamp != null) {
            ConversationsScreen().updateState(chatters, conversation, text);
          }
        }
      }
    }
  }

  void addChatMessageSubscription(String conversationId) {
    _chatMessageSubscriptions.putIfAbsent(conversationId,
        () => loadAllChatMessages(conversationId).listen(_sendNotification));
  }
}
