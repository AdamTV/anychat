import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Screens/welcome_screen.dart';
import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/locale.dart';
import 'package:anychat/components/notifications.dart';
import 'package:anychat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'Screens/conversations_screen.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<Widget> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifications().init();
  await Firebase.initializeApp();
  await Ads.init();
  FirebaseAuth.instance.authStateChanges().listen((User user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
  Locale.init();
  var app = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AnyChat',
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      darkTheme: kDarkTheme,
      home: await getWelcomeScreen());
  runApp(app);
  return app;
}

Future<Widget> getWelcomeScreen() async {
  return StreamBuilder<User>(
    stream: _auth.authStateChanges(),
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
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ConversationsScreen()));
        });
      }
      print('returning WelcomeScreen');
      return WelcomeScreen();
    },
  );
}
