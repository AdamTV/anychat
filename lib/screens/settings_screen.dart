import 'dart:io';
import 'dart:core';
// import 'dart:js_interop';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/theme_option.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifications/notifications_util.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../components/combined_locale_info.dart';
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
  late bool isNotificationsEnabled;
  late String isoCode;
  late String displayName;
  late String email;

  ThemeMode themeMode =
      Theme.of(Utilities().globalKey.currentContext!).brightness ==
              Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark;
  late ThemeOption dropdownValue;

  @override
  initState() {
    super.initState();
    init = initUserData();
  }

  Future<void> initUserData() async {
    final userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    var options =
        themeOptions(mounted ? context : Utilities().globalKey.currentContext!);
    dropdownValue = options.last;

    Brightness userBrightness = userData.theme.brightness;

    ThemeMode userThemeMode =
        (userBrightness == Brightness.dark) ? ThemeMode.dark : ThemeMode.light;
    dropdownValue = options.firstWhere(
      (option) => option.themeMode == userThemeMode,
      orElse: () => options.last, // Assuming system is the last option
    );
    displayName = userData.username;
    email = userData.email;
    themeMode = userData.theme.brightness == Brightness.light
        ? ThemeMode.light
        : ThemeMode.dark;
    // Assuming userData.theme.brightness is available and is a Brightness value

    isoCode = UserData.localeToString(userData.locale);
    isNotificationsEnabled =
        await AwesomeNotifications().isNotificationAllowed();
  }

  List<ThemeOption> themeOptions(BuildContext context) {
    return [
      ThemeOption(localizationOf(context).light, ThemeMode.light),
      ThemeOption(localizationOf(context).dark, ThemeMode.dark),
      ThemeOption(localizationOf(context).system, ThemeMode.system),
    ];
  }

  late final Future init;

  @override
  Widget build(BuildContext context) {
    logger.d('loading settings screen');

    return FutureBuilder<void>(
      future: init, // Execute your async init function
      builder: (context, snapshot) {
        //Check if the future is complete
        if (snapshot.connectionState == ConnectionState.done) {
          //Future is complete, you can build your widget with the loaded data
          return Scaffold(
            appBar: AppBar(
                title: Text(
                    '${localizationOf(context).title} ${localizationOf(context).settings}'),
                leading: Builder(builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      NavigationService()
                          .pushNamedAndRemoveUntil('/conversations');
                    },
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  );
                })),
            body: SettingsList(
              contentPadding: const EdgeInsets.only(top: 12),
              sections: [
                SettingsSection(
                  title: Text(localizationOf(context).translation),
                  tiles: [
                    SettingsTile(
                      title: Text(localizationOf(context).language),
                      description: Text(getEndonymByLocaleCode(
                          isoCode, localizationOf(context))),
                      leading: const Icon(Icons.language),
                      onPressed: (BuildContext context) {
                        Navigator.of(context).pushNamed('/languages');
                      },
                    ),
                  ],
                ),
                SettingsSection(
                  title: Text(localizationOf(context).information),
                  tiles: [
                    SettingsTile(
                      title: Text(localizationOf(context).displayName),
                      description: Text(AnyChatAuth.currentUser.displayName),
                      leading: const Icon(Icons.drive_file_rename_outline),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title:
                                    Text(localizationOf(context).enterYourName),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      TextField(
                                          controller: _displayNameController,
                                          onChanged: (value) =>
                                              {displayName = value}),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(localizationOf(context).save),
                                    onPressed: () {
                                      if (displayName.isEmpty) {
                                        Utilities().showToast(
                                            localizationOf(context)
                                                .enterYourName);
                                        return;
                                      }
                                      AnyChatUser.updateDisplayName(
                                          displayName);
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
                              ? localizationOf(context).emailVerified
                              : localizationOf(context).verificationEmailSent),
                      description: Text(AnyChatAuth.currentUser.email),
                      leading: const Icon(Icons.email),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                    localizationOf(context).enterYourEmail),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: <Widget>[
                                      TextField(
                                          controller: _emailController,
                                          onChanged: (value) =>
                                              {email = value}),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(localizationOf(context).save),
                                    onPressed: () async {
                                      if (email.isEmpty) {
                                        Utilities().showToast(
                                            localizationOf(context)
                                                .enterYourEmail);
                                        return;
                                      }
                                      await AnyChatUser.updateEmail(email);
                                      NavigationService().goBack();
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
                  title: Text(localizationOf(context).picture),
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
                        title: Text(localizationOf(context).changePicture),
                        // enabled: changeProfilePictureEnabled,
                        leading: const Icon(Icons.photo),
                        trailing:
                            AnyChatUser.getAvatar(AnyChatAuth.currentUser))
                  ],
                ),
                SettingsSection(
                    title: Text(localizationOf(context).colors),
                    tiles: [
                      SettingsTile(
                        title: Text(localizationOf(context).theme),
                        description: Text(dropdownValue.name),
                        leading: const Icon(Icons.palette),
                        onPressed: (BuildContext context) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      localizationOf(context).selectYourTheme),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: <Widget>[
                                        DropdownButton<ThemeOption>(
                                          value: dropdownValue,
                                          // Ensure dropdownValue is of type ThemeOption
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
                                          items: themeOptions(context).map<
                                                  DropdownMenuItem<
                                                      ThemeOption>>(
                                              (ThemeOption option) {
                                            return DropdownMenuItem<
                                                ThemeOption>(
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
                  title: Text(localizationOf(context).notifications),
                  tiles: [
                    SettingsTile.switchTile(
                      title: Text(localizationOf(context).notifications),
                      leading: isNotificationsEnabled
                          ? const Icon(FontAwesomeIcons.solidBell)
                          : const Icon(FontAwesomeIcons.solidBellSlash),
                      onToggle: (value) async {
                        bool isAllowed = false;
                        if (value == true) {
                          isAllowed = await NotificationUtils
                              .requestBasicPermissionToSendNotifications(
                                  context);
                          if (!isAllowed) return;
                        } else {
                          isAllowed = await NotificationUtils
                              .redirectToPermissionsPage();
                        }
                        isNotificationsEnabled = await AwesomeNotifications().isNotificationAllowed();
                        setState(() {
                          isNotificationsEnabled = isNotificationsEnabled;
                        });

                        // await AnyChatUser.updateNotifications(
                        //     value);
                        // setState(() {
                        //   isNotificationsEnabled = value;
                        // });
                      },
                      initialValue: isNotificationsEnabled,
                    ),
                    SettingsTile(
                      title: Text('Manage notifications in device settings'),
                      leading: const Icon(FontAwesomeIcons.gear),
                      onPressed: (_) =>
                          NotificationUtils.redirectToPermissionsPage(),
                    )
                  ],
                ),
                SettingsSection(
                  title: Text(localizationOf(context).miscellaneous),
                  tiles: [
                    SettingsTile(
                        title: Text(localizationOf(context).privacyPolicy),
                        leading: const Icon(Icons.description),
                        onPressed: (ctx) => _launchPrivacyPolicy()),
                    SettingsTile(
                        title: Text(localizationOf(context).eula),
                        leading: const Icon(Icons.description),
                        onPressed: (ctx) => _launchEula()),
                    // SettingsTile(
                    //     title: 'Open source licenses',
                    //     leading: Icon(Icons.collections_bookmark)),
                  ],
                ),
                SettingsSection(
                  title: Text(localizationOf(context).dangerZone),
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
                        title: Text(localizationOf(context).deleteYourAccount),
                        leading: const Icon(Icons.delete_forever),
                        onPressed: (ctx) => _deleteAccount()),
                    // SettingsTile(
                    //     title: 'Open source licenses',
                    //     leading: Icon(Icons.collections_bookmark)),
                  ],
                ),
              ],
            ),
          );
        } else {
          //   While waiting for the future to complete, show a loading spinner or some placeholder
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
      subject: localizationOf(context).flagObjectionableContent,
      body: localizationOf(context).flagContentEmailBody,
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

  _deleteAccount() {
    showDialog(
        context: Utilities().globalKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizationOf(context).deleteYourAccount),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(localizationOf(context).areYouSureYouWantToDeleteAccount)
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                    localizationOf(Utilities().globalKey.currentContext!)
                        .cancel),
                onPressed: () {
                  NavigationService().goBack();
                },
              ),
              TextButton(
                child: Text(
                    localizationOf(Utilities().globalKey.currentContext!)
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
}
