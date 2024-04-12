import 'dart:collection';

import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_message.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/database/conversation_info.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/widgets/chat_screen_utility_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../components/combined_locale_info.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Slidable> conversationWidgets = [];
  bool _isLoadedConversations = false;

  @override
  initState() {
    super.initState();
    readConversations();
    _handleRefresh();
    // RemoteNotificationObserver().initConversationSubscriptions(_updateConversations);
  }

  createConversations() {
    if (RemoteNotificationObserver().conversationWidgets.isEmpty) return;
    var mostRecentState = RemoteNotificationObserver().conversationWidgets.last;
    setState((){
      insertSorted(
        mostRecentState);
      _isLoadedConversations = true;
      });
    }

  readConversations() async {
    await RemoteNotificationObserver().initChatSubscriptions();
  }

  Future<void> updateConversations(QuerySnapshot snapshot) async {
    if (conversationWidgets.isEmpty) {
      await RemoteNotificationObserver().loadConversations();
      return;
    }
    var conversations =
        RemoteNotificationObserver().getConversationsFromQuery(snapshot);
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
      logger.d(e);
    }
    if (AnyChatAuth.currentConversation == null) {
      await RemoteNotificationObserver().initConversationInfo();
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
    List<String?> users = conversation.participants;
    var chatters = <AnyChatUser>[];
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
        AnyChatMessage message;
        // try {
        if (msgSnapshot.docs.isNotEmpty) {
          message = AnyChatMessage.fromSnapshot(msgSnapshot.docs.last);
        } else {
          RemoteNotificationObserver()
              .addChatMessageSubscription(conversation.id);

          message = AnyChatMessage(
              "",
              Timestamp.now(),
              chatter.id,
              localizationOf(
                      mounted ? context : Utilities().globalKey.currentContext)
                  .newConversation,
              null);
        }
        try {
          var info = AnyChatAuth.currentUser.conversations
              .firstWhere((element) => element.id == conversation.id);
          final language = message.senderId == AnyChatAuth.currentUser.id
              ? info.outgoingLanguage
              : info.incomingLanguage;
        } catch (e) {
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

    if (chatters.isNotEmpty && conversation.timestamp != null) {
      var state = RemoteNotificationObserver().conversationWidgets.last;
      setState(() {
        insertSorted(state);
        _isLoadedConversations = true;
      });
    }
    if (!conversationWidgets
        .any((element) => element.key == Key(conversation.id))) {
      RemoteNotificationObserver().addChatMessageSubscription(conversation.id);

      logger.d('added conversation widget');
      logger.d(conversationWidgets);
    }
  }

  deleteConversations() {}

  @override
  Widget build(BuildContext context) {
    final remoteNotifications =
        Provider.of<RemoteNotificationObserver>(context);
    createConversations();
    logger.d(
        'in build -> conversationWidgets.length: ${conversationWidgets.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text(localizationOf(context).title),
        actions: <Widget>[
          if (conversationWidgets.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: localizationOf(context).createConversation,
              onPressed: () {
                AnyChatAuth.currentConversation = null;
                NavigationService().pushNamed("/searchChatter");
              },
            ),
        ],
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                localizationOf(context).title,
              ),
            ),
            ListTile(
                title: Text(localizationOf(context).liveTranslator),
                onTap: () async {
                  if (await Utilities()
                      .handlePermission(Permission.microphone)) {
                    NavigationService().pushNamed("/liveTranslator");
                  }
                }),
            ListTile(
                title: Text(localizationOf(context).settings),
                onTap: () {
                  NavigationService().pushNamed("/settings");
                }),
            ListTile(
                title: Text(localizationOf(context).logout),
                onTap: () async {
                  await NavigationService().pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()), (p0)=>p0.isFirst);
                  await AnyChatAuth.signOut();
                }),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          children: [
            Align(
                alignment: conversationWidgets.isEmpty
                    ? Alignment.center
                    : Alignment.topCenter,
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: _isLoadedConversations
                        ? conversationWidgets.isEmpty
                            ? RefreshableEmptyConversationWidget() // see definition below
                            : ListView.separated(
                                separatorBuilder: (context, index) => Divider(
                                  indent:
                                      MediaQuery.of(context).size.width * 0.25,
                                  endIndent:
                                      MediaQuery.of(context).size.width * 0.25,
                                  color: Theme.of(context).dividerColor,
                                ),
                                itemCount: conversationWidgets.length,
                                itemBuilder: (_, int index) =>
                                    conversationWidgets[index],
                              )
                        : Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    // Your logic to refresh the conversations or data
    // For example, you might call setState() to trigger a rebuild:
    List<Conversation> conversations = [];
    AnyChatAuth.currentUser.conversations =
    await ConversationInfo.getAllConversationInfo(
        AnyChatAuth.currentUser.id);
    for (var info in AnyChatAuth.currentUser.conversations){
      List<AnyChatUser> chatters = [];
      var conversation = await Conversation.getConversationById(info.id);
      for (var user in conversation.participants){
          chatters.add(await AnyChatUser.getUserById(user));
      }
      var message = (await Conversation.getLatestMessageByConversationId(conversation.id));
      if (message == null) continue;
      var state = AnyChatConversationWidget(chatters, conversation, message);
      setState(() {
        insertSorted(state);
        conversations.add(conversation);
      });
    }
  }

// If the conversation list is empty, still allow pull-to-refresh:
  Widget RefreshableEmptyConversationWidget() => RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                child: Text(localizationOf(context).startConversation),
                onPressed: () {
                  AnyChatAuth.currentConversation = null;
                  NavigationService().pushNamed("/searchChatter");
                },
              ),
            ],
          ),
        ),
      );

  // return Scaffold(
  //     // bottomSheet: Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
  //     // bottomSheet: Ads.getBanner(),
  //     appBar: AppBar(
  //       // foregroundColor: ,
  //       title: Text(localizationOf(context).title),
  //       actions: <Widget>[
  //         if (conversationWidgets.isNotEmpty)
  //           IconButton(
  //             icon: const Icon(Icons.add),
  //             tooltip: localizationOf(context).createConversation,
  //             onPressed: () {
  //               AnyChatAuth.currentConversation = null;
  //               NavigationService().pushNamed("/searchChatter");
  //             },
  //           ),
  //       ],
  //     ),
  //     drawer: Drawer(
  //       // Add a ListView to the drawer. This ensures the user can scroll
  //       // through the options in the drawer if there isn't enough vertical
  //       // space to fit everything.
  //       child: ListView(
  //         // Important: Remove any padding from the ListView.
  //         padding: EdgeInsets.zero,
  //         children: <Widget>[
  //           DrawerHeader(
  //             decoration: BoxDecoration(
  //               color: Theme.of(context).primaryColor,
  //             ),
  //             child: Text(
  //               localizationOf(context).title,
  //             ),
  //           ),
  //           ListTile(
  //               title: Text(localizationOf(context).liveTranslator),
  //               onTap: () async {
  //                 if (await Utilities()
  //                     .handlePermission(Permission.microphone)) {
  //                   NavigationService().pushNamed("/liveTranslator");
  //                 }
  //               }),
  //           ListTile(
  //               title: Text(localizationOf(context).settings),
  //               onTap: () {
  //                 NavigationService().pushNamed("/settings");
  //               }),
  //           ListTile(
  //               title: Text(localizationOf(context).logout),
  //               onTap: () async {
  //                 await AnyChatAuth.signOut();
  //                 NavigationService().pushNamed("/welcome");
  //               }),
  //         ],
  //       ),
  //     ),
  //     body: Stack(
  //       children: [
  //         Align(
  //             alignment: conversationWidgets.isEmpty
  //                 ? Alignment.center
  //                 : Alignment.topCenter,
  //             child: Container(
  //                 constraints: const BoxConstraints(maxWidth: 1280),
  //                 child: _isLoadedConversations
  //                     ? conversationWidgets.isEmpty
  //                         ? Column(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: <Widget>[
  //                               ElevatedButton(
  //                                 child: Text(localizationOf(context)
  //                                     .startConversation),
  //                                 onPressed: () {
  //                                   AnyChatAuth.currentConversation = null;
  //                                   NavigationService()
  //                                       .pushNamed("/searchChatter");
  //                                 },
  //                               ),
  //                             ],
  //                           )
  //                         : ListView.separated(
  //                             separatorBuilder: (context, index) => Divider(
  //                                   indent:
  //                                       MediaQuery.of(context).size.width *
  //                                           0.25,
  //                                   endIndent:
  //                                       MediaQuery.of(context).size.width *
  //                                           0.25,
  //                                   color: Theme.of(context).dividerColor,
  //                                 ),
  //                             itemCount: conversationWidgets.length,
  //                             itemBuilder: (_, int index) =>
  //                                 conversationWidgets[index])
  //                     : Center(
  //                         child: CircularProgressIndicator(
  //                           valueColor: AlwaysStoppedAnimation<Color>(
  //                             Theme.of(context).primaryColor,
  //                           ),
  //                         ),
  //                       ))),
  //         // Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
  //       ],
  //     ));

  Map<String, Timestamp?> convoTimes = {};
  void insertSorted(AnyChatConversationWidget state) {
    convoTimes.putIfAbsent(state.conversation.id.toString(), () => state.message.timestamp);
    var sortedTimes = convoTimes.keys.toList(growable: false)
      ..sort((k1, k2) => convoTimes[k2]!.compareTo(convoTimes[k1]!));
    LinkedHashMap sortedMap = LinkedHashMap.fromIterable(sortedTimes,
        key: (k) => k, value: (k) => convoTimes[k]);
    logger.d(sortedMap);
    var index = sortedMap.keys.toList().indexOf(state.conversation.id);
    conversationWidgets.removeWhere((element) => element.key == state.getSlidable().key);
    if (!state.conversation.participants.any((element) =>
        AnyChatAuth.currentUser.blockedAccounts.contains(element))) {
        _isLoadedConversations = true;
        conversationWidgets.insert(index, state.getSlidable());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
