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
  @override
  Widget build(BuildContext context) {
    if(!loaded){
      loadConversations();
    }
    return Scaffold(
      body: Body(),
    );
  }
  List<Widget> loadConversations() {
    loaded = true;
    var widgets = <Widget>[];
    ConversationsScreen.conversations.forEach((conversationId) async {
      Conversation conversation;
      conversation = Conversation.fromSnapshot(await FirebaseFirestore.instance.collection("conversations").doc(conversationId).get());
      String chatterName = "test";
      String chatterId;
      List<String> users = conversation.participants;
      for(var i = 0; i < conversation.participants.length; i++){
        if(users[i] != AnyChatAuth
            .getGoogleSignIn()
            .currentUser
            .id) {
          AnyChatApp.chatter = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(users[i]).get());
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
      setState(() {
        ConversationsScreen.testWidgets.add(new ListTile(
                onTap: () {
                  ChatWindow.currentConversation = conversation;
                  Navigator.push(
                          context, MaterialPageRoute(builder: (context) {
                        return ChatScreen();
                      }));
                },
                leading: Icon(Icons.chat),
                title: RichText(
                    text: TextSpan(
                        text: chatterName,
                        style: TextStyle(color: Colors.grey)))));
      });
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
