import 'dart:async';

import 'package:anychat/Screens/conversations_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'anychat_user.dart';
import 'constants.dart';

class Utilities {
  static SharedPreferences prefs;
  static final String apiKey = "AIzaSyATyV6do7Ov4MkT55jyBKW_0gaZL8qE3Vw";
  static final String authority = "translation.googleapis.com";
  static final String unencodedPath = "/language/translate/v2";
  static Map<String, String> queryParameters = Map();

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static Future<String> getGoogleTranslation(
      String language, String text) async {
    queryParameters.putIfAbsent("key", () => apiKey);
    String isoCode = language;
    queryParameters.update("target", (value) => isoCode,
        ifAbsent: () => isoCode);
    queryParameters.update("q", (value) => text, ifAbsent: () => text);
    var uri = Uri.https(authority, unencodedPath, queryParameters);
    print(uri);
    Response x = await http.post(uri);
    String body = x.body;
    print(body);
    RegExp translatedTextRegex = RegExp("translatedText(?:.*?\"){2}([^\"]+)");
    Iterable<Match> matches = translatedTextRegex.allMatches(body);
    if (matches.length == 1 && matches.first.groupCount == 1) {
      return matches.first.group(1).replaceAll("&#39;", "'");
    } else {
      throw new Exception("Could not getGoogleTranslation -> uri: $uri");
    }
  }

  static Future<void> showAlertDialog(
      BuildContext context, String title, String text) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static initConversationScreen(BuildContext context, AnyChatUser value) {
    // Check if user has conversations
    FirebaseFirestore.instance
        .collection("users")
        .doc(value.id)
        .get()
        .then((value) => AnyChatUser.fromSnapshot(value))
        .then((AnyChatUser user) => {
              // if (userconversationIds?.isEmpty)
              //   {
              //     user.conversationIds = <String>[]
              //   },
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ConversationsScreen()))
            })
        .catchError((e) => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ConversationsScreen();
                  },
                ),
              )
            });
  }

  static String getLanguageFromIsoCode(String language) {
    for (String key in isoMap.keys) {
      if (isoMap[key] == language) {
        return key;
      }
    }
    return "Error";
  }

  static Future<void> handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  static String getChatterDisplayNameString(List<AnyChatUser> users) {
    var ret = "";
    for (var user in users){
      if (user.id != AnyChatAuth.currentUser.id){
        ret += user.displayName;
        ret += ", ";
      }
    }
    try {
      ret = ret.substring(0, ret.length - 2);
    }catch(e){

    }
    return ret;
  }

  static ThemeMode getThemeMode() {
    switch (prefs.getString('theme')?.toLowerCase() ?? 'system'){
      case 'system' :
        return ThemeMode.system;
        break;
      case 'dark' :
        return ThemeMode.dark;
        break;
      case 'light' :
        return ThemeMode.light;
        break;
      default:
        return ThemeMode.system;
    }
  }

  static void showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        fontSize: 16.0);
  }
}
