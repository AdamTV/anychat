import 'dart:async';
import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Screens/welcome_screen.dart';
import 'package:anychat/Screens/chat_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'conversations_screen.dart';

class SearchChatterByEmailScreen extends StatefulWidget {
  final String email;
  static bool addToConvo;

  const SearchChatterByEmailScreen({Key key, this.email}) : super(key: key);

  @override
  SearchChatterByEmailScreenState createState() => SearchChatterByEmailScreenState(email);
}

class SearchChatterByEmailScreenState extends State<SearchChatterByEmailScreen> {
  static String email;
  static Stream<QuerySnapshot> searchResults;
  static List<AnyChatUser> users = <AnyChatUser>[];

  SearchChatterByEmailScreenState(String email) {
    SearchChatterByEmailScreenState.email = email;
    loadSearchResults();
  }

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
          child: SearchChatterByEmailScreenState.users.length == 0
              ? ListTile(
              title: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      text: "No Results Found",
                      style: TextStyle(color: Colors.grey))))
              : ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: SearchChatterByEmailScreenState.users.length,
            itemBuilder: (BuildContext buildCtx, int index) {
              return new ListTile(
                  onTap: () async {
                    if (ChatWindow.currentConversation == null) {
                      var convo = await AnyChatUser.createConversation(
                          SearchChatterByEmailScreenState.users[index].id);
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
                      AnyChatUser.addUserToConversation(
                          SearchChatterByEmailScreenState.users[index]);
                      ChatWindow.currentConversation.participants
                          .add(SearchChatterByEmailScreenState.users[index].id);
                      await FirebaseFirestore.instance.runTransaction(
                              (Transaction transaction) async {
                            var convoDoc = FirebaseFirestore.instance
                                .collection('conversations')
                                .doc(ChatWindow.currentConversation.id);
                            return transaction
                                .get(convoDoc)
                                .then((DocumentSnapshot doc) =>
                                Conversation.fromSnapshot(doc))
                                .then((Conversation fresh) async {
                              transaction.update(convoDoc, {
                                'participants': ChatWindow
                                    .currentConversation.participants,
                              });
                            });
                          });
                      ChatWindow.currentChatters
                          .add(SearchChatterByEmailScreenState.users[index]);
                    }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return ChatScreen();
                        }));
                  },
                  leading: new CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: NetworkImage(
                          SearchChatterByEmailScreenState.users[index].photoUrl)),
                  title: RichText(
                      text: TextSpan(
                          text: SearchChatterByEmailScreenState
                              .users[index].displayName,
                          style: TextStyle(color: Colors.grey))));
            },
          )),
    );
  }

  void loadSearchResults() async {
    users.clear();
    var user = await AnyChatUser.findUserByEmail(email);
    if (user != null) users.add(user);
    setState(() {});
  }
}
