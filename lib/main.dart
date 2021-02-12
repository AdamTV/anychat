import 'package:anychat/Screens/Conversations/conversations_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/locale.dart';
import 'package:anychat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/components/ads.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseAdMob.instance.initialize(appId: "ca-app-pub-4494853791237895~4335658619");
  Ads();
  Ads.myBanner.load();
  FirebaseAuth.instance.authStateChanges().listen((User user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
  locale.init();
  // test();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AnyChat',
    theme: defaultTargetPlatform == TargetPlatform.iOS // NEW
        ? kIOSTheme // NEW
        : kDefaultTheme,
    home: await getWelcomeScreen(),
  ));
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
          // if (AnyChatAuth.currentUser.conversationIds?.isNotEmpty ?? false) {
          //   ConversationsScreen.conversations =
          //       user.conversationIds.cast<String>();
          // } else {
          //   ConversationsScreen.conversations = <String>[];
          // }
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

// Widget initConversationScreen() {
//   FirebaseFirestore.instance
//       .collection("users")
//       .doc(value.id)
//       .get()
//       .then((value) => AnyChatUser.fromSnapshot(value))
//       .then((AnyChatUser user) => {
//             if (user.conversations?.isNotEmpty)
//               {
//                 ConversationsScreen.conversations =
//                     user.conversations.cast<String>(),
//               }
//             else
//               {ConversationsScreen.conversations = new List<String>()},
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => ConversationsScreen()))
//           })
//       .catchError((e) => {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) {
//                   return ConversationsScreen();
//                 },
//               ),
//             )
//           });
// }

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'AnyChat',
//       theme: defaultTargetPlatform == TargetPlatform.iOS // NEW
//       ? kIOSTheme // NEW
//       : kDefaultTheme,
//       // home: await getWelcomeScreen(),
//       home: WelcomeScreen(),
//     );
//   }
// }
