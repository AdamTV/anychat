import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsBody extends StatefulWidget {
  @override
  _SettingsBodyState createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  String isoCode;
  String dropdownValue = Utilities.getDropDownValue(AnyChatAuth.currentUser.language);

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
                  style: TextStyle(color: Theme.of(context).primaryColorLight),
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
                  onTap: () async {
                    await AnyChatAuth.signOut();
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
                      // Text('Language'),
                      DropdownButton<String>(
                        value: dropdownValue,
                        icon: Icon(Icons.language),
                        iconSize: 24,
                        elevation: 16,
                        style: TextStyle(color: Theme.of(context).primaryColor),
                        onChanged: (String newValue) {
                          setState(() {
                            dropdownValue = newValue;
                          });
                          isoCode = isoMap[newValue];
                          print(isoCode);
                        },
                        items: isoMap.keys
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      // RoundedInputField(icon: Icons.language,onChanged:(value) {language = value;}),
                      RoundedButton(
                          text: "SAVE",
                          press: () async {
                            final user = FirebaseFirestore.instance
                                .collection("users")
                                .doc(AnyChatAuth.currentUser.id);
                            await FirebaseFirestore.instance
                                .runTransaction((Transaction transaction) {
                              return transaction
                                  .get(user)
                                  .then((DocumentSnapshot doc) =>
                                      AnyChatUser.fromSnapshot(doc))
                                  .then((AnyChatUser fresh) async {
                                transaction
                                    .update(user, {'language': isoCode});
                                AnyChatAuth.currentUser = await AnyChatUser.findUserById(AnyChatAuth.currentUser.id);
                                Utilities.showAlertDialog(context, "Success",
                                    "Your settings have been saved.");
                              });
                            });
                          }),
                    ],
                  ),
                ))));
  }
}
