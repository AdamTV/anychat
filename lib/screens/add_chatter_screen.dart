import 'package:anychat/Screens/search_chatter_by_email_screen.dart';
import 'package:anychat/Screens/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'contacts_screen.dart';
import 'conversations_screen.dart';

class AddChatterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String email;
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
                    //_handleSignOut();
                  }),
              ListTile(
                  title: Text('Logout'),
                  onTap: () async {
                    await AnyChatAuth.signOut();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WelcomeScreen()));
                    //_handleSignOut();
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
                      RoundedInputField(
                          hintText: "Find chatter by e-mail",
                          onChanged: (value) {
                            email = value;
                          }),
                      RoundedButton(
                          text: "Search",
                          press: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SearchChatterByEmailScreen(email: email)));
                          }),
                      Divider(height: 100),
                      Text('See who is already on AnyChat!'),
                      RoundedButton(
                          text: "Contacts",
                          press: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ContactsScreen()));
                          }),
                    ],
                  ),
                ))));
  }
}
