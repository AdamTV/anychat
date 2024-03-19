
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static Widget initState(user) {
    dynamic value;
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((value) => {
              AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(value),
            });

    if (value.exists) {
      return ConversationsScreen();
    } else {
      return const WelcomeScreen();
    }
  }
  static void listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) return;
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(snapshot);
        NavigationService().pushNamedAndRemoveUntil('/conversations',
            predicate: (p0) => p0.isFirst);
      } else {
        NavigationService()
            .pushNamedAndRemoveUntil('/welcome', predicate: (p0) => p0.isFirst);
      }
      //     .get()
      //     .then((value) => AnyChatUser.fromSnapshot(value))
      // .then((AnyChatUser user) {
      //   AnyChatAuth.currentUser = user;
      //   logger.d('returning ConversationsScreen');
      // }).onError((error, stacktrace) {
      //   logger.e("Welcome Screen Error:", error, stacktrace);
      //   AnyChatAuth.currentUser = null;
      // });
    });
  }
}
