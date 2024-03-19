import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  final SharedPreferences prefs;

  CacheManager(this.prefs);

  Future<void> cacheUserData(UserData data) async {
    String serializedData = jsonEncode(data.toJson());
    await prefs.setString('user_data', serializedData);
  }

  UserData? getCachedUserData() {
    String? serializedData = prefs.getString('user_data');
    return serializedData != null ? UserData.fromJson(jsonDecode(serializedData)) : null;
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
    throw Error();
    // Database fetch logic here
    return UserData();
  }
}

class UserData {

  Object? toJson() {
    return toJson();
  }
  static fromJson(jsonDecode) {
    return fromJson(jsonDecode);
  }
}