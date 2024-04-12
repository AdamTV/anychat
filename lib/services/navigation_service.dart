import 'package:anychat/screens/blocked_users_screen.dart';
import 'package:anychat/screens/call_screen.dart';
import 'package:anychat/screens/chat_screen.dart';
import 'package:anychat/screens/conversations_screen.dart';
import 'package:anychat/screens/forgot_password.dart';
import 'package:anychat/screens/languages_screen.dart';
import 'package:anychat/screens/live_translator_screen.dart';
import 'package:anychat/screens/login_screen.dart';
import 'package:anychat/screens/register_screen.dart';
import 'package:anychat/screens/search_screen.dart';
import 'package:anychat/screens/settings_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

class NavigationService extends Navigator {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // get textDirection => navigatorKey.

  get routes => {
        // '/addChatter': (context) => const AddChatterScreen(),
        '/blockedUsers': (context) => const BlockedUsersScreen(),
        '/call': (context) => const CallScreen(),
        '/chat': (context) => const ChatScreen(),
        // '/contacts': (context) => const ContactsScreen(),
        '/conversations': (context) => const ConversationsScreen(),
        '/languages': (context) => const LanguagesScreen(),
        '/liveTranslator': (context) => const LiveTranslatorScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/searchChatter': (context) => const SearchChatterScreen(false, false),
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

  Future<dynamic> push(Route<dynamic> newRoute) {
    return navigatorKey.currentState!.push(newRoute);
  }

  Future<dynamic> pushNamed(String routeName) {
    return navigatorKey.currentState!.pushNamed(
        routeName);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {bool Function(Route<dynamic>)? predicate}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
        routeName, predicate ?? (Route<dynamic> route) => false);
  }

  Future<Object?> pushReplacementNamed(String s) {
    return navigatorKey.currentState!.pushReplacementNamed(s);
  }

  Future<dynamic> pushReplacement(Route<dynamic> newRoute, {dynamic result}) {
    return navigatorKey.currentState!.pushReplacement(newRoute, result: result);
  }
  Future<dynamic> pushAndRemoveUntil(Route<dynamic> newRoute, bool Function(Route<dynamic>) predicate){
    return navigatorKey.currentState!.pushAndRemoveUntil(newRoute, predicate);
  }
  void pop() {
    return navigatorKey.currentState!.pop();
  }
  void popUntil(bool Function(Route<dynamic>) predicate){
    return navigatorKey.currentState!.popUntil(predicate);
  }
}
