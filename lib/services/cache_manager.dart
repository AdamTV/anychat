import 'dart:convert';

import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/notifier_service.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:google_speech/generated/google/protobuf/any.pb.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CacheManager {
  late final SharedPreferences prefs;
  late final notifierService = Provider.of<DeivceNotifierService>(
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
      notifierService.updateTheme(data.theme);
      notifierService.updateLocale(data.locale);
      await prefs.setString('user_data', serializedData);
    } catch (e) {
      logger.e('Error caching user data: $e');
    }
  }

  UserData? _getCachedUserData() {
    String? serializedData = prefs.getString('user_data');
    return serializedData != null && serializedData.isNotEmpty
        ? UserData.fromJson(jsonDecode(serializedData))
        : null;
  }

  Future<UserData> getUserDataWithCache(String userId) async {
    // Try to get data from cache first
    UserData? cachedData = _getCachedUserData();
    if (cachedData != null) {
      return cachedData;
    }

    // If cache miss, fetch from database and update cache
    UserData dataFromDb = await _fetchUserDataFromDatabase(userId);
    await cacheUserData(dataFromDb);
    return dataFromDb;
  }

  Future<UserData> _fetchUserDataFromDatabase(String userId) async {
    AnyChatUser user = await AnyChatUser.getUserById(userId);
    return UserData(
        id: user.id,
        username: user.displayName,
        email: user.email,
        theme: UserData.themeFromString(user.theme),
        locale: UserData.localeFromString(user.language),
        notificationsEnabled: user.notificationsEnabled);
  }

  Future<ThemeData> loadThemeFromCache() async {
    try {
      if (AnyChatAuth.isUserInitialized()) {
        UserData userData =
            await getUserDataWithCache(AnyChatAuth.currentUser.id);
        return userData.theme;
      } else {
        UserData? userData = _getCachedUserData();
        return userData!.theme;
      }
    } catch (e) {
      logger.e("Unable to load theme from cache: ", e.toString());
      return kLightTheme;
    }
  }

  Future<Locale?> loadLocaleFromCache() async {
    try {
      if (AnyChatAuth.isUserInitialized()) {
        UserData userData =
            await getUserDataWithCache(AnyChatAuth.currentUser.id);
        return userData.locale;
      } else {
        UserData? userData = _getCachedUserData();
        return userData?.locale ?? await Devicelocale.currentAsLocale;
      }
    } catch (e) {
      logger.e("Unable to load theme from cache: ", e);
      return UserData.localeFromString('en');
    }
  }

  clearUserData() async {
    await prefs.setString("user_data", "");
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
    if (Utilities().globalKey.currentContext != null) {
      return themeStr == 'dark' ? ThemeData.dark() : ThemeData.light();
    } else {
      return ThemeData.light();
    }
  }

  static String themeToString(ThemeData? theme) {
    return theme?.brightness == Brightness.dark ? 'dark' : 'light';
  }

  static Locale localeFromString(String localeStr) {
    var parts = localeStr.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }

  static String localeToString(Locale locale) {
    return locale.languageCode.toString();
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
  Map<String, String> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'theme': UserData.themeToString(theme),
      'locale': locale.toString(),
      'notificationsEnabled': notificationsEnabled.toString(),
    };
  }

  // Constructs a UserData object from a Map object
  factory UserData.fromJson(Map<String, dynamic> json) {
    String id = json['id'];
    String username = json['username'];
    String email = json['email'];
    ThemeData theme = UserData.themeFromString(json['theme']);
    Locale locale = UserData.localeFromString(json['locale']);
    bool notificationsEnabled = json['notificationsEnabled'] == 'true';
    return UserData(
      id: id,
      username: username,
      email: email,
      theme: theme,
      locale: locale,
      notificationsEnabled: notificationsEnabled,
    );
  }
}
