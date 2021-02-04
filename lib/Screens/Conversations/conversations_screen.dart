import 'dart:async';
import 'dart:typed_data';

import 'package:anychat/Screens/AddChatter/addchatter_screen.dart';
import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/Screens/Conversations/components/body.dart';
import 'package:anychat/Screens/Settings/settings_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConversationsScreen extends StatefulWidget {

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool loaded = false;
  StreamSubscription<QuerySnapshot> _conversationSubscription;
  List<String> addedConversations = <String>[];
  List<Widget> conversationWidgets = new List<Widget>();

  _ConversationsScreenState() {
    conversationWidgets.clear();
    _conversationSubscription =
        ChatWindow.loadAllConversations().listen(_updateConversations);
  }

  @override
  Widget build(BuildContext context) {
    print('AnyChatAuth.currentUser.conversationIds.length: ${AnyChatAuth.currentUser.conversationIds.length}');
    print('in build -> conversationWidgets.length: ${conversationWidgets.length}');
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
                    TextStyle(color: Colors.white),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
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

  List<Widget> loadConversations() {
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
            final chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
                .instance
                .collection("users")
                .doc(users[i])
                .get());
            chatterName = chatter.displayName;
            chatterId = chatter.id;

            if (!addedConversations.contains(conversation.id) && mounted) {
              print('adding conversation: ' + conversation.id);
              addedConversations.add(conversation.id);
              // ConversationsScreen.conversations.add(conversation.id);
              setState(() {
                conversationWidgets.add(new ListTile(
                    onTap: () {
                      AnyChatApp.chatter = chatter;
                      ChatWindow.currentConversation = conversation;
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ChatScreen();
                      }));
                    },
                    leading: Icon(Icons.chat),
                    title: RichText(
                        text: TextSpan(
                            text: chatterName,
                            style: TextStyle(color: Colors.grey)))));
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
    return widgets;
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
    if(!conversation.participants.contains(AnyChatAuth.currentUser.id)){
      print('conversation participants does not contain ${AnyChatAuth.currentUser.id}');
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
        final chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
            .instance
            .collection("users")
            .doc(users[i])
            .get());
        setState(() {
          chatterName = chatter.displayName;
          if (!addedConversations.contains(conversation.id)) {
            addedConversations.add(conversation.id);
            // ConversationsScreen.conversations.add(conversation.id);
            conversationWidgets.add(new ListTile(
                onTap: () {
                  AnyChatApp.chatter = chatter;
                  ChatWindow.currentConversation = conversation;
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return ChatScreen();
                  }));
                },
                leading: Icon(Icons.chat),
                title: RichText(
                    text: TextSpan(
                        text: chatterName,
                        style: TextStyle(color: Colors.grey)))));
            if(!AnyChatAuth.currentUser.conversationIds.contains(conversation.id)){
              AnyChatAuth.currentUser.conversationIds.add(conversation.id);
            }
            print('added conversation widget');
            print(conversationWidgets);
          }
        });
        // chatterId = AnyChatApp.chatter.id;
      }
    }
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
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
}
