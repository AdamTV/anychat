import 'dart:convert';

import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/notifier_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CacheManager {
  late final SharedPreferences prefs;
  late final notifierService = Provider.of<NotifierService>(
      Utilities().globalKey.currentContext!,
      listen: false);

  CacheManager._privateConstructor();
  static final CacheManager _instance = CacheManager._privateConstructor();

  // Factory constructor to return the same instance
  factory CacheManager() {
    return _instance;
  }

  initSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> cacheUserData(UserData data) async {
    try {
      String serializedData = jsonEncode(data.toJson());
      await prefs.setString('user_data', serializedData);
      notifierService.updateLocale(data.locale);
      notifierService.updateTheme(data.theme);
    } catch (e) {
      logger.e('Error caching user data: $e');
    }
  }

  UserData? getCachedUserData() {
    String? serializedData = prefs.getString('user_data');
    return serializedData != null
        ? UserData.fromJson(jsonDecode(serializedData))
        : null;
  }

  Future<UserData> getUserDataWithCache(String userId) async {
    // Try to get data from cache first
    UserData? cachedData = getCachedUserData();
    if (cachedData != null) {
      return cachedData;
    }

    // If cache miss, fetch from database and update cache
    UserData dataFromDb = await fetchUserDataFromDatabase(userId);
    await cacheUserData(dataFromDb);
    return dataFromDb;
  }

  // Placeholder for fetching data from a database
  Future<UserData> fetchUserDataFromDatabase(String userId) async {
    AnyChatUser user = await AnyChatUser.getUserById(userId);
    return UserData(
        id: user.id,
        username: user.displayName,
        email: user.email,
        theme: UserData.themeFromString(user.theme),
        locale: UserData.localeFromString(user.language),
        notificationsEnabled: user.notificationsEnabled);
  }
}

class UserData {
  String id;
  String username;
  String email;
  ThemeData theme;
  Locale locale;
  bool notificationsEnabled;

  static ThemeData themeFromString(String themeStr) {
    return themeStr == 'dark' ? ThemeData.dark() : ThemeData.light();
  }

  static Locale localeFromString(String localeStr) {
    var parts = localeStr.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }

  ThemeMode getThemeMode() {
    switch (theme.brightness) {
      case Brightness.light:
        return ThemeMode.light;
      case Brightness.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  UserData(
      {required this.id,
      required this.username,
      required this.email,
      required this.theme,
      required this.locale,
      required this.notificationsEnabled});

  // Method to serialize UserData for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'theme': UserData.themeToString(theme),
      'locale': locale.toString(),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Constructs a UserData object from a Map object
  factory UserData.fromJson(Map<String, dynamic> json) {
    String id = json['id'];
    String username = json['username'];
    String email = json['email'];
    ThemeData theme = UserData.themeFromString(json['theme']);
    Locale locale = UserData.localeFromString(json['locale']);
    bool notificationsEnabled = json['notificationsEnabled'];
    return UserData(
      id: id,
      username: username,
      email: email,
      theme: theme,
      locale: locale,
      notificationsEnabled: notificationsEnabled,
    );
  }

  static themeToString(ThemeData? theme) {
    return theme?.brightness == Brightness.dark
        ? AppLocalizations.of(Utilities().globalKey.currentContext!)?.dark
        : AppLocalizations.of(Utilities().globalKey.currentContext!)?.light;
  }
}
