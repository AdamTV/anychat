import 'dart:io';
import 'dart:core';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/languages_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'blocked_users_screen.dart';
import 'package:mailto/mailto.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? isoCode;
  bool notifications = Utilities.prefs.getBool('notifications') ?? true;
  String? displayName = AnyChatAuth.currentUser!.displayName;
  ThemeMode? themeMode;
  late List<String> themes;
  String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    logger.d('loading settings screen');
    themes = [
      AppLocalizations.of(context)!.system,
      AppLocalizations.of(context)!.light,
      AppLocalizations.of(context)!.dark
    ];
    dropdownValue = Utilities.getThemeDropdownValue();

    return PopScope(
        child: Scaffold(
          appBar: AppBar(
              title: Text(
                  '${AppLocalizations.of(context)!.title} ${AppLocalizations.of(context)!.settings}')),
          body: SettingsList(
            contentPadding: const EdgeInsets.only(top: 12),
            sections: [
              SettingsSection(
                title: Text(AppLocalizations.of(context)!.translation),
                tiles: [
                  SettingsTile(
                    title: Text(AppLocalizations.of(context)!.language),
                    description: Text(Utilities.getLanguageFromIsoCode(
                        AnyChatAuth.currentUser!.language)),
                    leading: const Icon(Icons.language),
                    onPressed: (BuildContext context) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => const LanguagesScreen(),
                      ));
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: Text(AppLocalizations.of(context)!.information),
                tiles: [
                  SettingsTile(
                    title: Text(AppLocalizations.of(context)!.displayName),
                    description: Text(displayName!),
                    leading: const Icon(Icons.drive_file_rename_outline),
                    onPressed: (BuildContext context) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                  AppLocalizations.of(context)!.enterYourName),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    RoundedInputField(
                                        initialValue: AnyChatAuth
                                            .currentUser!.displayName,
                                        icon: Icons.drive_file_rename_outline,
                                        onChanged: (value) =>
                                            {displayName = value}),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child:
                                      Text(AppLocalizations.of(context)!.save),
                                  onPressed: () async {
                                    if (displayName!.isEmpty ||
                                        displayName == null) {
                                      Utilities.showToast(
                                          AppLocalizations.of(context)!
                                              .enterYourName);
                                      return;
                                    }
                                    await AnyChatUser.updateDisplayName(
                                        displayName);
                                    Navigator.of(mounted
                                            ? context
                                            : Utilities
                                                .globalKey.currentContext!)
                                        .pushReplacement(MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ));
                                  },
                                ),
                              ],
                            );
                          });
                    },
                  ),
                  SettingsTile(
                      title: Text(
                          FirebaseAuth.instance.currentUser!.emailVerified
                              ? AppLocalizations.of(context)!.emailVerified
                              : AppLocalizations.of(context)!
                                  .verificationEmailSent),
                      description: Text(AnyChatAuth.currentUser!.email),
                      leading: const Icon(Icons.email)),
                ],
              ),
              SettingsSection(
                title: Text(AppLocalizations.of(context)!.picture),
                tiles: [
                  // SettingsTile.switchTile(
                  //   title: 'Profile Picture',
                  //   description: 'Use picture from linked account',
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
                      title: Text(AppLocalizations.of(context)!.changePicture),
                      // enabled: changeProfilePictureEnabled,
                      leading: const Icon(Icons.photo),
                      trailing: AnyChatAuth.currentUser!.photoUrl != ''
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                  AnyChatAuth.currentUser!.photoUrl))
                          : CircleAvatar(
                              child: Text(AnyChatAuth.currentUser!.displayName
                                  .substring(0, 1))))
                ],
              ),
              SettingsSection(
                  title: Text(AppLocalizations.of(context)!.colors),
                  tiles: [
                    SettingsTile(
                      title: Text(AppLocalizations.of(context)!.theme),
                      description: Text(dropdownValue!),
                      leading: const Icon(Icons.palette),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .selectYourTheme),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      DropdownButton<String>(
                                        value: dropdownValue,
                                        iconSize: 24,
                                        elevation: 16,
                                        onChanged: (String? newValue) async {
                                          setState(() {
                                            dropdownValue = newValue;
                                          });
                                          Utilities.setThemeFromDropdownValue(
                                              newValue);
                                          Navigator.of(context).popUntil(
                                              (route) => route.isFirst);
                                          Navigator.of(context)
                                              .pushReplacementNamed('/');
                                        },
                                        items: themes
                                            .map<DropdownMenuItem<String>>(
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
                title: Text(AppLocalizations.of(context)!.notifications),
                tiles: [
                  SettingsTile.switchTile(
                    title: Text(AppLocalizations.of(context)!.notifications),
                    leading: const Icon(Icons.notifications_active),
                    // switchValue: notifications,
                    onToggle: (value) async {
                      setState(() {
                        notifications = value;
                      });
                      await Utilities.prefs.setBool('notifications', value);
                    },
                    initialValue: null,
                  )
                ],
              ),
              SettingsSection(
                title: Text(AppLocalizations.of(context)!.miscellaneous),
                tiles: [
                  SettingsTile(
                      title: Text(AppLocalizations.of(context)!.privacyPolicy),
                      leading: const Icon(Icons.description),
                      onPressed: (ctx) => _launchPrivacyPolicy()),
                  SettingsTile(
                      title: Text(AppLocalizations.of(context)!.eula),
                      leading: const Icon(Icons.description),
                      onPressed: (ctx) => _launchEula()),
                  // SettingsTile(
                  //     title: 'Open source licenses',
                  //     leading: Icon(Icons.collections_bookmark)),
                ],
              ),
              SettingsSection(
                title: Text(AppLocalizations.of(context)!.dangerZone),
                tiles: [
                  SettingsTile(
                      title: const Text("Blocked"),
                      leading: const Icon(Icons.block),
                      onPressed: (ctx) => {
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                              builder: (_) => const BlockedUsersScreen(),
                            ))
                          }),
                  SettingsTile(
                      title: const Text("Flag Content"),
                      leading: const Icon(Icons.flag),
                      onPressed: (ctx) async => {await launchMailto()}),
                  SettingsTile(
                      title:
                          Text(AppLocalizations.of(context)!.deleteYourAccount),
                      leading: const Icon(Icons.delete_forever),
                      onPressed: (ctx) => _deleteAccount()),
                  // SettingsTile(
                  //     title: 'Open source licenses',
                  //     leading: Icon(Icons.collections_bookmark)),
                ],
              ),
            ],
          ),
        ),
        onPopInvoked: (didPop) => _onPopInvoked(context, didPop));        
  }

// ...somewhere in your Flutter app...
  Future<void> launchMailto() async {
    final mailtoLink = Mailto(
      to: ['admin@alphatechnology.ca'],
      // cc: ['cc1@example.com', 'cc2@example.com'],
      subject: AppLocalizations.of(context)?.flagObjectionableContent,
      body: AppLocalizations.of(context)?.flagContentEmailBody,
    );
    // Convert the Mailto instance into a string.
    // Use either Dart's string interpolation
    // or the toString() method.
    await launchUrlString('$mailtoLink');
  }

// Image Picker
//     List<File> _images = [];
  late File _image; // Used only if you need a single picture

  Future getImage(bool gallery) async {
    ImagePicker picker = ImagePicker();
    XFile? pickedFile;
    // Let user select photo from gallery
    if (gallery) {
      pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
    }
    // Otherwise open camera to get new photo
    else {
      pickedFile = await picker.pickImage(
        source: ImageSource.camera,
      );
    }

    setState(() {
      if (pickedFile != null) {
        // _images.add(File(pickedFile.path));
        _image = File(pickedFile.path); // Use if you only need a single picture
      } else {
        logger.d('No image selected.');
      }
    });
    await AnyChatUser.updatePhotoUrl(await uploadFile(_image));
    setState(() {});
  }

  Future<String?> uploadFile(File image) async {
    Reference storageReference =
        FirebaseStorage.instance.ref().child('images/${image.path}');
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.whenComplete(() => null);
    logger.d('File Uploaded');
    String? returnURL;
    await storageReference.getDownloadURL().then((fileURL) {
      returnURL = fileURL;
    });
    return returnURL;
  }
}

_deleteAccount() {
  showDialog(
      context: Utilities.globalKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteYourAccount),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!
                    .areYouSureYouWantToDeleteAccount)
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                  AppLocalizations.of(Utilities.globalKey.currentContext!)!
                      .cancel),
              onPressed: () {
                Navigator.of(context)
                    .popUntil((route) => route.settings.name == '/');
              },
            ),
            TextButton(
              child: Text(
                  AppLocalizations.of(Utilities.globalKey.currentContext!)!
                      .approve),
              onPressed: () async {
                AnyChatAuth.currentUser!.deleteAccount();
              },
            ),
          ],
        );
      });
}

_launchPrivacyPolicy() async {
  await launchUrlString(
      "https://www.alphatechnology.ca/anychat-privacy-policy");
}

_launchEula() async {
  await launchUrlString("https://www.alphatechnology.ca/anychat-eula");
}

void _onPopInvoked(BuildContext context, bool didPop) {
  try {
    if (didPop){
      Navigator.pushNamed(context, '/conversations');
    }
  } on Exception catch (e) {
    logger.e(e.toString());
  }
}
