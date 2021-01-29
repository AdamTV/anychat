import 'dart:async';

import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:anychat/Screens/Conversations/components/body.dart';

class ConversationsScreen extends StatefulWidget {
  static List<String> conversations = new List<String>();
  static List<Widget> testWidgets = new List<Widget>();

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool loaded = false;
  StreamSubscription<QuerySnapshot> _conversationSubscription;
  List<String> addedConversations = <String>[];

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      loadConversations();
    }
    return Scaffold(
      body: Body(),
    );
  }

  List<Widget> loadConversations() {
    loaded = true;

    ConversationsScreen.testWidgets.clear();

    _conversationSubscription?.cancel();
    _conversationSubscription =
        ChatWindow.loadAllConversations().listen(_updateConversations);

    var widgets = <Widget>[];
    ConversationsScreen.conversations.forEach((conversationId) async {
      Conversation conversation;
      conversation = Conversation.fromSnapshot(await FirebaseFirestore.instance
          .collection("conversations")
          .doc(conversationId)
          .get());
      String chatterName = "test";
      String chatterId;
      List<String> users = conversation.participants;
      print(AnyChatAuth.currentUser.id);
      for (var i = 0; i < conversation.participants.length; i++) {
        if (users[i] != AnyChatAuth.currentUser.id) {
          AnyChatApp.chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
              .instance
              .collection("users")
              .doc(users[i])
              .get());
          chatterName = AnyChatApp.chatter.displayName;
          chatterId = AnyChatApp.chatter.id;
        }
      }

      // conversation.participants.forEach((AnyChatUser participant) async {
      //     if(participant.id != AnyChatAuth
      //         .getGoogleSignIn()
      //         .currentUser
      //         .id) {
      //       chatterName = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(participant.id).get()).displayName;
      //     }
      //   });
      // if(chatterName == null)return;
      if (!addedConversations.contains(conversation.id)) {
        addedConversations.add(conversation.id);
        ConversationsScreen.conversations.add(conversation.id);
        setState(() {
          ConversationsScreen.testWidgets.add(new ListTile(
              onTap: () {
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
        });
      }
      print('test widget added');
      // FirebaseFirestore.instance.collection("conversations").doc(element).get().then((value) =>
      // {
      //   conversation = Conversation.fromSnapshot(value),
      //   print('test'),
      //   testWidgets.add(Text("test"))
      // });

      // var conversation = Conversation.fromSnapshot((
      //     element).get());
      //String chatterName = "Sf";
      // conversation.participants.forEach((AnyChatUser participant) async {
      //   if(participant.id != AnyChatAuth
      //       .getGoogleSignIn()
      //       .currentUser
      //       .id) {
      //     chatterName = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(participant.id).get()).displayName;
      //   }
      // });

      // print("adding widget");
      // widgets.add(new ListTile(
      //     onTap: () {
      //       // AnyChatApp.user = FindChatterScreenState.users[index];
      //       // Navigator.push(
      //       //     context, MaterialPageRoute(builder: (context) {
      //       //   return ChatScreen();
      //       // }));
      //     },
      //     leading: Icon(Icons.person_add),
      //     title: RichText(
      //         text: TextSpan(
      //             text: chatterName,
      //             style: TextStyle(color: Colors.grey)))));
    });
    return widgets;
  }

  List<Conversation> getConversationsFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return Conversation.fromSnapshot(doc);
    }).toList();
  }

  Future<void> _updateConversations(QuerySnapshot snapshot) async {
    if (getConversationsFromQuery(snapshot).isEmpty) return;
    Conversation conversation = getConversationsFromQuery(snapshot).last;
    AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(await FirebaseFirestore
        .instance
        .collection('users')
        .doc(AnyChatAuth.currentUser.id)
        .get());
    if (!AnyChatAuth.currentUser.conversations.contains(conversation.id))
      return;

    String chatterName;

    List<String> users = conversation.participants;
    for (var i = 0; i < conversation.participants.length; i++) {
      print(AnyChatAuth.currentUser.id);
      // This assumes the chatter is the first participant that is not the user
      if (users[i] != AnyChatAuth.currentUser.id) {
        AnyChatApp.chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore
            .instance
            .collection("users")
            .doc(users[i])
            .get());
        setState(() {
          chatterName = AnyChatApp.chatter.displayName;
          if (!addedConversations.contains(conversation.id)) {
            addedConversations.add(conversation.id);
            ConversationsScreen.conversations.add(conversation.id);
            ConversationsScreen.testWidgets.add(new ListTile(
                onTap: () {
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
          }
        });
        // chatterId = AnyChatApp.chatter.id;
      }
    }
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
