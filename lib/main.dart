import 'package:anychat/Screens/welcome_screen.dart';
import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/anychatLocale.dart';
import 'package:anychat/components/notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Screens/conversations_screen.dart';
import 'components/utilities.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Notifications().init();
  AnyChatLocale.init();
  Firebase.initializeApp().then((value) => {
    Ads.init(),
    Utilities.init().then((value) => {
              runApp(MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'AnyChat',
                  localizationsDelegates: [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [
                    const Locale('en', ''), // English, no country code
                    const Locale('es', ''), // Spanish, no country code
                  ],
                  theme: kDefaultTheme,
                  darkTheme: kDarkTheme,
                  themeMode: Utilities.getThemeMode(),
                  home: StreamBuilder<User>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (BuildContext context, snapshot) {
                      if (snapshot.hasData && (!snapshot.data.isAnonymous)) {
                        print(snapshot.data);
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(snapshot.data.providerData[0].uid)
                            .get()
                            .then((value) => AnyChatUser.fromSnapshot(value))
                            .then((AnyChatUser user) {
                          AnyChatAuth.currentUser = user;
                          print('returning ConversationsScreen');
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ConversationsScreen()));
                        });
                      }
                      print('returning WelcomeScreen');
                      return WelcomeScreen();
                    },
                  )))
            }),
        FirebaseAuth.instance.authStateChanges().listen((User user) {
          if (user == null) {
            print('User is signed out!');
          } else {
            print('User is signed in!');
          }
        }),
      });
}
