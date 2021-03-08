import 'dart:async';
import 'dart:ui';

import 'package:anychat/Screens/AddChatter/addchatter_screen.dart';
import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/Screens/LiveTranslator/live_translator_screen.dart';
import 'package:anychat/Screens/Settings/settings_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/notifications.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
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
    Ads.myBanner.show(
      // Positions the banner ad 0 pixels from the bottom of the screen
      anchorOffset: 0.0,
      // Positions the banner ad 0 pixels from the center of the screen to the right
      horizontalCenterOffset: 0.0,
      // Banner Position
      anchorType: AnchorType.bottom,
    );
  }

  bool loaded = false;
  StreamSubscription<QuerySnapshot> _conversationSubscription;
  List<StreamSubscription<QuerySnapshot>> _chatMessageSubscriptions = [];

  // List<String> addedConversations = <String>[];
  // ignore: deprecated_member_use
  List<Widget> conversationWidgets = new List<Widget>();

  _ConversationsScreenState() {
    conversationWidgets.clear();
    _conversationSubscription =
        ChatWindow.loadAllConversations().listen(_updateConversations);
    for (var conversationId in AnyChatAuth.currentUser.conversationIds) {
      _chatMessageSubscriptions
          .add(loadAllChatMessages(conversationId).listen(_sendNotification));
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'AnyChatAuth.currentUser.conversationIds.length: ${AnyChatAuth.currentUser.conversationIds.length}');
    print(
        'in build -> conversationWidgets.length: ${conversationWidgets.length}');
    if (!loaded) {
      //loadConversations();
    }
    return Scaffold(
      appBar: AppBar(
        //leading: Icon(Icons.restaurant),
        title: Text('AnyChat'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Chatter',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddChatterScreen()));
            },
          ),
        ],
        // bottom: PreferredSize(
        //   preferredSize: Size(320, 48),
        //   child: Padding(
        //     padding: EdgeInsets.fromLTRB(6, 0, 6, 4),
        //     child: FilterBar(
        //       filter: _filter,
        //       onPressed: _onFilterBarPressed,
        //     ),
        //   ),
        // ),
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
                'AnyChat',
                style: TextStyle(color: Theme.of(context).primaryColorLight),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
                title: Text('Live Translator'),
                onTap: () async {
                  await Utilities.handleCameraAndMic(Permission.microphone);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LiveTranslatorScreen()));
                  //_handleSignOut();
                }),
            ListTile(
                title: Text('Settings'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingsScreen()));
                  //_handleSignOut();
                }),
            ListTile(
                title: Text('Logout'),
                onTap: () async {
                  await AnyChatAuth.signOut();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()));
                  //_handleSignOut();
                }),
          ],
        ),
      ),
      body: Align(
          alignment: AnyChatAuth.currentUser.conversationIds.length > 0
              ? Alignment.topCenter
              : Alignment.center,
          child: Container(
            constraints: BoxConstraints(maxWidth: 1280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AnyChatAuth.currentUser.conversationIds.length > 0
                  ? conversationWidgets
                  : <Widget>[
                      Text('Conversations will appear here.'),
                      RoundedButton(
                        text: "Start Chatting",
                        press: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddChatterScreen()));
                        },
                      ),
                    ],
            ),
          )),
    );
  }

  void loadConversations() {
    var ids = <String>[];
    AnyChatAuth.currentUser.conversationIds.forEach((conversationId) async {
      Conversation conversation;
      conversation = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .get());

      String chatterName = "test";

      if (!ids.contains(conversationId)) {
        print(conversationId);
        ids.add(conversationId);
        List<String> users = conversation.participants;
        print(AnyChatAuth.currentUser.id);
        for (var i = 0; i < conversation.participants.length; i++) {
          if (users[i] != AnyChatAuth.currentUser.id) {
            var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
                .instance
                .collection("users")
                .doc(users[i])
                .get());
            chatterName = chatter.displayName;

            if (!conversationWidgets
                    .any((element) => element.key == Key(conversation.id)) &&
                mounted) {
              var snapshot = await FirebaseFirestore.instance
                  .collection("conversations")
                  .doc(conversation.id)
                  .collection("messages")
                  .orderBy('timestamp', descending: false)
                  .get();
              String text;
              AnyChatMessage message;
              try {
                message = snapshot.docs.map((DocumentSnapshot doc) {
                  return AnyChatMessage.fromSnapshot(doc);
                }).last;
                text = "${message.text}\n\n"
                    "${await Utilities.getGoogleTranslation(message.senderId == AnyChatAuth.currentUser.id ? AnyChatApp.chatter.language : AnyChatAuth.currentUser.language, message.text)}";
                // chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
                //     .instance
                //     .collection("users")
                //     .doc(message.senderId)
                //     .get());
              } catch (e) {
                throw e;
              }
              print('adding conversation: ' + conversation.id);
              setState(() {
                conversationWidgets.add(slidable(chatter, conversation, text));
              });
            }
            print('test widget added');
          }
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
    if (AnyChatAuth.currentUser.conversationIds == null) {
      print('user conversationIds was null');
      return;
    }
    if (!AnyChatAuth.currentUser.conversationIds.contains(conversation.id)) {
      if (conversation.participants.contains(AnyChatAuth.currentUser.id)){
        AnyChatAuth.currentUser.conversationIds.add(conversation.id);
      }else {
        print(
            'currentUser conversationIds does not contain this conversation id.');
        return;
      }
    }
    if (!conversation.participants.contains(AnyChatAuth.currentUser.id)) {
      print(
          'conversation participants does not contain ${AnyChatAuth.currentUser.id}');
      return;
    }

    List<String> users = conversation.participants;
    for (var i = 0; i < conversation.participants.length; i++) {
      print(AnyChatAuth.currentUser.id);
      // This assumes the chatter is the first participant that is not the user
      if (users[i] != AnyChatAuth.currentUser.id) {
        var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection("users")
            .doc(users[i])
            .get());
        var snapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversation.id)
            .collection("messages")
            .orderBy('timestamp', descending: false)
            .get();
        String text;
        AnyChatMessage message;
        try {
          if (snapshot.docs.isNotEmpty) {
            message = snapshot.docs.map((DocumentSnapshot doc) {
              return AnyChatMessage.fromSnapshot(doc);
            }).last;
          } else {
            message = AnyChatMessage(
                "", Timestamp.now(), chatter.id, "New Conversation", null);
          }
          // chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
          //     .collection("users")
          //     .doc(message.senderId)
          //     .get());
          text = "${message.text}\n\n"
              "${await Utilities.getGoogleTranslation(message.senderId == AnyChatAuth.currentUser.id ? chatter.language : AnyChatAuth.currentUser.language, message.text)}";
        } catch (e) {
          throw e;
        }
        setState(() {
          if (!conversationWidgets
              .any((element) => element.key == Key(conversation.id))) {
            _chatMessageSubscriptions.add(
                loadAllChatMessages(conversation.id).listen(_sendNotification));
            conversationWidgets.add(slidable(chatter, conversation, text));
            if (!AnyChatAuth.currentUser.conversationIds
                .contains(conversation.id)) {
              AnyChatAuth.currentUser.conversationIds.add(conversation.id);
            }
            print('added conversation widget');
            print(conversationWidgets);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (var sub in _chatMessageSubscriptions) {
      sub?.cancel();
    }
    _conversationSubscription?.cancel();
    Ads.myBanner.dispose();
    Ads.myInterstitial.dispose();
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
    if (mounted) {
      var conversation = Conversation.fromSnapshot(
          await snapshot.docs.last.reference.parent.parent.get());
      if (AnyChatAuth.currentUser.conversationIds.contains(conversation.id)) {
        AnyChatUser chatter;
        if (conversation.participants.length == 1) {
          chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
              .instance
              .collection("users")
              .doc(message.senderId)
              .get());
        }else{
          chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
              .collection("users")
              .doc(conversation.participants
              .firstWhere((element) => element != AnyChatAuth.currentUser.id))
              .get());
        }

        final language = message.senderId == AnyChatAuth.currentUser.id
            ? chatter.language
            : AnyChatAuth.currentUser.language;
        final text = "${message.text}\n\n"
            "${await Utilities.getGoogleTranslation(language, message.text)}";
        setState(() {
          conversationWidgets
              .removeWhere((element) => element.key == Key(conversation.id));
          conversationWidgets.insert(0, slidable(chatter, conversation, text));
        });
      }
    }
    print("_notification");
    print(_notification);
    if (message.senderId != AnyChatAuth.currentUser.id &&
        _notification != AppLifecycleState.resumed) {
      var user = await AnyChatUser.findUserById(message.senderId);
      var text = "${message.text}\n\n"
          "${await Utilities.getGoogleTranslation(message.senderId == AnyChatAuth.currentUser.id ? AnyChatApp.chatter.language : AnyChatAuth.currentUser.language, message.text)}";
      await Notifications().showNotification(user.displayName, text);
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

  Widget slidable(AnyChatUser chatter, Conversation conversation, String text) {
    return new Slidable(
      key: new Key(conversation.id),
      actionExtentRatio: 0.25,
      child: new Container(
        color: Theme.of(context).primaryColorLight,
        child: new ListTile(
          onTap: () {
            AnyChatApp.chatter = chatter;
            ChatWindow.currentConversation = conversation;
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ChatScreen();
            }));
          },
          leading: new CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: NetworkImage(chatter.photoUrl),
            foregroundColor: Theme.of(context).primaryColorLight,
          ),
          title: new Text(chatter.displayName),
          subtitle: new Text(text),
        ),
      ),
      actions: <Widget>[
        new IconSlideAction(
          caption: 'Archive',
          color: Colors.blue,
          icon: Icons.archive,
          onTap: () => print('Archive'),
        ),
        new IconSlideAction(
          caption: 'Share',
          color: Colors.indigo,
          icon: Icons.share,
          onTap: () => print('Share'),
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: 'More',
          color: Colors.black45,
          icon: Icons.more_horiz,
          onTap: () => print('More'),
        ),
        new IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => {
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Delete Conversation"),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        Text(
                            "Are you sure you want to leave this conversation? "
                            "You will not be able to join back unless somebody "
                            "invites you."),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Fluttertoast.showToast(
                            msg: "Cancelled",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 3,
                            backgroundColor: Colors.red,
                            textColor: Theme.of(context).primaryColorLight,
                            fontSize: 16.0);
                      },
                    ),
                    TextButton(
                      child: Text('Approve'),
                      onPressed: () {
                        setState(() {
                          AnyChatAuth.currentUser.conversationIds.removeWhere(
                              (element) => element == conversation.id);
                        });
                        Navigator.of(context).pop();
                        ChatWindow.currentConversation = null;
                        AnyChatAuth.currentUser
                            .leaveConversation(conversation.id);
                        Fluttertoast.showToast(
                            msg: "Successfully left conversation",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 3,
                            backgroundColor: Colors.red,
                            textColor: Theme.of(context).primaryColorLight,
                            fontSize: 16.0);
                        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConversationsScreen()));
                      },
                    ),
                  ],
                );
              },
            )
          },
        ),
      ],
      actionPane: SlidableDrawerActionPane(),
    );
  }
}
