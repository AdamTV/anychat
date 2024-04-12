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

class RemoteNotificationObserver extends ChangeNotifier with WidgetsBindingObserver, Disposable {

  final List<AnyChatConversationWidget> _conversationWidgets = [];

  UnmodifiableListView<AnyChatConversationWidget> get conversationWidgets => UnmodifiableListView(_conversationWidgets);

  AppLifecycleState _notification = AppLifecycleState.resumed;

  StreamSubscription<QuerySnapshot>?
  _conversationSubscription;

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
    _chatMessageSubscriptions.forEach((key, value) async { await value?.cancel();});
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
    List<AnyChatUser> chatters = [];

    for(var chatter in conversation.participants) {
        chatters.add(await AnyChatUser.getUserById(chatter));
    }
     var sender = await AnyChatUser.getUserById(message.senderId);
      var text = conversation.participants.contains(message.senderId)
          ? "${message.text}\n\n"
              "${await Utilities().getGoogleTranslation(AnyChatAuth.currentUser.language, message.text)}"
          : localizationOf(Utilities().globalKey.currentContext!)
              .thisPersonHasLeftConversation;

      _conversationWidgets.add(AnyChatConversationWidget(chatters, conversation, message));
      notifyListeners();
      await handleDbUpdates(conversation, message);


      if (message.senderId != AnyChatAuth.currentUser.id && _notification != AppLifecycleState.resumed) {
       _sendNotification(conversation, sender, message.text);
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
        // if (AnyChatAuth.currentUser.conversations
        //     .any((element) => element.id == conversation.id)) {
        //   var info = AnyChatAuth.currentUser.conversations
        //       .firstWhere((element) => element.id == conversation.id);
        //   final language = message.senderId == AnyChatAuth.currentUser.id
        //       ? info.outgoingLanguage
        //       : info.incomingLanguage;
        //   var truncatedText = message.text;
        //   if (truncatedText.length > 20) {
        //     truncatedText = "${truncatedText.substring(0, 19)}...";
        //   }
        //   final text = conversation.participants.contains(message.senderId)
        //       ? "$truncatedText\n\n"
        //           "${await Utilities().getGoogleTranslation(language ?? localeName, truncatedText)}"
        //       : localizationOf(Utilities().globalKey.currentContext)
        //           .thisPersonHasLeftConversation;
        // }
      }
    }
  }

  void addChatMessageSubscription(String conversationId) {
    _chatMessageSubscriptions.putIfAbsent(conversationId,
        () => loadAllChatMessages(conversationId).listen(_updateChatMessages));
  }

  Future<void> loadConversations() async {
    var ids = <String>[];
    AnyChatAuth.currentUser.conversations =
    await ConversationInfo.getAllConversationInfo(
        AnyChatAuth.currentUser.id);
    for (var conversation in AnyChatAuth.currentUser.conversations){
      Conversation temp;
      temp = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversation.id)
          .get());
    AnyChatMessage? message;
      if (!ids.contains(temp.id)) {
        logger.d(temp.id);
        ids.add(temp.id);
        List<String?> users = temp.participants;
        logger.d(AnyChatAuth.currentUser.id);
        var chatters = <AnyChatUser>[];
        String? text;
        var snapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(temp.id)
            .collection("messages")
            .orderBy('timestamp', descending: false)
            .get();
        for (var i = 0; i < temp.participants.length; i++) {
          if (users[i] != AnyChatAuth.currentUser.id) {
            try {
              var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
                  .instance
                  .collection("users")
                  .doc(users[i])
                  .get());
              if (chatters
                  .where((element) => element.id == chatter.id).isEmpty) {
                chatters.add(chatter);
              }
            } catch (e) {
              logger.d(e);
            }
            AnyChatMessage message;
            try {
              message = snapshot.docs.map((DocumentSnapshot doc) {
                return AnyChatMessage.fromSnapshot(doc);
              }).last;
              var info = AnyChatAuth.currentUser.conversations.firstWhere(
                      (element) =>
                  element.id == AnyChatAuth.currentConversation!.id);
              final language = message.senderId == AnyChatAuth.currentUser.id
                  ? info.outgoingLanguage
                  : info.incomingLanguage;
              text = "${message.text}\n\n"
                  "${await Utilities().getGoogleTranslation(language, message.text)}";
            } catch (e) {
              logger.d(e);
            }
            logger.d('adding conversation: ${temp.id}');
          }
          logger.d('test widget added');
        }
        // conversationWidgets
        //     .removeWhere((element) => element.key == Key(temp.id));
        // if (chatters.length == 1) {
        //   var messages = snapshot.docs.map((DocumentSnapshot doc) {
        //     return AnyChatMessage.fromSnapshot(doc);
        //   });
        //   var message = messages.lastWhere((element) =>
        //   element.text.compareTo(
        //       AppLocalizations.of(context).thisPersonHasLeftConversation) ==
        //       0);
        //   chatters.clear();
        //   chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
        //       .collection("users")
        //       .doc(message.senderId)
        //       .get()));
        //   text = message.text;
        // }
        if (chatters.isNotEmpty && temp.timestamp != null) {
          message?.text;
          _conversationWidgets.add(AnyChatConversationWidget(chatters, temp, message!));
          notifyListeners();
        }
      }
    }
  }

  Future<void> _updateConversations(QuerySnapshot snapshot) async {
    var conversations = getConversationsFromQuery(snapshot);
    logger.d('in _updateConversations');
    if (conversations.isEmpty) {
      logger.d('conversation snapshot was empty');
      return;
    }
    Conversation conversation = conversations.last;
    AnyChatUser? firstChatter = AnyChatAuth.currentUser;
    try {
      firstChatter = await AnyChatUser.getUserById(conversation.participants
          .firstWhere((element) => element != AnyChatAuth.currentUser.id));
    } catch (e) {
      logger.e(e);
    }
    if (AnyChatAuth.currentConversation == null) {

    }
    if (!AnyChatAuth.currentUser.conversations
        .any((element) => element.id == conversation.id)) {
      if (conversation.participants.contains(AnyChatAuth.currentUser.id)) {
        AnyChatAuth.currentUser.conversations.add(ConversationInfo(
            conversation.id,
            AnyChatAuth.currentUser.language,
            firstChatter!.language));
      } else {
        logger
            .d('none of currentUser conversations ID are ${conversation.id}.');
        return;
      }
    }
    if (!conversation.participants.contains(AnyChatAuth.currentUser.id)) {
      logger.d(
          'conversation participants does not contain ${AnyChatAuth.currentUser.id}');
      return;
    }
    String? text;
    List<String?> users = conversation.participants;
    var chatters = <AnyChatUser>[];
    AnyChatMessage? message;
    for (var i = 0; i < conversation.participants.length; i++) {
      logger.d(AnyChatAuth.currentUser.id);
      if (users[i] != AnyChatAuth.currentUser.id) {
        var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection("users")
            .doc(users[i])
            .get());
        if (chatters.where((element) => element.id == chatter.id).isEmpty) {
          chatters.add(chatter);
        }
        var msgSnapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversation.id)
            .collection("messages")
            .orderBy('timestamp', descending: false)
            .get();
        // try {
        if (msgSnapshot.docs.isNotEmpty) {
          message = AnyChatMessage.fromSnapshot(msgSnapshot.docs.last);
        } else {
          await RemoteNotificationObserver().initChatSubscriptions();
          message = AnyChatMessage("", Timestamp.now(), chatter.id,
              localizationOf(Utilities().globalKey.currentContext).newConversation, null);
        }
        try {
          var info = AnyChatAuth.currentUser.conversations
              .firstWhere((element) => element.id == conversation.id);
          final language = message.senderId == AnyChatAuth.currentUser.id
              ? info.outgoingLanguage
              : info.incomingLanguage;
          var truncatedText = message.text;
          if (truncatedText.length > 20) {
            truncatedText = "${truncatedText.substring(0, 19)}...";
          }
          text = "$truncatedText\n\n"
              "${await Utilities().getGoogleTranslation(language, truncatedText)}";
        } catch (e) {
          logger.d("New Conversation: $conversation.id");
          text = localizationOf(
              Utilities().globalKey.currentContext!)
              .newConversation;
        }
        // } catch (e) {
        //   throw e;
        // }
      }
    }
    // if (AnyChatAuth.currentUser.conversations != null &&
    //     !AnyChatAuth.currentUser.conversations
    //         .any((element) => element.id == conversation.id)) {
    //   if (conversation.participants.contains(AnyChatAuth.currentUser.id)) {
    //     AnyChatAuth.currentUser.conversations.add(ConversationInfo.fromSnapshot(
    //         await FirebaseFirestore.instance
    //             .collection("users")
    //             .doc(AnyChatAuth.currentUser.id)
    //             .collection('conversations')
    //             .doc(conversation.id)
    //             .get()));
    //   }
    // }

    // if (chatters.length == 1) {
    //   var message = messages.lastWhere((element) =>
    //       element.text.compareTo(
    //           AppLocalizations.of(context).thisPersonHasLeftConversation) ==
    //       0);
    //   chatters.clear();
    //   chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
    //       .collection("users")
    //       .doc(message.senderId)
    //       .get()));
    // }

    if (chatters.isNotEmpty && conversation.timestamp != null && text != null) {
      _conversationWidgets.add(AnyChatConversationWidget(
          chatters, conversation, message!));
      notifyListeners();
    }
  }

  List<Conversation> getConversationsFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return Conversation.fromSnapshot(doc);
    }).toList();
  }
  void _sendNotification(Conversation conversation, AnyChatUser sender, String text) async {
    if (text.contains(localizationOf(Utilities().globalKey.currentContext!)
        .isCallingYouOnAnyChat)) {
      await NotificationUtils.showCallNotification(
          text,
          conversation.id.hashCode, 42, conversation.id);
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

