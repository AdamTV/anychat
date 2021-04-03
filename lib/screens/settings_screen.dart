import 'dart:io';

import 'package:anychat/Screens/languages_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/anychat_auth.dart';
import '../components/anychat_user.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String isoCode;
  bool notifications = Utilities.prefs.getBool('notifications') ?? true;
  String displayName = AnyChatAuth.currentUser.displayName;
  ThemeMode themeMode;
  List<String> themes;
  String dropdownValue;

  @override
  Widget build(BuildContext context) {
    print('loading settings screen');
    themes = [AppLocalizations.of(context).system, AppLocalizations.of(context).light, AppLocalizations.of(context).dark];
    dropdownValue = Utilities.getThemeDropdownValue();

    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(title: Text('${AppLocalizations.of(context).title} ${AppLocalizations.of(context).settings}')),
          body: SettingsList(
            sections: [
              SettingsSection(
                title: AppLocalizations.of(context).translation,
                tiles: [
                  SettingsTile(
                    title: AppLocalizations.of(context).language,
                    subtitle: Utilities.getLanguageFromIsoCode(
                        AnyChatAuth.currentUser.language),
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
                title: AppLocalizations.of(context).information,
                tiles: [
                  SettingsTile(
                    title: AppLocalizations.of(context).displayName,
                    subtitle: displayName,
                    leading: Icon(Icons.drive_file_rename_outline),
                    onPressed: (BuildContext context) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context).enterYourName),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    RoundedInputField(
                                        initialValue:
                                            AnyChatAuth.currentUser.displayName,
                                        icon: Icons.drive_file_rename_outline,
                                        onChanged: (value) =>
                                            {displayName = value}),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(AppLocalizations.of(context).save),
                                  onPressed: () async {
                                    await AnyChatUser.updateDisplayName(
                                        displayName);
                                    Navigator.of(context)
                                        .pushReplacement(MaterialPageRoute(
                                      builder: (_) => SettingsScreen(),
                                    ));
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  ),
                  SettingsTile(
                      title: AppLocalizations.of(context).email,
                      subtitle: AnyChatAuth.currentUser.email,
                      leading: Icon(Icons.email)),
                ],
              ),
              SettingsSection(
                title: AppLocalizations.of(context).picture,
                tiles: [
                  // SettingsTile.switchTile(
                  //   title: 'Profile Picture',
                  //   subtitle: 'Use picture from linked account',
                  //   switchValue: useLinkedPicture,
                  //   onToggle: (bool value) async {
                  //     if (value == true) {
                  //       await AnyChatUser.updatePhotoUrl(AnyChatAuth.linkedAccountPhotoUrl);
                  //     }
                  //     setState(() {
                  //       useLinkedPicture = value;
                  //       changeProfilePictureEnabled = !value;
                  //     });
                  //   },
                  // ),
                  SettingsTile(
                      onPressed: (v) => {getImage(true)},
                      title: AppLocalizations.of(context).changePicture,
                      // enabled: changeProfilePictureEnabled,
                      leading: Icon(Icons.photo),
                      trailing: CircleAvatar(
                          backgroundImage:
                              NetworkImage(AnyChatAuth.currentUser.photoUrl))),
                ],
              ),
              SettingsSection(title: AppLocalizations.of(context).colors, tiles: [
                SettingsTile(
                  title: AppLocalizations.of(context).theme,
                  subtitle: dropdownValue,
                  leading: Icon(Icons.palette),
                  onPressed: (BuildContext context) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context).selectYourTheme),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  DropdownButton<String>(
                                    value: dropdownValue,
                                    iconSize: 24,
                                    elevation: 16,
                                    onChanged: (String newValue) async {
                                      setState(() {
                                        dropdownValue = newValue;
                                      });
                                      await Utilities
                                          .setThemeFromDropdownValue(newValue);
                                      Navigator.pop(context);
                                      main();
                                    },
                                    items: themes.map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  },
                )
              ]),
              SettingsSection(
                title: AppLocalizations.of(context).notifications,
                tiles: [
                  SettingsTile.switchTile(
                    title: AppLocalizations.of(context).notifications,
                    leading: Icon(Icons.notifications_active),
                    switchValue: notifications,
                    onToggle: (value) async {
                      setState(() {
                        notifications = value;
                      });
                      await Utilities.prefs.setBool('notifications', value);
                    },
                  )
                ],
              )
              // SettingsSection(
              //   title: 'Misc',
              //   tiles: [
              //     SettingsTile(
              //         title: 'Terms of Service', leading: Icon(Icons.description)),
              //     SettingsTile(
              //         title: 'Open source licenses',
              //         leading: Icon(Icons.collections_bookmark)),
              //   ],
              // ),
            ],
          ),
        ),
        onWillPop: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
              return ConversationsScreen();
            })));
  }

// Image Picker
//     List<File> _images = [];
  File _image; // Used only if you need a single picture

  Future getImage(bool gallery) async {
    ImagePicker picker = ImagePicker();
    PickedFile pickedFile;
    // Let user select photo from gallery
    if (gallery) {
      pickedFile = await picker.getImage(
        source: ImageSource.gallery,
      );
    }
    // Otherwise open camera to get new photo
    else {
      pickedFile = await picker.getImage(
        source: ImageSource.camera,
      );
    }

    setState(() {
      if (pickedFile != null) {
        // _images.add(File(pickedFile.path));
        _image = File(pickedFile.path); // Use if you only need a single picture
      } else {
        print('No image selected.');
      }
    });
    await AnyChatUser.updatePhotoUrl(await uploadFile(_image));
    setState(() {});
  }

  Future<String> uploadFile(File _image) async {
    Reference storageReference =
        FirebaseStorage.instance.ref().child('images/${_image.path}');
    UploadTask uploadTask = storageReference.putFile(_image);
    await uploadTask.whenComplete(() => null);
    print('File Uploaded');
    String returnURL;
    await storageReference.getDownloadURL().then((fileURL) {
      returnURL = fileURL;
    });
    return returnURL;
  }
}
