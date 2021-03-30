import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:anychat/Screens/languages_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String isoCode;

  bool useLinkedPicture = true;
  bool changeProfilePictureEnabled = false;
  // String dropdownValue = Utilities.getLanguageFromIsoCode(AnyChatAuth.currentUser.language);
  //                   Text('Name'),
  //                   RoundedInputField(hintText: "Name",),
  //                   Text('Picture'),
  //                   Text('E-mail'),
  //                   Text('Color Theme'),
  @override
  Widget build(BuildContext context) {
    print('loading settings screen');
    return Scaffold(
      appBar: AppBar(title: Text('AnyChat Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: 'Translation',
            tiles: [
              SettingsTile(
                title: 'Language',
                subtitle: Utilities.getLanguageFromIsoCode(AnyChatAuth.currentUser.language),
                leading: Icon(Icons.language),
                onPressed: (BuildContext context) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => LanguagesScreen(),
                  ));
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Information',
            tiles: [
              SettingsTile(
                title: 'Display Name',
                subtitle: AnyChatAuth.currentUser.displayName,
                leading: Icon(Icons.drive_file_rename_outline),
                onPressed: (BuildContext context) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => LanguagesScreen(),
                  ));
                },
              ),
              SettingsTile(title: 'E-mail', subtitle: AnyChatAuth.currentUser.email, leading: Icon(Icons.email)),
            ],
          ),
          SettingsSection(
            title: 'Picture',
            tiles: [
              SettingsTile.switchTile(
                title: 'Profile Picture',
                subtitle: 'Use picture from linked account',
                switchValue: useLinkedPicture,
                onToggle: (bool value) {
                  setState(() {
                    useLinkedPicture = value;
                    changeProfilePictureEnabled = !value;
                  });
                },
              ),
              SettingsTile(title: 'Change Picture', enabled: changeProfilePictureEnabled, leading: Icon(Icons.photo)),
            ],
          ),
          SettingsSection(
            title: 'Misc',
            tiles: [
              SettingsTile(
                  title: 'Terms of Service', leading: Icon(Icons.description)),
              SettingsTile(
                  title: 'Open source licenses',
                  leading: Icon(Icons.collections_bookmark)),
            ],
          ),
        ],
      ),
    );    //print(ConversationsScreen.testWidgets.length);
    // return Scaffold(
    //     appBar: AppBar(
    //       //leading: Icon(Icons.restaurant),
    //       title: Text('AnyChat'),
    //       // bottom: PreferredSize(
    //       //   preferredSize: Size(320, 48),
    //       //   child: Padding(
    //       //     padding: EdgeInsets.fromLTRB(6, 0, 6, 4),
    //       //     child: FilterBar(
    //       //       filter: _filter,
    //       //       onPressed: _onFilterBarPressed,
    //       //     ),
    //       //   ),
    //       // ),
    //     ),
    //     drawer: Drawer(
    //       // Add a ListView to the drawer. This ensures the user can scroll
    //       // through the options in the drawer if there isn't enough vertical
    //       // space to fit everything.
    //       child: ListView(
    //         // Important: Remove any padding from the ListView.
    //         padding: EdgeInsets.zero,
    //         children: <Widget>[
    //           DrawerHeader(
    //             child: Text(
    //               'AnyChat',
    //               style: TextStyle(color: Theme.of(context).primaryColorLight),
    //             ),
    //             decoration: BoxDecoration(
    //               color: Theme.of(context).primaryColor,
    //             ),
    //           ),
    //           ListTile(
    //               title: Text('Back'),
    //               onTap: () {
    //                 Navigator.pop(context);
    //                 Navigator.pop(context);
    //                 Navigator.pop(context);
    //               }),
    //           ListTile(
    //               title: Text('Logout'),
    //               onTap: () async {
    //                 await AnyChatAuth.signOut();
    //                 Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                         builder: (context) => WelcomeScreen()));
    //               }),
    //         ],
    //       ),
    //     ),
    //     body: Center(
    //         child: Container(
    //             constraints: BoxConstraints(maxWidth: 1280),
    //             child: Center(
    //               child: Column(
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: <Widget>[
    //                   Text('Name'),
    //                   RoundedInputField(hintText: "Name",),
    //                   Text('Picture'),
    //                   Text('E-mail'),
    //                   Text('Color Theme'),
    //                   Text('Language'),
    //                   DropdownButton<String>(
    //                     value: dropdownValue,
    //                     icon: Icon(Icons.language),
    //                     iconSize: 24,
    //                     elevation: 16,
    //                     style: TextStyle(color: Theme.of(context).primaryColor),
    //                     onChanged: (String newValue) {
    //                       setState(() {
    //                         dropdownValue = newValue;
    //                       });
    //                       isoCode = isoMap[newValue];
    //                       print(isoCode);
    //                     },
    //                     items: isoMap.keys
    //                         .map<DropdownMenuItem<String>>((String value) {
    //                       return DropdownMenuItem<String>(
    //                         value: value,
    //                         child: Text(value),
    //                       );
    //                     }).toList(),
    //                   ),
    //                   // RoundedInputField(icon: Icons.language,onChanged:(value) {language = value;}),
    //                   RoundedButton(
    //                       text: "SAVE",
    //                       press: () async {
    //                         final user = FirebaseFirestore.instance
    //                             .collection("users")
    //                             .doc(AnyChatAuth.currentUser.id);
    //                         await FirebaseFirestore.instance
    //                             .runTransaction((Transaction transaction) {
    //                           return transaction
    //                               .get(user)
    //                               .then((DocumentSnapshot doc) =>
    //                                   AnyChatUser.fromSnapshot(doc))
    //                               .then((AnyChatUser fresh) async {
    //                             transaction
    //                                 .update(user, {'language': isoCode});
    //                             AnyChatAuth.currentUser = await AnyChatUser.findUserById(AnyChatAuth.currentUser.id);
    //                             Utilities.showAlertDialog(context, "Success",
    //                                 "Your settings have been saved.");
    //                           });
    //                         });
    //                       }),
    //                 ],
    //               ),
    //             ))));
  }
}

