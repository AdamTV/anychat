import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:flutter/material.dart';

class NotifierService extends ChangeNotifier {
  ThemeData _themeData = kLightTheme; // Default theme
  Locale? _locale = const Locale('en'); // Default locale

  ThemeData get themeData => _themeData;
  Locale? get locale => _locale;

  void updateTheme(ThemeData newTheme) {
    _themeData = newTheme;
    logger.i('UpdateTheme is notifying listeners to change to a ${newTheme.brightness} theme.');
    notifyListeners(); // Notify all listeners of change
  }

  void updateLocale(Locale newLocale) {
    _locale = newLocale;
    logger.i('UpdateLocale is notifying listeners to change to a ${newLocale.languageCode} locale.');
    notifyListeners(); // Notify all listeners of change
  }
}
