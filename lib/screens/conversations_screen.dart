import 'dart:async';
import 'dart:collection';

// import 'package:anychat/components/ads.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_message.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/database/conversation_info.dart';
import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/components/notifications.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/chat_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifications/notifications_util.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/combined_locale_info.dart';

class ConversationsScreen extends StatefulWidget {
  static const ConversationsScreen _instance = ConversationsScreen._internal();

  factory ConversationsScreen() {
    return _instance;
  }
  const ConversationsScreen._internal();

  const ConversationsScreen.named({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState.empty();

  State<ConversationsScreen> updateState(
          List<AnyChatUser> users, Conversation newConversation, String text) =>
      _ConversationsScreenState.stateful(users, newConversation, text);
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  static List<Slidable> conversationWidgets = [];

  static bool _isLoadedConversations = false;

  _ConversationsScreenState.empty();
  _ConversationsScreenState.stateful(
      List<AnyChatUser> users, Conversation newConversation, String text) {
    _isLoadedConversations = true;
    var newState = slidable(users, newConversation, text);
    conversationWidgets.add(newState);
    insertSorted(newState, newConversation);
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);
  //   setState(() {
  //     logger.i('AppLifeCycle changed from $_notification to $state');
  //     _notification = state;
  //   });
  // }

  @override
  initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this);
    // conversationWidgets.clear();

    // _chatMessageSubscriptions.clear();
    //new removal initChatSubscriptions();
    NotificationObserver().initChatSubscriptions();
    NotificationObserver().initConversationSubscriptions(_updateConversations);
    // _conversationSubscription ??=
    //     ChatWindow.loadAllConversations().listen(_updateConversations);
    // AnyChatAuth.currentUser?.addSubscription(_conversationSubscription);
  }

  @override
  Widget build(BuildContext context) {
    logger.d(
        'in build -> conversationWidgets.length: ${conversationWidgets.length}');
    return Scaffold(
        // bottomSheet: Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
        // bottomSheet: Ads.getBanner(),
        appBar: AppBar(
          // foregroundColor: ,
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
                            .handlePermission(Permission.microphone) &&
                        context.mounted) {
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
                    await AnyChatAuth.signOut();
                    NavigationService().pushNamed("/welcome");
                  }),
            ],
          ),
        ),
        body: Stack(
          children: [
            Align(
                alignment: conversationWidgets.isEmpty
                    ? Alignment.center
                    : Alignment.topCenter,
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: _isLoadedConversations
                        ? conversationWidgets.isEmpty
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ElevatedButton(
                                    child: Text(localizationOf(context)
                                        .startConversation),
                                    onPressed: () {
                                      AnyChatAuth.currentConversation = null;
                                      NavigationService()
                                          .pushNamed("/searchChatter");
                                    },
                                  ),
                                ],
                              )
                            : ListView.separated(
                                separatorBuilder: (context, index) => Divider(
                                      indent:
                                          MediaQuery.of(context).size.width *
                                              0.25,
                                      endIndent:
                                          MediaQuery.of(context).size.width *
                                              0.25,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                itemCount: conversationWidgets.length,
                                itemBuilder: (_, int index) =>
                                    conversationWidgets[index])
                        : Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ))),
            // Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
          ],
        ));
  }

  Future<void> loadConversations() async {
    var ids = <String>[];
    AnyChatAuth.currentUser.conversations =
        await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser.id);
    for (final conversation in AnyChatAuth.currentUser.conversations) {
      Conversation temp;
      temp = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversation.id)
          .get());

      if (!ids.contains(temp.id)) {
        logger.d(temp.id);
        ids.add(temp.id);
        List<String?> users = temp.participants;
        logger.d(AnyChatAuth.currentUser.id);
        var chatters = <AnyChatUser>[];
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
                  .where((element) => element.id == chatter.id)
                  .isEmpty) {
                chatters.add(chatter);
              }
            } catch (e) {
              logger.d(e);
            }
            if (mounted && AnyChatAuth.currentConversation != null) {
              AnyChatMessage message;
              try {
                message = snapshot.docs.map((DocumentSnapshot doc) {
                  return AnyChatMessage.fromSnapshot(doc);
                }).last;
                // String? text;
                // text = message.text;
                var info = AnyChatAuth.currentUser.conversations.firstWhere(
                    (element) =>
                        element.id == AnyChatAuth.currentConversation!.id);
                final language = message.senderId == AnyChatAuth.currentUser.id
                    ? info.outgoingLanguage
                    : info.incomingLanguage;
                // text = "${message.text}\n\n"

                await Utilities().getGoogleTranslation(language, message.text);
              } catch (e) {
                logger.d(e);
              }
              logger.d(
                  'adding conversation: ${temp.id} with participants: $chatters');
            }
          }
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

        // if (chatters.isNotEmpty && temp.timestamp != null && mounted) {
        //   insertSorted(
        //       slidable(chatters, temp,
        //           text ?? localizationOf(context).newConversation),
        //       temp);
        // }
      }
    }
    if (mounted) {
      setState(() {
        _isLoadedConversations = true;
      });
    }
  }

  static Map<String, Timestamp?> convoTimes = {};
  void insertSorted(Slidable slidable, Conversation conversation) {
    convoTimes.putIfAbsent(conversation.id, () => conversation.timestamp);
    var sortedTimes = convoTimes.keys.toList(growable: false)
      ..sort((k1, k2) => convoTimes[k2]!.compareTo(convoTimes[k1]!));
    LinkedHashMap sortedMap = LinkedHashMap.fromIterable(sortedTimes,
        key: (k) => k, value: (k) => convoTimes[k]);
    logger.d(sortedMap);
    var index = sortedMap.keys.toList().indexOf(conversation.id);
    conversationWidgets.removeWhere((element) => element.key == slidable.key);
    if (!conversation.participants.any((element) =>
        AnyChatAuth.currentUser.blockedAccounts.contains(element))) {
      _isLoadedConversations = true;
      conversationWidgets.insert(index, slidable);
    }
  }

  List<Conversation> getConversationsFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return Conversation.fromSnapshot(doc);
    }).toList();
  }

  Future<void> _updateConversations(QuerySnapshot snapshot) async {
    if (conversationWidgets.isEmpty) {
      await loadConversations();
      return;
    }
    var conversations = getConversationsFromQuery(snapshot);
    logger.d('in _updateConversations');
    if (conversations.isEmpty) {
      logger.d('conversation snapshot was empty');
      return;
    }
    Conversation conversation = conversations.last;
    AnyChatAuth.currentUser;
    AnyChatUser? firstChatter = AnyChatAuth.currentUser;
    try {
      firstChatter = await AnyChatUser.getUserById(conversation.participants
          .firstWhere((element) => element != AnyChatAuth.currentUser.id));
    } catch (e) {
      logger.e(e);
    }
    if (AnyChatAuth.currentConversation == null) {
      await NotificationObserver().initConversationInfo();
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
    late String text;
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
          await NotificationObserver().initChatSubscriptions();
          message = AnyChatMessage("", Timestamp.now(), chatter.id,
              localizationOf(context).newConversation, null);
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
          text = "${truncatedText}\n\n"
              "${await Utilities().getGoogleTranslation(language, truncatedText)}";
        } catch (e, stack) {
          logger.d("New Conversation: $conversation.id");
          text = localizationOf(
                  mounted ? context : Utilities().globalKey.currentContext!)
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

    if (chatters.isNotEmpty && conversation.timestamp != null) {
      setState(() {
        insertSorted(slidable(chatters, conversation, text), conversation);
      });
    }
    if (!conversationWidgets
        .any((element) => element.key == Key(conversation.id))) {
      NotificationObserver().addChatMessageSubscription(conversation.id);
      // _chatMessageSubscriptions
      //     .add(loadAllChatMessages(conversation.id).listen(_sendNotification));
      logger.d(
          '${AnyChatAuth.currentUser} is listening to notifications for ${conversation.id}');
    }
  }

  Slidable slidable(
      List<AnyChatUser> chatters, Conversation conversation, String text) {
    logger.d("slidable: ${conversation.id}");
    var timeOfLastMessage = DateTime.fromMillisecondsSinceEpoch(
        conversation.timestamp!.millisecondsSinceEpoch);
    String displayTime = '';
    var difference = DateTime.now().difference(timeOfLastMessage);
    var currentContext =
        mounted ? context : Utilities().globalKey.currentContext;
    if (difference < const Duration(minutes: 1)) {
      displayTime = "< 1 min";
    } else if (difference < const Duration(hours: 1)) {
      displayTime =
          '${difference.inMinutes} ${difference.inMinutes == 1 ? localizationOf(currentContext).minute : localizationOf(currentContext).minutes} ${localizationOf(currentContext).ago}';
    } else if (difference < const Duration(days: 1)) {
      displayTime =
          '${difference.inHours} ${difference.inHours == 1 ? localizationOf(currentContext).hour : localizationOf(currentContext).hours} ${localizationOf(currentContext).ago}';
    } else if (difference < const Duration(days: 7)) {
      displayTime =
          '${difference.inDays} ${difference.inDays == 1 ? localizationOf(currentContext).day : localizationOf(currentContext).days} ${localizationOf(currentContext).ago}';
    } else {
      displayTime =
          '${timeOfLastMessage.year}-${timeOfLastMessage.month}-${timeOfLastMessage.day}';
    }
    return Slidable(
      key: Key(conversation.id),
      // actionExtentRatio: 0.25,
      // actions: <Widget>[
      //   //   new IconSlideAction(
      //   //     caption: 'Archive',
      //   //     color: Colors.blue,
      //   //     icon: Icons.archive,
      //   //     onTap: () => logger.d('Archive'),
      //   //   ),
      //   //   new IconSlideAction(
      //   //     caption: 'Share',
      //   //     color: Colors.indigo,
      //   //     icon: Icons.share,
      //   //     onTap: () => logger.d('Share'),
      //   //   ),
      //   // ],
      //   // secondaryActions: <Widget>[
      //   //   new IconSlideAction(
      //   //     caption: 'More',
      //   //     color: Colors.black45,
      //   //     icon: Icons.more_horiz,
      //   //     onTap: () => logger.d('More'),
      //   //   ),
      //   IconSlideAction(
      //     caption: localizationOf(context).delete,
      //     color: Colors.red,
      //     icon: Icons.delete,
      //     onTap: () => {
      //       // setState(() {
      //       AnyChatUser.deleteConversation(context, conversation.id)
      //       // })
      //     },
      //   ),
      // ],
      // startActionPane: SlidableDrawerActionPane(),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: ListTile(
          onTap: () {
            // setState(() {
            AnyChatAuth.currentConversation = conversation;
            AnyChatAuth.currentChatters = chatters;
            // });
            // Navigator.pushNamed(context,  "/chat", arguments: {conversation, chatters});
            NavigationService().pushNamed('/chat');
          },
          leading: getChatterWidgetList(chatters),
          // chatters.length > 1
          //     ? Icon(Icons.person)
          //     : CircleAvatar(
          //     backgroundColor: Theme.of(context).primaryColor,
          //     backgroundImage: NetworkImage(chatters.first.photoUrl),
          //     foregroundColor: Theme.of(context).primaryColorLight),
          title: Text(Utilities().getChatterDisplayNameString(chatters)),
          subtitle: Text(text),
          trailing: Text(displayTime),
        ),
      ),
    );
  }

  Widget getChatterWidgetList(List<AnyChatUser> chatters) {
    const double containerRadius = kIsWeb ? 45 : 55.0;
    const double avatarRadius = containerRadius / 2;
    // return Container(
    //     height: _containerRadius,
    //     width: _containerRadius,
    //     decoration: BoxDecoration(
    //       shape: BoxShape.circle,
    //     ),
    //     child: ClipOval(
    //       clipBehavior: Clip.antiAlias,
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: <Widget>[
    //           Row(
    //             children: <Widget>[
    //               _buildAvatar(avatarRadius, chatters.first.photoUrl),
    //               // _buildAvatar(avatarRadius, Colors.blue),
    //               // _buildAvatar(avatarRadius, Colors.black),
    //             ],
    //           ),
    //           // Row(
    //           //   children: <Widget>[
    //           //     _buildAvatar(avatarRadius, Colors.yellow),
    //           //     _buildAvatar(avatarRadius, Colors.red),
    //           //     _buildAvatar(avatarRadius, Colors.orange),
    //           //   ],
    //           // )
    //         ],
    //       ),
    //     ),
    // );

    var topWidgets = <Widget>[];
    var bottomWidgets = <Widget>[];

    for (int i = 0; i < chatters.length; i += 2) {
      if (chatters.length == 1) {
        topWidgets.add(
            AnyChatUser.getAvatarInContainer(containerRadius, chatters[i]));
      }
      topWidgets
          .add(AnyChatUser.getAvatarInContainer(avatarRadius, chatters[i]));
    }
    for (int i = 1; i < chatters.length; i += 2) {
      bottomWidgets
          .add(AnyChatUser.getAvatarInContainer(avatarRadius, chatters[i]));
    }
    Column column;
    switch (chatters.length) {
      case 1:
        column = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  topWidgets.first,
                ],
              )
            ]);
        break;
      case 2:
        column = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[topWidgets.first],
            ),
            Row(
              children: <Widget>[
                bottomWidgets.first,
              ],
            )
          ],
        );
        break;
      case 3:
        column = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[topWidgets.first, topWidgets[1]],
            ),
            Row(
              children: <Widget>[
                bottomWidgets.first,
              ],
            )
          ],
        );
        break;
      case 4:
        column = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                topWidgets.first,
                topWidgets[1],
              ],
            ),
            Row(
              children: <Widget>[
                bottomWidgets.first,
                bottomWidgets[1],
              ],
            )
          ],
        );
        break;
      case 5:
        column = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                topWidgets.first,
                topWidgets[1],
                topWidgets[2]
              ],
            ),
            Row(
              children: <Widget>[
                bottomWidgets.first,
                bottomWidgets[1],
              ],
            )
          ],
        );
        break;
      case 6:
      default:
        column = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                topWidgets.first,
                topWidgets[1],
                topWidgets[2]
              ],
            ),
            Row(
              children: <Widget>[
                bottomWidgets.first,
                bottomWidgets[1],
                bottomWidgets[2],
              ],
            )
          ],
        );
        break;
    }

    return Container(
        height: containerRadius,
        width: containerRadius,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(clipBehavior: Clip.antiAlias, child: column));

    // var widgets = <Positioned>[];
    // double top = 1;
    // for (var chatter in chatters) {
    //   if (chatters.first == chatter) {
    //     widgets.add(Positioned(
    //       child: new CircleAvatar(
    //           backgroundColor: Theme.of(context).primaryColor,
    //           backgroundImage: NetworkImage(chatter.photoUrl),
    //           foregroundColor: Theme.of(context).primaryColorLight),
    //     ));
    //   } else {
    //     widgets.add(Positioned(
    //       top: top,
    //       child: new CircleAvatar(
    //           backgroundColor: Theme.of(context).primaryColor,
    //           backgroundImage: NetworkImage(chatter.photoUrl),
    //           foregroundColor: Theme.of(context).primaryColorLight),
    //     ));
    //     top += 5;
    //   }
    // }
    // return widgets;
  }

  @override
  void dispose() {
    // for (var sub in _chatMessageSubscriptions) {
    //   sub?.cancel();
    // }
    // _conversationSubscription?.cancel();

    // Ads.interstitial.dispose();
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
