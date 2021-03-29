import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/Screens/FindChatter/findchatter_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../components/anychat_auth.dart';
import '../../../components/anychat_user.dart';
import '../../Conversations/conversations_screen.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AnyChat'),
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
                title: Text('Return to conversations'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ConversationsScreen()));
                }),
            ListTile(
                title: Text('Logout'),
                onTap: () async {
                  await AnyChatAuth.signOut();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()));
                }),
          ],
        ),
      ),
      body: Container(
          constraints: BoxConstraints(maxWidth: 1280),
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: FindChatterScreenState.users.length,
            itemBuilder: (BuildContext buildCtx, int index) {
              return new ListTile(
                  onTap: () async {
                    if (ChatWindow.currentConversation == null) {
                      var convo = await AnyChatUser.createConversation(
                          FindChatterScreenState.users[index].id);
                      ChatWindow.currentConversation = convo;
                      List<AnyChatUser> users = <AnyChatUser>[];
                      for (var id in convo.participants) {
                        if (id != AnyChatAuth.currentUser.id) {
                          users.add(AnyChatUser.fromSnapshot(
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(id)
                                  .get()));
                        }
                      }
                      ChatWindow.currentChatters = users;
                    } else {
                      AnyChatUser.addUserToConversation(FindChatterScreenState.users[index]);
                      ChatWindow.currentConversation.participants
                          .add(FindChatterScreenState.users[index].id);
                      await FirebaseFirestore.instance
                          .runTransaction((Transaction transaction) async {
                        var convoDoc = FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(ChatWindow.currentConversation.id);
                        return transaction
                            .get(convoDoc)
                            .then((DocumentSnapshot doc) =>
                                Conversation.fromSnapshot(doc))
                            .then((Conversation fresh) async {
                          transaction.update(convoDoc, {
                            'participants':
                                ChatWindow.currentConversation.participants,
                          });
                        });
                      });
                      ChatWindow.currentChatters
                          .add(FindChatterScreenState.users[index]);
                    }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return ChatScreen();
                    }));
                  },
                  leading: Icon(Icons.person_add),
                  title: RichText(
                      text: TextSpan(
                          text: FindChatterScreenState.users[index].displayName,
                          style: TextStyle(color: Colors.grey))));
            },
          )),
    );
  }
}
