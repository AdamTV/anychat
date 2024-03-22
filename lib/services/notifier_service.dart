import 'package:anychat/main.dart';
import 'package:anychat/services/cache_maanger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotifierService extends ChangeNotifier {
  ThemeData _themeData = CacheManager().getCachedUserData()!.theme; // Default theme
  Locale _locale = CacheManager().getCachedUserData()!.locale; // Default locale

  ThemeData get themeData => _themeData;
  Locale get locale => _locale;

  void updateTheme(ThemeData newTheme) {
    _themeData = newTheme;
    logger.d('UpdateTheme is notifying listeners');
    notifyListeners(); // Notify all listeners of change
  }

  void updateLocale(Locale newLocale) {
    _locale = newLocale;
    logger.d('UpdateLocale is notifying listeners');
    notifyListeners(); // Notify all listeners of change
  }
}
