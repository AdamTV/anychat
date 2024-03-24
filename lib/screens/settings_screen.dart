import 'dart:io';
import 'dart:core';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/theme_option.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_maanger.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifier_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_speech/generated/google/protobuf/any.pb.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'blocked_users_screen.dart';
import 'package:mailto/mailto.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: AnyChatAuth.currentUser.email,
  );
  final TextEditingController _displayNameController = TextEditingController(
  text: AnyChatAuth.currentUser.displayName,
  );
  bool isNotificationsEnabled = AnyChatAuth.currentUser.notificationsEnabled;
  String isoCode = AnyChatAuth.currentUser.language;
  String displayName = AnyChatAuth.currentUser.displayName;
  String email = AnyChatAuth.currentUser.email;
  ThemeMode themeMode =
      Theme.of(Utilities().globalKey.currentContext!).brightness ==
              Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark;
  late ThemeOption dropdownValue;

  List<ThemeOption> themeOptions(BuildContext context) {
    return [
      ThemeOption(AppLocalizations.of(context)!.light, ThemeMode.light),
      ThemeOption(AppLocalizations.of(context)!.dark, ThemeMode.dark),
      ThemeOption(AppLocalizations.of(context)!.system, ThemeMode.system),
    ];
  }

  Future<void> initUserData() async {
    var options = themeOptions(context);
    dropdownValue = options.last;
    var userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    displayName = userData.username;
    email = userData.email;
    themeMode = userData.theme.brightness == Brightness.light
        ? ThemeMode.light
        : ThemeMode.dark;
    // Assuming userData.theme.brightness is available and is a Brightness value
    Brightness userBrightness = userData.theme.brightness;
    ThemeMode userThemeMode =
        (userBrightness == Brightness.dark) ? ThemeMode.dark : ThemeMode.light;
    dropdownValue =
        options
            .firstWhere(
      (option) => option.themeMode == userThemeMode,
      orElse: () =>
          options.last, // Assuming system is the last option
    );
    isoCode = UserData.localeToString(userData.locale);
    isNotificationsEnabled = userData.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    logger.d('loading settings screen');

    return FutureBuilder<void>(
      future: initUserData(), // Execute your async init function
      builder: (context, snapshot) {
        // Check if the future is complete
        if (snapshot.connectionState == ConnectionState.done) {
          // Future is complete, you can build your widget with the loaded data
          return Scaffold(
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
                        description:
                        Text(Utilities().getLanguageFromIsoCode(isoCode)),
                        leading: const Icon(Icons.language),
                        onPressed: (BuildContext context) {
                          Navigator.of(context).pushNamed('/languages');
                        },
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: Text(AppLocalizations.of(context)!.information),
                    tiles: [
                      SettingsTile(
                        title: Text(AppLocalizations.of(context)!.displayName),
                        description: Text(AnyChatAuth.currentUser.displayName),
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
                                        TextField(
                                            controller:
                                            _displayNameController,
                                            onChanged: (value) =>
                                            {displayName = value}),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.save),
                                      onPressed: ()  {
                                        if (displayName.isEmpty) {
                                          Utilities().showToast(
                                              AppLocalizations.of(context)!
                                                  .enterYourName);
                                          return;
                                        }
                                        AnyChatUser.updateDisplayName(displayName);
                                      },
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
                      SettingsTile(
                        title: Text(FirebaseAuth.instance.currentUser!.emailVerified
                            ? AppLocalizations.of(context)!.emailVerified
                            : AppLocalizations.of(context)!.verificationEmailSent),
                        description: Text(AnyChatAuth.currentUser.email),
                        leading: const Icon(Icons.email),
                        onPressed: (BuildContext context) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      AppLocalizations.of(context)!.enterYourEmail),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: <Widget>[
                                        TextField(
                                            controller: _emailController,
                                            onChanged: (value) => {email = value}),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.save),
                                      onPressed: () async {
                                        if (email.isEmpty) {
                                          Utilities().showToast(
                                              AppLocalizations.of(context)!
                                                  .enterYourEmail);
                                          return;
                                        }
                                        await AnyChatUser.updateEmail(email)
                                            .then((value) => {
                                          Navigator.of(context)
                                              .pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                const SettingsScreen(),
                                              ))
                                        });
                                      },
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
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
                          trailing: AnyChatAuth.currentUser.photoUrl != ''
                              ? CircleAvatar(
                              backgroundImage:
                              NetworkImage(AnyChatAuth.currentUser.photoUrl))
                              : CircleAvatar(
                              child: Text(AnyChatAuth.currentUser.displayName
                                  .substring(0, 1))))
                    ],
                  ),
                  SettingsSection(
                      title: Text(AppLocalizations.of(context)!.colors),
                      tiles: [
                        SettingsTile(
                          title: Text(AppLocalizations.of(context)!.theme),
                          description: Text(dropdownValue.name),
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
                                          DropdownButton<ThemeOption>(
                                            value:
                                            dropdownValue, // Ensure dropdownValue is of type ThemeOption
                                            iconSize: 24,
                                            elevation: 16,
                                            onChanged: (ThemeOption? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  dropdownValue = newValue;
                                                  AnyChatUser.updateTheme(
                                                      newValue.themeMode);
                                                  NavigationService().goBack();
                                                });
                                              }
                                            },
                                            items: themeOptions(context)
                                                .map<DropdownMenuItem<ThemeOption>>(
                                                    (ThemeOption option) {
                                                  return DropdownMenuItem<ThemeOption>(
                                                    value: option,
                                                    child: Text(option.name),
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
                        onToggle: (value) {
                          setState(() {
                            isNotificationsEnabled = value;
                          });
                          AnyChatUser.updateNotifications(value);
                        },
                        initialValue: isNotificationsEnabled,
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
              ));

        } else {
          // While waiting for the future to complete, show a loading spinner or some placeholder
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

// ...somewhere in your Flutter app...
  Future<void> launchMailto() async {
    final mailtoLink = Mailto(
      to: ['info@anychat.ca'],
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
        uploadFile(_image)
            .then((value) => {AnyChatUser.updatePhotoUrl(value)})
            .onError((error, stackTrace) {
          logger.e("Error changing user profile image.", error, stackTrace);
          return {};
        });
      } else {
        logger.d('No image selected.');
      }
    });
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
      context: Utilities().globalKey.currentContext!,
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
                  AppLocalizations.of(Utilities().globalKey.currentContext!)!
                      .cancel),
              onPressed: () {
                NavigationService().goBack();
              },
            ),
            TextButton(
              child: Text(
                  AppLocalizations.of(Utilities().globalKey.currentContext!)!
                      .approve),
              onPressed: () async {
                AnyChatAuth.currentUser.deleteAccount();
              },
            ),
          ],
        );
      });
}

_launchPrivacyPolicy() async {
  await launchUrlString("https://anychat.ca/privacy-policy");
}

_launchEula() async {
  await launchUrlString("https://anychat.ca/eula");
}
