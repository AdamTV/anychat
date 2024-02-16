import 'dart:io';

import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/screens/add_chatter_screen.dart';
import 'package:anychat/screens/call_screen.dart';
import 'package:anychat/screens/chat_screen.dart';
import 'package:anychat/screens/contacts_screen.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/forgot_password.dart';
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
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Notifications().init();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) => {
        Ads.init(),
        Utilities.init().then((value) => {runApp(const AnyChat())}),
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user == null) {
            print('User is signed out!');
          } else {
            print('User is signed in!');
            print('User is ${user.emailVerified ? "" : "NOT "}verified!');
            // if (!user.emailVerified) {
            //   var actionCodeSettings = ActionCodeSettings(
            //       url:
            //       'https://www.example.com/?email=${user.email}',
            //       dynamicLinkDomain: "example.page.link",
            //       androidInstallApp: true,
            //       androidMinimumVersion: '12',
            //       androidPackageName: "ca.alphatech.anychat",
            //       iOSBundleId: "ca.alphatech.anychat",
            //       handleCodeInApp: true);
            //
            //   await user.sendEmailVerification();
            // }
          }
        }),
      });
}

class AnyChat extends StatefulWidget {
  const AnyChat({Key? key}) : super(key: key);

  @override
  _AnyChatState createState() => _AnyChatState();
}

class _AnyChatState extends State<AnyChat> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Utilities.globalKey,
      routes: {
        '/addChatter': (context) => const AddChatterScreen(),
        '/call': (context) => const CallScreen(),
        '/chat': (context) => const ChatScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/conversations': (context) => const ConversationsScreen(),
        '/languages': (context) => const LanguagesScreen(),
        '/liveTranslator': (context) => const LiveTranslatorScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/searchChatterByEmail': (context) => const SearchChatterByEmailScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/forgotPassword': (context) => const ForgotPassword(),
      },
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.title,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('af', ''),
        Locale('sq', ''),
        Locale('am', ''),
        Locale('ar', ''),
        Locale('hy', ''),
        Locale('az', ''),
        Locale('eu', ''),
        Locale('be', ''),
        Locale('bn', ''),
        Locale('bs', ''),
        Locale('bg', ''),
        Locale('ca', ''),
        Locale('ceb', ''),
        Locale('zh', ''),
        Locale('co', ''),
        Locale('hr', ''),
        Locale('cs', ''),
        Locale('da', ''),
        Locale('nl', ''),
        Locale('en', ''),
        Locale('eo', ''),
        Locale('et', ''),
        Locale('fi', ''),
        Locale('fr', ''),
        Locale('fy', ''),
        Locale('gl', ''),
        Locale('ka', ''),
        Locale('de', ''),
        Locale('el', ''),
        Locale('gu', ''),
        Locale('ht', ''),
        Locale('ha', ''),
        Locale('haw', ''),
        Locale('iw', ''),
        Locale('hi', ''),
        Locale('hmn', ''),
        Locale('hu', ''),
        Locale('is', ''),
        Locale('ig', ''),
        Locale('id', ''),
        Locale('ga', ''),
        Locale('it', ''),
        Locale('ja', ''),
        Locale('jv', ''),
        Locale('kn', ''),
        Locale('kk', ''),
        Locale('km', ''),
        Locale('rw', ''),
        Locale('ko', ''),
        Locale('ku', ''),
        Locale('ky', ''),
        Locale('lo', ''),
        Locale('la', ''),
        Locale('lv', ''),
        Locale('lt', ''),
        Locale('lb', ''),
        Locale('mk', ''),
        Locale('mg', ''),
        Locale('ms', ''),
        Locale('ml', ''),
        Locale('mt', ''),
        Locale('mi', ''),
        Locale('mr', ''),
        Locale('mn', ''),
        Locale('my', ''),
        Locale('ne', ''),
        Locale('no', ''),
        Locale('ny', ''),
        Locale('or', ''),
        Locale('ps', ''),
        Locale('fa', ''),
        Locale('pl', ''),
        Locale('pt', ''),
        Locale('pa', ''),
        Locale('ro', ''),
        Locale('ru', ''),
        Locale('sm', ''),
        Locale('gd', ''),
        Locale('sr', ''),
        Locale('st', ''),
        Locale('sn', ''),
        Locale('sd', ''),
        Locale('si', ''),
        Locale('sk', ''),
        Locale('sl', ''),
        Locale('so', ''),
        Locale('es', ''),
        Locale('su', ''),
        Locale('sw', ''),
        Locale('sv', ''),
        Locale('tl', ''),
        Locale('tg', ''),
        Locale('ta', ''),
        Locale('tt', ''),
        Locale('te', ''),
        Locale('th', ''),
        Locale('tr', ''),
        Locale('tk', ''),
        Locale('uk', ''),
        Locale('ur', ''),
        Locale('ug', ''),
        Locale('uz', ''),
        Locale('vi', ''),
        Locale('cy', ''),
        Locale('xh', ''),
        Locale('yi', ''),
        Locale('yo', ''),
        Locale('zu', ''),
      ],
      theme: kDefaultTheme,
      darkTheme: kDarkTheme,
      themeMode: Utilities.getThemeMode(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData && (!snapshot.data!.isAnonymous)) {
            _checkNetworkConnection(context);
            AnyChatLocale.init(context);
            print(snapshot.data);
            FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.providerData[0].providerId == 'google.com'
                    ? snapshot.data!.uid
                    : snapshot.data!.providerData[0].uid)
                .get()
                .then((value) => AnyChatUser.fromSnapshot(value))
                .onError((error, stackTrace) => AnyChatUser.deletedUser())
                .then((AnyChatUser user) {
                  if(user.id == null) {
                    return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1), child: const WelcomeScreen());
                  }
              AnyChatAuth.currentUser = user;
              print('returning ConversationsScreen');
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1),
                    child: const ConversationsScreen());
              }));
            });
          }
          print('returning WelcomeScreen');
          return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1), child: const WelcomeScreen());
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

Future<void> _checkNetworkConnection(BuildContext context) async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('connected');
    }
  } on SocketException catch (_) {
    Utilities.showToast(AppLocalizations.of(context)!.notConnectedToInternet);
  }
}
