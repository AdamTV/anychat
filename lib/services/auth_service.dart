import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  static Future<Widget> initState(User? user) async {
    if (user == null) {
      return const WelcomeScreen();
    }
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!snapshot.exists) {
      return const WelcomeScreen();
    }
    AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(snapshot);
    return const ConversationsScreen();
  }

  static Future<void> listenToAuthChanges() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid)
          .get();
      if (snapshot.exists) {
        // On new login assume database has most up to date info
        AnyChatAuth.currentUser = AnyChatUser.fromSnapshot(snapshot);
        await RemoteNotificationObserver().initChatSubscriptions();
        // await RemoteNotificationObserver().initConversationSubscriptions();
        var user = await CacheManager()
            .getUserDataWithCache(AnyChatAuth.currentUser.id);
        user.id = AnyChatAuth.currentUser.id;
        user.username = AnyChatAuth.currentUser.displayName;
        user.email = AnyChatAuth.currentUser.email;
        user.notificationsEnabled =
            AnyChatAuth.currentUser.notificationsEnabled;
        user.theme = UserData.themeFromString(AnyChatAuth.currentUser.theme);
        user.locale =
            UserData.localeFromString(AnyChatAuth.currentUser.language);
        await CacheManager().cacheUserData(user);
        // }

        await NavigationService().pushNamedAndRemoveUntil('/conversations',
            predicate: (p0) => p0.isFirst);
        await NavigationService().pushReplacementNamed('/conversations');
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
