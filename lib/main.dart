import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/notifications.dart';
import 'package:anychat/screens/add_chatter_screen.dart';
import 'package:anychat/screens/call_screen.dart';
import 'package:anychat/screens/chat_screen.dart';
import 'package:anychat/screens/contacts_screen.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/languages_screen.dart';
import 'package:anychat/screens/live_translator_screen.dart';
import 'package:anychat/screens/login_screen.dart';
import 'package:anychat/screens/register_screen.dart';
import 'package:anychat/screens/search_chatter_by_email_screen.dart';
import 'package:anychat/screens/settings_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'components/utilities.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Notifications().init();
  Firebase.initializeApp().then((value) => {
        Ads.init(),
        Utilities.init().then((value) => {
              runApp(MaterialApp(
                routes: {
                  '/addChatter': (context) => AddChatterScreen(),
                  '/call': (context) => CallScreen(),
                  '/chat': (context) => ChatScreen(),
                  '/contacts': (context) => ContactsScreen(),
                  '/conversations': (context) => ConversationsScreen(),
                  '/languages': (context) => LanguagesScreen(),
                  '/liveTranslator': (context) => LiveTranslatorScreen(),
                  '/login': (context) => LoginScreen(),
                  '/register': (context) => RegisterScreen(),
                  '/searchChatterByEmail': (context) =>
                      SearchChatterByEmailScreen(),
                  '/settings': (context) => SettingsScreen(),
                  '/welcome': (context) => WelcomeScreen(),
                },
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (BuildContext context) =>
                    AppLocalizations.of(context).title,
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: [
                  const Locale('af', ''),
                  const Locale('sq', ''),
                  const Locale('am', ''),
                  const Locale('ar', ''),
                  const Locale('hy', ''),
                  const Locale('az', ''),
                  const Locale('eu', ''),
                  const Locale('be', ''),
                  const Locale('bn', ''),
                  const Locale('bs', ''),
                  const Locale('bg', ''),
                  const Locale('ca', ''),
                  const Locale('ceb', ''),
                  const Locale('zh', ''),
                  const Locale('co', ''),
                  const Locale('hr', ''),
                  const Locale('cs', ''),
                  const Locale('da', ''),
                  const Locale('nl', ''),
                  const Locale('en', ''),
                  const Locale('eo', ''),
                  const Locale('et', ''),
                  const Locale('fi', ''),
                  const Locale('fr', ''),
                  const Locale('fy', ''),
                  const Locale('gl', ''),
                  const Locale('ka', ''),
                  const Locale('de', ''),
                  const Locale('el', ''),
                  const Locale('gu', ''),
                  const Locale('ht', ''),
                  const Locale('ha', ''),
                  const Locale('haw', ''),
                  const Locale('iw', ''),
                  const Locale('hi', ''),
                  const Locale('hmn', ''),
                  const Locale('hu', ''),
                  const Locale('is', ''),
                  const Locale('ig', ''),
                  const Locale('id', ''),
                  const Locale('ga', ''),
                  const Locale('it', ''),
                  const Locale('ja', ''),
                  const Locale('jv', ''),
                  const Locale('kn', ''),
                  const Locale('kk', ''),
                  const Locale('km', ''),
                  const Locale('rw', ''),
                  const Locale('ko', ''),
                  const Locale('ku', ''),
                  const Locale('ky', ''),
                  const Locale('lo', ''),
                  const Locale('la', ''),
                  const Locale('lv', ''),
                  const Locale('lt', ''),
                  const Locale('lb', ''),
                  const Locale('mk', ''),
                  const Locale('mg', ''),
                  const Locale('ms', ''),
                  const Locale('ml', ''),
                  const Locale('mt', ''),
                  const Locale('mi', ''),
                  const Locale('mr', ''),
                  const Locale('mn', ''),
                  const Locale('my', ''),
                  const Locale('ne', ''),
                  const Locale('no', ''),
                  const Locale('ny', ''),
                  const Locale('or', ''),
                  const Locale('ps', ''),
                  const Locale('fa', ''),
                  const Locale('pl', ''),
                  const Locale('pt', ''),
                  const Locale('pa', ''),
                  const Locale('ro', ''),
                  const Locale('ru', ''),
                  const Locale('sm', ''),
                  const Locale('gd', ''),
                  const Locale('sr', ''),
                  const Locale('st', ''),
                  const Locale('sn', ''),
                  const Locale('sd', ''),
                  const Locale('si', ''),
                  const Locale('sk', ''),
                  const Locale('sl', ''),
                  const Locale('so', ''),
                  const Locale('es', ''),
                  const Locale('su', ''),
                  const Locale('sw', ''),
                  const Locale('sv', ''),
                  const Locale('tl', ''),
                  const Locale('tg', ''),
                  const Locale('ta', ''),
                  const Locale('tt', ''),
                  const Locale('te', ''),
                  const Locale('th', ''),
                  const Locale('tr', ''),
                  const Locale('tk', ''),
                  const Locale('uk', ''),
                  const Locale('ur', ''),
                  const Locale('ug', ''),
                  const Locale('uz', ''),
                  const Locale('vi', ''),
                  const Locale('cy', ''),
                  const Locale('xh', ''),
                  const Locale('yi', ''),
                  const Locale('yo', ''),
                  const Locale('zu', ''),
                ],
                theme: kDefaultTheme,
                darkTheme: kDarkTheme,
                themeMode: Utilities.getThemeMode(),
                home: StreamBuilder<User>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData && (!snapshot.data.isAnonymous)) {
                      AnyChatUser.context = context;
                      AnyChatLocale.init(context);
                      print(snapshot.data);
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(snapshot.data.providerData[0].uid)
                          .get()
                          .then((value) => AnyChatUser.fromSnapshot(value))
                          .then((AnyChatUser user) {
                        AnyChatAuth.currentUser = user;
                        print('returning ConversationsScreen');
                        Navigator.push(context,
                            MaterialPageRoute(builder: (BuildContext context) {
                          return ConversationsScreen();
                        }));
                      });
                    }
                    print('returning WelcomeScreen');
                    return WelcomeScreen();
                  },
                ),
              ))
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
