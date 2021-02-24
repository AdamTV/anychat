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
                style:
                    // TODO: Color should be platform specific
                    TextStyle(color: Theme.of(context).primaryColorLight),
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
    // loaded = true;

    // ConversationsScreen.testWidgets.clear();

    // _conversationSubscription?.cancel();
    // _conversationSubscription =
    //     ChatWindow.loadAllConversations().listen(_updateConversations);

    var widgets = <Widget>[];
    var ids = <String>[];
    AnyChatAuth.currentUser.conversationIds.forEach((conversationId) async {
      Conversation conversation;
      conversation = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .get());

      String chatterName = "test";
      String chatterId;

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
            chatterId = chatter.id;

            if (!conversationWidgets.any((element) => element.key == Key(conversation.id)) && mounted) {
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
                chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(message.senderId).get());
              } catch (e) {
                throw e;
              }
              print('adding conversation: ' + conversation.id);
              // addedConversations.add(conversation.id);
              // ConversationsScreen.conversations.add(conversation.id);
              setState(() {
                conversationWidgets.add(new Slidable(
                  key: new Key(conversation.id),
                  actionExtentRatio: 0.25,
                  child: new Container(
                    color: Theme.of(context).primaryColorLight,
                    child: new ListTile(
                      onTap: () {
                        AnyChatApp.chatter = chatter;
                        ChatWindow.currentConversation = conversation;
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ChatScreen();
                        }));
                      },
                      leading: new CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: NetworkImage(chatter.photoUrl),
                        foregroundColor: Theme.of(context).primaryColorLight,
                      ),
                      title: new Text(chatterName),
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
                                    Navigator.of(context).pop();
                                    setState(() {
                                      AnyChatAuth.currentUser.conversationIds
                                          .removeWhere((element) =>
                                              element == conversation.id);
                                    });
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
                ));
                // conversationWidgets.add(new ListTile(
                //     onTap: () {
                //       AnyChatApp.chatter = chatter;
                //       ChatWindow.currentConversation = conversation;
                //       Navigator.push(context,
                //           MaterialPageRoute(builder: (context) {
                //         return ChatScreen();
                //       }));
                //     },
                //     leading: Icon(Icons.chat),
                //     title: RichText(
                //         text: TextSpan(
                //             text: chatterName,
                //             style: TextStyle(color: Colors.grey)))));
              });
            }
            print('test widget added');
          }
        }
      }
      //
      //     // conversation.participants.forEach((AnyChatUser participant) async {
      //     //     if(participant.id != AnyChatAuth
      //     //         .getGoogleSignIn()
      //     //         .currentUser
      //     //         .id) {
      //     //       chatterName = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(participant.id).get()).displayName;
      //     //     }
      //     //   });
      //     // if(chatterName == null)return;
      //
      //     // FirebaseFirestore.instance.collection("conversations").doc(element).get().then((value) =>
      //     // {
      //     //   conversation = Conversation.fromSnapshot(value),
      //     //   print('test'),
      //     //   testWidgets.add(Text("test"))
      //     // });
      //
      //     // var conversation = Conversation.fromSnapshot((
      //     //     element).get());
      //     //String chatterName = "Sf";
      //     // conversation.participants.forEach((AnyChatUser participant) async {
      //     //   if(participant.id != AnyChatAuth
      //     //       .getGoogleSignIn()
      //     //       .currentUser
      //     //       .id) {
      //     //     chatterName = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(participant.id).get()).displayName;
      //     //   }
      //     // });
      //
      //     // print("adding widget");
      //     // widgets.add(new ListTile(
      //     //     onTap: () {
      //     //       // AnyChatApp.user = FindChatterScreenState.users[index];
      //     //       // Navigator.push(
      //     //       //     context, MaterialPageRoute(builder: (context) {
      //     //       //   return ChatScreen();
      //     //       // }));
      //     //     },
      //     //     leading: Icon(Icons.person_add),
      //     //     title: RichText(
      //     //         text: TextSpan(
      //     //             text: chatterName,
      //     //             style: TextStyle(color: Colors.grey)))));
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
    if (!conversation.participants.contains(AnyChatAuth.currentUser.id)) {
      print(
          'conversation participants does not contain ${AnyChatAuth.currentUser.id}');
      return;
    }
    // if(!AnyChatAuth.currentUser.conversationIds.contains(conversation.id)){
    //   print('user conversationIds does not contain ${conversation.id}');
    //   return;
    // }
    // if (conversationWidgets.isEmpty) {
    //   setState(() {
    //     conversationWidgets = loadConversations();
    //   });
    // return;
    // }
    String chatterName;

    List<String> users = conversation.participants;
    for (var i = 0; i < conversation.participants.length; i++) {
      print(AnyChatAuth.currentUser.id);
      // This assumes the chatter is the first participant that is not the user
      if (users[i] != AnyChatAuth.currentUser.id) {
        var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
            .instance
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
          message = snapshot.docs.map((DocumentSnapshot doc) {
            return AnyChatMessage.fromSnapshot(doc);
          }).last;
          text = "${message.text}\n\n"
              "${await Utilities.getGoogleTranslation(message.senderId == AnyChatAuth.currentUser.id ? AnyChatApp.chatter.language : AnyChatAuth.currentUser.language, message.text)}";
          chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(message.senderId).get());
        } catch (e) {
          throw e;
        }
        setState(() {
          chatterName = chatter.displayName;
          if (!conversationWidgets.any((element) => element.key == Key(conversation.id))) {
            // addedConversations.add(conversation.id);
            // ConversationsScreen.conversations.add(conversation.id);
            // conversationWidgets.add(new ListTile(
            //     onTap: () {
            //       AnyChatApp.chatter = chatter;
            //       ChatWindow.currentConversation = conversation;
            //       Navigator.push(context, MaterialPageRoute(builder: (context) {
            //         return ChatScreen();
            //       }));
            //     },
            //     leading: Icon(Icons.chat),
            //     title: RichText(
            //         text: TextSpan(
            //             text: chatterName,
            //             style: TextStyle(color: Colors.grey)))));
            conversationWidgets.add(new Slidable(
              key: new Key(conversation.id),
              actionExtentRatio: 0.25,
              child: new Container(
                color: Theme.of(context).primaryColorLight,
                child: new ListTile(
                  onTap: () {
                    AnyChatApp.chatter = chatter;
                    ChatWindow.currentConversation = conversation;
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return ChatScreen();
                    }));
                  },
                  leading: new CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: NetworkImage(chatter.photoUrl),
                    foregroundColor: Theme.of(context).primaryColorLight,
                  ),
                  title: new Text(chatterName),
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
                                Navigator.of(context).pop();
                                setState(() {
                                  AnyChatAuth.currentUser.conversationIds
                                      .removeWhere((element) =>
                                          element == conversation.id);
                                });
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
            ));
            if (!AnyChatAuth.currentUser.conversationIds
                .contains(conversation.id)) {
              AnyChatAuth.currentUser.conversationIds.add(conversation.id);
            }
            print('added conversation widget');
            print(conversationWidgets);
          }
          // } else {
          //   conversationWidgets
          //       .removeWhere((element) => element.key == Key(conversation.id));
          //   conversationWidgets.add(new Slidable(
          //     key: new Key(conversation.id),
          //     actionExtentRatio: 0.25,
          //     child: new Container(
          //       color: Theme.of(context).primaryColorLight,
          //       child: new ListTile(
          //         onTap: () {
          //           AnyChatApp.chatter = chatter;
          //           ChatWindow.currentConversation = conversation;
          //           Navigator.push(context,
          //               MaterialPageRoute(builder: (context) {
          //             return ChatScreen();
          //           }));
          //         },
          //         leading: new CircleAvatar(
          //           backgroundColor: Theme.of(context).primaryColor,
          //           backgroundImage: NetworkImage(chatter.photoUrl),
          //           foregroundColor: Theme.of(context).primaryColorLight,
          //         ),
          //         title: new Text(chatterName),
          //         subtitle: new Text(text),
          //       ),
          //     ),
          //     actions: <Widget>[
          //       new IconSlideAction(
          //         caption: 'Archive',
          //         color: Colors.blue,
          //         icon: Icons.archive,
          //         onTap: () => print('Archive'),
          //       ),
          //       new IconSlideAction(
          //         caption: 'Share',
          //         color: Colors.indigo,
          //         icon: Icons.share,
          //         onTap: () => print('Share'),
          //       ),
          //     ],
          //     secondaryActions: <Widget>[
          //       new IconSlideAction(
          //         caption: 'More',
          //         color: Colors.black45,
          //         icon: Icons.more_horiz,
          //         onTap: () => print('More'),
          //       ),
          //       new IconSlideAction(
          //         caption: 'Delete',
          //         color: Colors.red,
          //         icon: Icons.delete,
          //         onTap: () => {
          //           showDialog<void>(
          //             context: context,
          //             barrierDismissible: true,
          //             builder: (BuildContext context) {
          //               return AlertDialog(
          //                 title: Text("Delete Conversation"),
          //                 content: SingleChildScrollView(
          //                   child: ListBody(
          //                     children: <Widget>[
          //                       Text(
          //                           "Are you sure you want to leave this conversation? "
          //                           "You will not be able to join back unless somebody "
          //                           "invites you."),
          //                     ],
          //                   ),
          //                 ),
          //                 actions: <Widget>[
          //                   TextButton(
          //                     child: Text('Cancel'),
          //                     onPressed: () {
          //                       Navigator.of(context).pop();
          //                       Fluttertoast.showToast(
          //                           msg: "Cancelled",
          //                           toastLength: Toast.LENGTH_LONG,
          //                           gravity: ToastGravity.CENTER,
          //                           timeInSecForIosWeb: 3,
          //                           backgroundColor: Colors.red,
          //                           textColor: Theme.of(context).primaryColorLight,
          //                           fontSize: 16.0);
          //                     },
          //                   ),
          //                   TextButton(
          //                     child: Text('Approve'),
          //                     onPressed: () {
          //                       Navigator.of(context).pop();
          //                       setState(() {
          //                         AnyChatAuth.currentUser.conversationIds
          //                             .removeWhere((element) =>
          //                                 element == conversation.id);
          //                       });
          //                       AnyChatAuth.currentUser
          //                           .leaveConversation(conversation.id);
          //                       Fluttertoast.showToast(
          //                           msg: "Successfully left conversation",
          //                           toastLength: Toast.LENGTH_LONG,
          //                           gravity: ToastGravity.CENTER,
          //                           timeInSecForIosWeb: 3,
          //                           backgroundColor: Colors.red,
          //                           textColor: Theme.of(context).primaryColorLight,
          //                           fontSize: 16.0);
          //                       // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConversationsScreen()));
          //                     },
          //                   ),
          //                 ],
          //               );
          //             },
          //           )
          //         },
          //       ),
          //     ],
          //     actionPane: SlidableDrawerActionPane(),
          //   ));
          // }
        });
        // chatterId = AnyChatApp.chatter.id;
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

// class ConversationsScreen extends StatelessWidget {
//   static List<String> conversations = new List<String>();
//   static List<Widget> testWidgets = new List<Widget>();
//
//   @override
//   Widget build(BuildContext context) {
//     loadConversations();
//     print('conversations loaded');
//     return Scaffold(
//       body: Body(),
//     );
//   }
//   static List<Widget> loadConversations() {
//     var widgets = <Widget>[];
//     ConversationsScreen.conversations.forEach((element) async {
//       Conversation conversation;
//       conversation = Conversation.fromSnapshot(await FirebaseFirestore.instance.collection("conversations").doc(element).get());
//       testWidgets.add(Text('test'));
//       print('test widget added');
//       // FirebaseFirestore.instance.collection("conversations").doc(element).get().then((value) =>
//       // {
//       //   conversation = Conversation.fromSnapshot(value),
//       //   print('test'),
//       //   testWidgets.add(Text("test"))
//       // });
//
//       // var conversation = Conversation.fromSnapshot((
//       //     element).get());
//       //String chatterName = "Sf";
//       // conversation.participants.forEach((AnyChatUser participant) async {
//       //   if(participant.id != AnyChatAuth
//       //       .getGoogleSignIn()
//       //       .currentUser
//       //       .id) {
//       //     chatterName = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(participant.id).get()).displayName;
//       //   }
//       // });
//
//       // print("adding widget");
//       // widgets.add(new ListTile(
//       //     onTap: () {
//       //       // AnyChatApp.user = FindChatterScreenState.users[index];
//       //       // Navigator.push(
//       //       //     context, MaterialPageRoute(builder: (context) {
//       //       //   return ChatScreen();
//       //       // }));
//       //     },
//       //     leading: Icon(Icons.person_add),
//       //     title: RichText(
//       //         text: TextSpan(
//       //             text: chatterName,
//       //             style: TextStyle(color: Colors.grey)))));
//     });
//     return widgets;
//   }
// }

  Future<void> _sendNotification(QuerySnapshot snapshot) async {
    print('in _sendNotification');
    var message = snapshot.docs
        .map((DocumentSnapshot doc) {
          return AnyChatMessage.fromSnapshot(doc);
        })
        .toList()
        .last;
    if (mounted) {
      // snapshot.docs.last.reference.parent.parent
      var conversation = Conversation.fromSnapshot(await snapshot.docs.last.reference.parent.parent.get());
      var chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(message.senderId).get());
      final language = message.senderId == AnyChatAuth.currentUser.id ? chatter.language : AnyChatAuth.currentUser.language;
      final text = "${message.text}\n\n"
          "${await Utilities.getGoogleTranslation(language, message.text)}";
      setState(() {
        conversationWidgets.removeWhere((element) => element.key == Key(conversation.id));
        conversationWidgets.insert(0, new Slidable(
          key: new Key(conversation.id),
          actionExtentRatio: 0.25,
          child: new Container(
            color: Theme.of(context).primaryColorLight,
            child: new ListTile(
              onTap: () {
                AnyChatApp.chatter = chatter;
                ChatWindow.currentConversation = conversation;
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                      return ChatScreen();
                    }));
              },
              leading: new CircleAvatar(
                backgroundColor: Theme
                    .of(context)
                    .primaryColor,
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
              onTap: () =>
              {
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
                            Navigator.of(context).pop();
                            setState(() {
                              AnyChatAuth.currentUser.conversationIds
                                  .removeWhere((element) =>
                              element == conversation.id);
                            });
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
        ));
      // conversationWidgets.clear();
      // loadConversations();
      });
      // setState(() {
      //   final wid = Slidable(
      //     key: new Key(convoId),
      //     actionExtentRatio: 0.25,
      //     child: new Container(
      //       color: Theme.of(context).primaryColorLight,
      //       child: new ListTile(
      //         onTap: () {
      //           AnyChatApp.chatter = chatter;
      //           ChatWindow.currentConversation = conversation;
      //           Navigator.push(context,
      //               MaterialPageRoute(builder: (context) {
      //                 return ChatScreen();
      //               }));
      //         },
      //         leading: new CircleAvatar(
      //           backgroundColor: Theme
      //               .of(context)
      //               .primaryColor,
      //           backgroundImage: NetworkImage(chatter.photoUrl),
      //           foregroundColor: Theme.of(context).primaryColorLight,
      //         ),
      //         title: new Text(chatterName),
      //         subtitle: new Text(text),
      //       ),
      //     ),
      //     actions: <Widget>[
      //       new IconSlideAction(
      //         caption: 'Archive',
      //         color: Colors.blue,
      //         icon: Icons.archive,
      //         onTap: () => print('Archive'),
      //       ),
      //       new IconSlideAction(
      //         caption: 'Share',
      //         color: Colors.indigo,
      //         icon: Icons.share,
      //         onTap: () => print('Share'),
      //       ),
      //     ],
      //     secondaryActions: <Widget>[
      //       new IconSlideAction(
      //         caption: 'More',
      //         color: Colors.black45,
      //         icon: Icons.more_horiz,
      //         onTap: () => print('More'),
      //       ),
      //       new IconSlideAction(
      //         caption: 'Delete',
      //         color: Colors.red,
      //         icon: Icons.delete,
      //         onTap: () =>
      //         {
      //           showDialog<void>(
      //             context: context,
      //             barrierDismissible: true,
      //             builder: (BuildContext context) {
      //               return AlertDialog(
      //                 title: Text("Delete Conversation"),
      //                 content: SingleChildScrollView(
      //                   child: ListBody(
      //                     children: <Widget>[
      //                       Text(
      //                           "Are you sure you want to leave this conversation? "
      //                               "You will not be able to join back unless somebody "
      //                               "invites you."),
      //                     ],
      //                   ),
      //                 ),
      //                 actions: <Widget>[
      //                   TextButton(
      //                     child: Text('Cancel'),
      //                     onPressed: () {
      //                       Navigator.of(context).pop();
      //                       Fluttertoast.showToast(
      //                           msg: "Cancelled",
      //                           toastLength: Toast.LENGTH_LONG,
      //                           gravity: ToastGravity.CENTER,
      //                           timeInSecForIosWeb: 3,
      //                           backgroundColor: Colors.red,
      //                           textColor: Theme.of(context).primaryColorLight,
      //                           fontSize: 16.0);
      //                     },
      //                   ),
      //                   TextButton(
      //                     child: Text('Approve'),
      //                     onPressed: () {
      //                       Navigator.of(context).pop();
      //                       setState(() {
      //                         AnyChatAuth.currentUser.conversationIds
      //                             .removeWhere((element) =>
      //                         element == conversation.id);
      //                       });
      //                       AnyChatAuth.currentUser
      //                           .leaveConversation(conversation.id);
      //                       Fluttertoast.showToast(
      //                           msg: "Successfully left conversation",
      //                           toastLength: Toast.LENGTH_LONG,
      //                           gravity: ToastGravity.CENTER,
      //                           timeInSecForIosWeb: 3,
      //                           backgroundColor: Colors.red,
      //                           textColor: Theme.of(context).primaryColorLight,
      //                           fontSize: 16.0);
      //                       // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConversationsScreen()));
      //                     },
      //                   ),
      //                 ],
      //               );
      //             },
      //           )
      //         },
      //       ),
      //     ],
      //     actionPane: SlidableDrawerActionPane(),
      //   ));

      // conversationWidgets.removeWhere((element) => element.key == Key());
      // conversationWidgets.insert(0, Text("yted"));
      // c
      // await _updateConversations(await FirebaseFirestore.instance
      //     .collection('conversations')
      //     .orderBy('timestamp', descending: false)
      //     .snapshots().last);
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
}
