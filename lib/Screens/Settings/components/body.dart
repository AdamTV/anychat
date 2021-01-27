import 'package:anychat/Screens/AddChatter/addchatter_screen.dart';
import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Conversations/conversations_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/constants.dart';

class Body extends StatelessWidget {
  String language;
  @override
  Widget build(BuildContext context) {
    print('loading settings screen');
    //print(ConversationsScreen.testWidgets.length);
    return Scaffold(
        appBar: AppBar(
          //leading: Icon(Icons.restaurant),
          title: Text('AnyChat'),
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
                  title: Text('Back'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text('Logout'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WelcomeScreen()));
                  }),
            ],
          ),
        ),
        body: Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 1280),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Language'),
                      RoundedInputField(icon: Icons.language,onChanged:(value) {language = value;}),
                      RoundedButton(
                          text: "SAVE", press: () async {
                        final user = FirebaseFirestore.instance
                            .collection("users")
                            .doc(AnyChatAuth.currentUser.id);
                        await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
                          return transaction
                              .get(user)
                              .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                              .then((AnyChatUser fresh) async {
                            fresh.language = language;
                            transaction.update(user, {'language': fresh.language});
                          });
                        });
                      }),
                    ],
                  ),
                ))));
  }


}
