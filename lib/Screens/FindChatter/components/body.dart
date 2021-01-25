import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/Screens/FindChatter/findchatter_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/constants.dart';

import '../../../components/anychat_auth.dart';
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
                style:
                    // TODO: Color should be platform specific
                    TextStyle(color: Colors.white),
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
                  //_handleSignOut();
                }),
            ListTile(
                title: Text('Logout'),
                onTap: () {
                  AnyChatAuth.signOutGoogle();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()));
                  //_handleSignOut();
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
                  onTap: () {},
                  leading: Icon(Icons.person_add),
                  title: RichText(
                      text: TextSpan(
                          text: FindChatterScreenState.users[index],
                          style: TextStyle(color: Colors.grey))));
            },
          )),
    );
  }
}
