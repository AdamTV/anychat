import 'package:anychat/screens/call_screen.dart';
import 'package:anychat/screens/chat_screen.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/forgot_password.dart';
import 'package:anychat/screens/languages_screen.dart';
import 'package:anychat/screens/live_translator_screen.dart';
import 'package:anychat/screens/login_screen.dart';
import 'package:anychat/screens/register_screen.dart';
import 'package:anychat/screens/search_chatter_by_email_screen.dart';
import 'package:anychat/screens/settings_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // get textDirection => navigatorKey.

  get routes => {
        // '/addChatter': (context) => const AddChatterScreen(),
        '/call': (context) => const CallScreen(),
        '/chat': (context) => const ChatScreen(),
        // '/contacts': (context) => const ContactsScreen(),
        '/conversations': (context) => ConversationsScreen(),
        '/languages': (context) => const LanguagesScreen(),
        '/liveTranslator': (context) => const LiveTranslatorScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/searchChatter': (context) =>
            const SearchChatterScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/forgotPassword': (context) => const ForgotPassword(),
      };

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  void goBack() {
    return navigatorKey.currentState!.pop();
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {bool Function(Route<dynamic>)? predicate}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
        routeName, predicate ?? (Route<dynamic> route) => false);
  }

  Future<Object?> pushNamedReplacement(String s) {
    return navigatorKey.currentState!.pushReplacementNamed(s);
  }

}
