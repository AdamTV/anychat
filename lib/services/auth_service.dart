import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_speech/generated/google/protobuf/any.pb.dart';

import 'notifications/notifications_util.dart';

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

  static Future<void> listenToAuthChanges() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) return;
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        // On new login assume database has most up to date info
        AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(snapshot);

        var user = await CacheManager()
            .getUserDataWithCache(AnyChatAuth.currentUser.id);
          user.id = AnyChatAuth.currentUser.id;
          user.username = AnyChatAuth.currentUser.displayName;
          user.email = AnyChatAuth.currentUser.email;
          user.notificationsEnabled = AnyChatAuth.currentUser.notificationsEnabled;
          user.theme = UserData.themeFromString(AnyChatAuth.currentUser.theme);
          user.locale =
              UserData.localeFromString(AnyChatAuth.currentUser.language);
          await CacheManager().cacheUserData(user);
        // }

        await NavigationService().pushNamedAndRemoveUntil('/conversations',
            predicate: (p0) => p0.isFirst);
      } else {
        await NavigationService()
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
