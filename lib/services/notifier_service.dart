import 'package:anychat/main.dart';
import 'package:flutter/material.dart';

class DeivceNotifierService extends ChangeNotifier {
  ThemeData? _themeData;
  Locale? _locale;

  ThemeData? get themeData => _themeData;
  Locale? get locale => _locale;

  void update(ThemeData? theme, Locale? locale){
    logger.d('DeivceNotifierService is notifying listeners');
    if (theme != null) _themeData = theme;
    if (locale != null) _locale = locale;
    notifyListeners();
  }

  void updateTheme(ThemeData newTheme) {
    _themeData = newTheme;
    logger.d('UpdateTheme is notifying listeners to change to a ${newTheme.brightness} theme.');
    notifyListeners(); // Notify all listeners of change
  }

  void updateLocale(Locale newLocale) {
    _locale = newLocale;
    logger.d('UpdateLocale is notifying listeners to change to a ${newLocale.languageCode} locale.');
    notifyListeners(); // Notify all listeners of change
  }
}
