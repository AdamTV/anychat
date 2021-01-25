import 'package:anychat/Screens/AddChatter/addchatter_screen.dart';
import 'package:anychat/Screens/Chat/chat_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/constants.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  title: Text('Logout'),
                  onTap: () {
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
                ))));
  }
}
