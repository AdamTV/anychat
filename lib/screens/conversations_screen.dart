import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/conversation_info.dart';
import 'package:anychat/components/notifications.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/screens/chat_screen.dart';
import 'package:anychat/screens/search_chatter_by_email_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';

class ConversationsScreen extends StatefulWidget {
  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with WidgetsBindingObserver {
  AppLifecycleState _notification = AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
      print(_notification);
    });
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool loaded = false;
  StreamSubscription<QuerySnapshot> _conversationSubscription;
  List<StreamSubscription<QuerySnapshot>> _chatMessageSubscriptions = [];
  List<Widget> conversationWidgets = [];

  _ConversationsScreenState() {
    conversationWidgets.clear();
    // _chatMessageSubscriptions.clear();
    if (_conversationSubscription == null)
      _conversationSubscription =
          ChatWindow.loadAllConversations().listen(_updateConversations);
    if (_chatMessageSubscriptions.isEmpty) initChatSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    print(
        'in build -> conversationWidgets.length: ${conversationWidgets.length}');
    return Scaffold(
        // bottomSheet: Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
        // bottomSheet: Ads.getBanner(),
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).title),
          actions: conversationWidgets.length == 0
              ? <Widget>[]
              : <Widget>[
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: AppLocalizations.of(context).createConversation,
                    onPressed: () {
                      AnyChatAuth.currentConversation = null;
                      Navigator.pushNamed(context, "/addChatter");
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
                child: Text(
                  AppLocalizations.of(context).title,
                  style: TextStyle(color: Theme.of(context).primaryColorLight),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                  title: Text(AppLocalizations.of(context).liveTranslator),
                  onTap: () async {
                    if (await Utilities.handlePermission(
                        Permission.microphone)) {
                      Utilities.showToast(AppLocalizations.of(context)
                          .listeningToMicrophoneLiveAudio);
                      Navigator.pushNamed(context, "/liveTranslator");
                    }
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context).settings),
                  onTap: () {
                    Navigator.pushNamed(context, "/settings");
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context).logout),
                  onTap: () async {
                    await AnyChatAuth.signOut();
                    Navigator.pushNamed(context, "/welcome");
                  }),
            ],
          ),
        ),
        body: Stack(
          children: [
            Align(
                alignment: conversationWidgets.length > 0
                    ? Alignment.topCenter
                    : Alignment.center,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 1280),
                  child: conversationWidgets.length > 0
                      ? ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                      indent: MediaQuery.of(context).size.width * 0.25,
                      endIndent: MediaQuery.of(context).size.width * 0.25,
                      color: Theme.of(context).primaryColor,
                    ),
                          itemCount: conversationWidgets.length,
                          itemBuilder: (_, int index) =>
                              conversationWidgets[index])
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(AppLocalizations.of(context)
                                .conversationsWillAppear),
                            RoundedButton(
                              text: AppLocalizations.of(context)
                                  .startConversation,
                              press: () {
                                AnyChatAuth.currentConversation = null;
                                SearchChatterByEmailScreen.addToConvo = false;
                                Navigator.pushNamed(context, "/addChatter");
                              },
                            ),
                          ],
                        ),
                )),
            Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
          ],
        ));
  }

  Future<void> loadConversations() async {
    var ids = <String>[];
    AnyChatAuth.currentUser.conversations =
        await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser.id);
    AnyChatAuth.currentUser.conversations.forEach((conversation) async {
      Conversation temp;
      temp = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversation.id)
          .get());

      if (!ids.contains(temp.id)) {
        print(temp.id);
        ids.add(temp.id);
        List<String> users = temp.participants;
        print(AnyChatAuth.currentUser.id);
        var chatters = <AnyChatUser>[];
        String text;
        var snapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(temp.id)
            .collection("messages")
            .orderBy('timestamp', descending: false)
            .get();
        for (var i = 0; i < temp.participants.length; i++) {
          if (users[i] != AnyChatAuth.currentUser.id) {
            var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
                .instance
                .collection("users")
                .doc(users[i])
                .get());
            if (chatters.where((element) => element.id == chatter.id).length ==
                0) {
              chatters.add(chatter);
            }
            if (mounted) {
              AnyChatMessage message;
              try {
                message = snapshot.docs.map((DocumentSnapshot doc) {
                  return AnyChatMessage.fromSnapshot(doc);
                }).last;
                var info = AnyChatAuth.currentUser.conversations.firstWhere(
                    (element) =>
                        element.id == AnyChatAuth.currentConversation.id);
                final language = message.senderId == AnyChatAuth.currentUser.id
                    ? info.outgoingLanguage
                    : info.incomingLanguage;
                text = "${message.text}\n\n"
                    "${await Utilities.getGoogleTranslation(language, message.text)}";
              } catch (e) {
                print(e);
              }
              print('adding conversation: ' + temp.id);
            }
            print('test widget added');
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
        if (chatters.isNotEmpty) {
          if (text == null) text = AppLocalizations.of(context).newConversation;
          insertSorted(await slidable(chatters, temp, text), temp);
        }
      }
    });
  }

  Map<String, Timestamp> convoTimes = Map();

  void insertSorted(Widget slidable, Conversation conversation) {
    convoTimes.addEntries({MapEntry(conversation.id, conversation.timestamp)});
    var sortedTimes = convoTimes.keys.toList(growable: false)
      ..sort((k1, k2) => convoTimes[k2].compareTo(convoTimes[k1]));
    LinkedHashMap sortedMap = new LinkedHashMap.fromIterable(sortedTimes,
        key: (k) => k, value: (k) => convoTimes[k]);
    print(sortedMap);
    var index = sortedMap.keys.toList().indexOf(conversation.id);
    conversationWidgets.removeWhere((element) => element.key == slidable.key);
    setState(() {
      conversationWidgets.insert(index, slidable);
    });
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
    print('in _updateConversations');
    if (conversations.isEmpty) {
      print('conversation snapshot was empty');
      return;
    }
    Conversation conversation = conversations.last;
    if(AnyChatAuth.currentUser == null) {
      AnyChatAuth.currentUser =
      await AnyChatUser.getUserById(AnyChatAuth.currentUser.id);
    }
    AnyChatUser firstChatter = AnyChatAuth.currentUser;
    try {
      firstChatter = await AnyChatUser.getUserById(conversation.participants
          .firstWhere((element) => element != AnyChatAuth.currentUser.id));
    } catch (e) {
      print(e);
    }
    if (AnyChatAuth.currentConversation == null) {
      await initConvoInfo();
    }
    if (AnyChatAuth.currentUser.conversations != null &&
        !AnyChatAuth.currentUser.conversations
            .any((element) => element.id == conversation.id)) {
      if (conversation.participants.contains(AnyChatAuth.currentUser.id)) {
        AnyChatAuth.currentUser.conversations.add(ConversationInfo(
            conversation.id,
            AnyChatAuth.currentUser.language,
            firstChatter.language));
      } else {
        print('none of currentUser conversations ID are ${conversation.id}.');
        return;
      }
    }
    if (!conversation.participants.contains(AnyChatAuth.currentUser.id)) {
      print(
          'conversation participants does not contain ${AnyChatAuth.currentUser.id}');
      return;
    }
    List<String> users = conversation.participants;
    var chatters = <AnyChatUser>[];
    String text;
    for (var i = 0; i < conversation.participants.length; i++) {
      print(AnyChatAuth.currentUser.id);
      if (users[i] != AnyChatAuth.currentUser.id) {
        var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection("users")
            .doc(users[i])
            .get());
        if (chatters.where((element) => element.id == chatter.id).length == 0) {
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
          _chatMessageSubscriptions.add(
              loadAllChatMessages(conversation.id).listen(_sendNotification));
          message = AnyChatMessage("", Timestamp.now(), chatter.id,
              AppLocalizations.of(context).newConversation, null);
        }
       try {
         var info = AnyChatAuth.currentUser.conversations
             .firstWhere((element) => element.id == conversation.id);
         final language = message.senderId == AnyChatAuth.currentUser.id
             ? info.outgoingLanguage
             : info.incomingLanguage;
         text = "${message.text}\n\n"
             "${await Utilities.getGoogleTranslation(language, message.text)}";
       } catch(e){
         text = AppLocalizations.of(context).newConversation;
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

    if (chatters.isNotEmpty) {
      insertSorted(await slidable(chatters, conversation, text), conversation);
    }
    if (!conversationWidgets
        .any((element) => element.key == Key(conversation.id))) {
      _chatMessageSubscriptions
          .add(loadAllChatMessages(conversation.id).listen(_sendNotification));
      print('added conversation widget');
      print(conversationWidgets);
    }
  }

  @override
  void dispose() {
    for (var sub in _chatMessageSubscriptions) {
      sub?.cancel();
    }
    _conversationSubscription?.cancel();
    Ads.interstitial.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _sendNotification(QuerySnapshot snapshot) async {
    print('in _sendNotification');
    var messages = snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).toList();
    AnyChatMessage message;
    if (messages.isNotEmpty) {
      message = messages.last;
    } else {
      print("messages are empty");
      return;
    }
    var conversation = Conversation.fromSnapshot(
        await snapshot.docs.last.reference.parent.parent.get());
    if (mounted) {
      if (AnyChatAuth.currentUser.conversations
          .any((element) => element.id == conversation.id)) {
        var chatters = <AnyChatUser>[];
        if (conversation.participants.length == 1) {
          // if (chatters
          //         .where((element) => element.id == message.senderId)
          //         .length ==
          //     0)
          // {
          try {
            chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore
                .instance
                .collection("users")
                .doc(message.senderId)
                .get()));
          } catch (e) {
            chatters
                .add(AnyChatUser(null, AppLocalizations.of(context).accountDeleted, null, null, null));
          }
          // }
        } else {
          var chatterIds = conversation.participants
              .where((element) => element != AnyChatAuth.currentUser.id);
          for (var id in chatterIds) {
            if (chatters.where((element) => element.id == id).length == 0) {
              try {
                chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore
                    .instance
                    .collection("users")
                    .doc(id)
                    .get()));
              } catch (e) {
                chatters.add(
                    AnyChatUser(null, AppLocalizations.of(context).accountDeleted, null, null, null));
              }
            }
          }
        }
        if (AnyChatAuth.currentUser.conversations != null &&
            AnyChatAuth.currentUser.conversations
                .any((element) => element.id == conversation.id)) {
          var info = AnyChatAuth.currentUser.conversations
              .firstWhere((element) => element.id == conversation.id);
          final language = message.senderId == AnyChatAuth.currentUser.id
              ? info.outgoingLanguage
              : info.incomingLanguage;
          final text = message.text == null
          ? AppLocalizations.of(context).thisPersonHasLeftConversation
          : "${message.text}\n\n"
              "${await Utilities.getGoogleTranslation(language, message.text)}";

          if (chatters.isNotEmpty) {
            insertSorted(
                await slidable(chatters, conversation, text), conversation);
          }
        }
      }
    }
    print("_notification");
    print(_notification);
    if (message.senderId != AnyChatAuth.currentUser.id &&
        _notification != AppLifecycleState.resumed) {
      var sender = await AnyChatUser.getUserById(message.senderId);
      var text = message.text == null
          ? AppLocalizations.of(context).thisPersonHasLeftConversation
          : "${message.text}\n\n"
          "${await Utilities.getGoogleTranslation(AnyChatAuth.currentUser.language, message.text)}";

      if (text.contains(AppLocalizations.of(context).isCallingYouOnAnyChat)) {
        await Notifications().showNotification(
            sender.displayName, text, "ring-${conversation.id}");
      } else {
        await Notifications().showNotification(
            sender.displayName, text, "chat-${conversation.id}");
      }
    }
  }

  loadAllChatMessages(String conversationId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<Widget> slidable(List<AnyChatUser> chatters, Conversation conversation,
      String text) async {
    print("slidable: ${conversation.id}");
    var timeOfLastMessage = DateTime.fromMicrosecondsSinceEpoch(
        conversation.timestamp.microsecondsSinceEpoch);
    String displayTime = '';
    var difference = DateTime.now().difference(timeOfLastMessage);
    if (difference < Duration(minutes: 1)) {
      displayTime = "< 1 min";
    } else if (difference < Duration(hours: 1)) {
      displayTime = difference.inMinutes.toString() +
          ' ${difference.inMinutes == 1 ? AppLocalizations.of(context).minute : AppLocalizations.of(context).minutes} ${AppLocalizations.of(context).ago}';
    } else if (difference < Duration(days: 1)) {
      displayTime = difference.inHours.toString() +
          ' ${difference.inHours == 1 ? AppLocalizations.of(context).hour : AppLocalizations.of(context).hours} ${AppLocalizations.of(context).ago}';
    } else if (difference < Duration(days: 7)) {
      displayTime = difference.inDays.toString() +
          ' ${difference.inDays == 1 ? AppLocalizations.of(context).day : AppLocalizations.of(context).days} ${AppLocalizations.of(context).ago}';
    } else {
      displayTime =
          '${timeOfLastMessage.year}-${timeOfLastMessage.month}-${timeOfLastMessage.day}';
    }
    return new Slidable(
      key: new Key(conversation.id),
      actionExtentRatio: 0.25,
      child: new Container(
        padding: EdgeInsets.all(10),
        child: new ListTile(
          onTap: () {
            setState(() {
              AnyChatAuth.currentConversation = conversation;
              AnyChatAuth.currentChatters = chatters;
            });
            // Navigator.pushNamed(context,  "/chat", arguments: {conversation, chatters});
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => ChatScreen()));
          },
          leading: getChatterWidgetList(chatters),
          // chatters.length > 1
          //     ? Icon(Icons.person)
          //     : CircleAvatar(
          //     backgroundColor: Theme.of(context).primaryColor,
          //     backgroundImage: NetworkImage(chatters.first.photoUrl),
          //     foregroundColor: Theme.of(context).primaryColorLight),
          title: new Text(Utilities.getChatterDisplayNameString(chatters)),
          subtitle: new Text(text),
          trailing: new Text(displayTime),
        ),
      ),
      actions: <Widget>[
        //   new IconSlideAction(
        //     caption: 'Archive',
        //     color: Colors.blue,
        //     icon: Icons.archive,
        //     onTap: () => print('Archive'),
        //   ),
        //   new IconSlideAction(
        //     caption: 'Share',
        //     color: Colors.indigo,
        //     icon: Icons.share,
        //     onTap: () => print('Share'),
        //   ),
        // ],
        // secondaryActions: <Widget>[
        //   new IconSlideAction(
        //     caption: 'More',
        //     color: Colors.black45,
        //     icon: Icons.more_horiz,
        //     onTap: () => print('More'),
        //   ),
        new IconSlideAction(
          caption: AppLocalizations.of(context).delete,
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => {
            // setState(() {
            AnyChatUser.deleteConversation(context, conversation.id)
            // })
          },
        ),
      ],
      actionPane: SlidableDrawerActionPane(),
    );
  }

  // Widget _buildAvatar(String photoUrl, double avatarRadius) {
  //   return Expanded(
  //     child: CircleAvatar(backgroundImage: NetworkImage(photoUrl)));
  // }
  Widget _buildAvatar(double avatarRadius, AnyChatUser user) {
    return Expanded(
        child: Container(
            height: avatarRadius,
            width: avatarRadius,
            child: user.photoUrl == null
                ? CircleAvatar(child: Text(user.displayName.substring(0, 1)))
                : CircleAvatar(backgroundImage: NetworkImage(user.photoUrl))));
  }

  Widget getChatterWidgetList(List<AnyChatUser> chatters) {
    final double _containerRadius = kIsWeb ? 45 : 55.0;
    final double avatarRadius = _containerRadius / 2;
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
        topWidgets.add(_buildAvatar(_containerRadius, chatters[i]));
      }
      topWidgets.add(_buildAvatar(avatarRadius, chatters[i]));
    }
    for (int i = 1; i < chatters.length; i += 2) {
      bottomWidgets.add(_buildAvatar(avatarRadius, chatters[i]));
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
        height: _containerRadius,
        width: _containerRadius,
        decoration: BoxDecoration(
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

  Future<void> initConvoInfo() async {
    AnyChatAuth.currentUser.conversations =
        await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser.id);
  }

  Future<void> initChatSubscriptions() async {
    await initConvoInfo();
    for (var conversationInfo in AnyChatAuth.currentUser.conversations) {
      _chatMessageSubscriptions.add(
          loadAllChatMessages(conversationInfo.id).listen(_sendNotification));
    }
  }
}
