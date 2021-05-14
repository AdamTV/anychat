import 'dart:async';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    _conversationSubscription =
        ChatWindow.loadAllConversations().listen(_updateConversations);
    initChatSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    print(
        'in build -> conversationWidgets.length: ${conversationWidgets.length}');
    return Scaffold(
      // bottomSheet: Align(alignment: Alignment.bottomCenter, child: Ads.getBanner()),
      bottomSheet: Ads.getBanner(context),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).title),
        actions: conversationWidgets.length == 0
            ? <Widget>[]
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: AppLocalizations.of(context).createConversation,
                  onPressed: () {
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
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)
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
      body: Align(
          alignment: conversationWidgets.length > 0
              ? Alignment.topCenter
              : Alignment.center,
          child: Container(
            constraints: BoxConstraints(maxWidth: 1280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: conversationWidgets.length > 0
                  ? conversationWidgets
                  : <Widget>[
                      Text(
                          AppLocalizations.of(context).conversationsWillAppear),
                      RoundedButton(
                        text: AppLocalizations.of(context).startConversation,
                        press: () {
                          Navigator.pushNamed(context, "/addChatter");
                        },
                      ),
                    ],
            ),
          )),
    );
  }

  void loadConversations() {
    var ids = <String>[];
    AnyChatAuth.currentUser.conversations.forEach((conversation) async {
      Conversation conversation;
      conversation = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversation.id)
          .get());

      if (!ids.contains(conversation.id)) {
        print(conversation.id);
        ids.add(conversation.id);
        List<String> users = conversation.participants;
        print(AnyChatAuth.currentUser.id);
        var chatters = <AnyChatUser>[];
        String text;
        for (var i = 0; i < conversation.participants.length; i++) {
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
            if (!conversationWidgets
                    .any((element) => element.key == Key(conversation.id)) &&
                mounted) {
              var snapshot = await FirebaseFirestore.instance
                  .collection("conversations")
                  .doc(conversation.id)
                  .collection("messages")
                  .orderBy('timestamp', descending: false)
                  .get();
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
                throw e;
              }
              print('adding conversation: ' + conversation.id);
            }
            print('test widget added');
          }
        }
        if (chatters.isNotEmpty) {
          conversationWidgets.insert(0, await slidable(chatters, conversation, text));
          setState(() {});
        }
      }
    });
  }

  List<Conversation> getConversationsFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return Conversation.fromSnapshot(doc);
    }).toList();
  }

  Future<void> _updateConversations(QuerySnapshot snapshot) async {
    print('in _updateConversations');
    if (getConversationsFromQuery(snapshot).isEmpty) {
      print('conversation snapshot was empty');
      return;
    }
    Conversation conversation = getConversationsFromQuery(snapshot).last;
    AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(await FirebaseFirestore
        .instance
        .collection('users')
        .doc(AnyChatAuth.currentUser.id)
        .get());
    AnyChatUser firstChatter = AnyChatAuth.currentUser;
    try{
      firstChatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
          .collection('users')
          .doc(conversation.participants
          .firstWhere((element) => element != AnyChatAuth.currentUser.id))
          .get());
    }catch(e){
      print(e);
    }
    await initConvoInfo();
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
        var snapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversation.id)
            .collection("messages")
            .orderBy('timestamp', descending: false)
            .get();
        AnyChatMessage message;
        // try {
        if (snapshot.docs.isNotEmpty) {
          message = snapshot.docs.map((DocumentSnapshot doc) {
            return AnyChatMessage.fromSnapshot(doc);
          }).last;
        } else {
          AnyChatAuth.currentUser.conversations =
              await ConversationInfo.getAllConversationInfo(
                  AnyChatAuth.currentUser.id);
          _chatMessageSubscriptions.add(
              loadAllChatMessages(conversation.id).listen(_sendNotification));
          message = AnyChatMessage("", Timestamp.now(), chatter.id,
              AppLocalizations.of(context).newConversation, null);
        }
        var info = AnyChatAuth.currentUser.conversations
            .firstWhere((element) => element.id == conversation.id);
        final language = message.senderId == AnyChatAuth.currentUser.id
            ? info.outgoingLanguage
            : info.incomingLanguage;
        text = "${message.text}\n\n"
            "${await Utilities.getGoogleTranslation(language, message.text)}";
        // } catch (e) {
        //   throw e;
        // }
      }
    }
    if (AnyChatAuth.currentUser.conversations != null &&
        !AnyChatAuth.currentUser.conversations
            .any((element) => element.id == conversation.id)) {
      if (conversation.participants.contains(AnyChatAuth.currentUser.id)) {
        AnyChatAuth.currentUser.conversations.add(ConversationInfo.fromSnapshot(
            await FirebaseFirestore.instance
                .collection("users")
                .doc(AnyChatAuth.currentUser.id)
                .collection('conversations')
                .doc(conversation.id)
                .get()));
      }
    }
    if (chatters.isNotEmpty) {
      conversationWidgets.insert(0, await slidable(chatters, conversation, text));
    }
    setState(() {
      if (!conversationWidgets
          .any((element) => element.key == Key(conversation.id))) {
        _chatMessageSubscriptions.add(
            loadAllChatMessages(conversation.id).listen(_sendNotification));
        print('added conversation widget');
        print(conversationWidgets);
      }
    });
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
          if (chatters
                  .where((element) => element.id == message.senderId)
                  .length ==
              0) {
            chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore
                .instance
                .collection("users")
                .doc(message.senderId)
                .get()));
          }
        } else {
          var chatterIds = conversation.participants
              .where((element) => element != AnyChatAuth.currentUser.id);
          for (var id in chatterIds) {
            if (chatters.where((element) => element.id == id).length == 0) {
              chatters.add(AnyChatUser.fromSnapshot(await FirebaseFirestore
                  .instance
                  .collection("users")
                  .doc(id)
                  .get()));
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
          final text = "${message.text}\n\n"
              "${await Utilities.getGoogleTranslation(language, message.text)}";
          conversationWidgets
              .removeWhere((element) => element.key == Key(conversation.id));
          if (chatters.isNotEmpty) {
            conversationWidgets.insert(
                0, await slidable(chatters, conversation, text));
            setState(() {});
          }
        }
      }
    }
    print("_notification");
    print(_notification);
    if (message.senderId != AnyChatAuth.currentUser.id &&
        _notification != AppLifecycleState.resumed) {
      var sender = await AnyChatUser.findUserById(message.senderId);
      var text = "${message.text}\n\n"
          "${await Utilities.getGoogleTranslation(AnyChatAuth.currentUser.language, message.text)}";

      if (text.contains(AppLocalizations.of(context).isCallingYouOnAnyChat)) {
        await Notifications().showNotification(sender.displayName, text, "ring-${conversation.id}");
      } else {
        await Notifications().showNotification(sender.displayName, text, "chat-${conversation.id}");
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
  Widget _buildAvatar(double avatarRadius, String photoUrl) {
    return Expanded(
        child: Container(
            height: avatarRadius,
            width: avatarRadius,
            child: photoUrl == null
            ? CircleAvatar(child: Text(AnyChatAuth.currentUser.displayName.substring(0,1)))
            : CircleAvatar(backgroundImage: NetworkImage(photoUrl))));
  }

  Widget getChatterWidgetList(List<AnyChatUser> chatters) {
    final double _containerRadius = 55.0;
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
        topWidgets.add(_buildAvatar(_containerRadius, chatters[i].photoUrl));
      }
      topWidgets.add(_buildAvatar(avatarRadius, chatters[i].photoUrl));
    }
    for (int i = 1; i < chatters.length; i += 2) {
      bottomWidgets.add(_buildAvatar(avatarRadius, chatters[i].photoUrl));
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
