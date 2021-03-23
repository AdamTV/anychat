import 'dart:async';

import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/Screens/Conversations/conversations_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants.dart';
import 'anychat_user.dart';

class Utilities {
  static final String apiKey = "AIzaSyATyV6do7Ov4MkT55jyBKW_0gaZL8qE3Vw";
  static final String authority = "translation.googleapis.com";
  static final String unencodedPath = "/language/translate/v2";
  static Map<String, String> queryParameters = Map();

  static Future<String> getGoogleTranslation(
      String language, String text) async {
    queryParameters.putIfAbsent("key", () => apiKey);
    String isoCode = language;
    queryParameters.update("target", (value) => isoCode,
        ifAbsent: () => isoCode);
    queryParameters.update("q", (value) => text, ifAbsent: () => text);
    var uri = Uri.https(authority, unencodedPath, queryParameters);
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

  static String getDropDownValue(String language) {
    for (String key in isoMap.keys) {
      // print(isoMap[key]);
      // print(AnyChatAuth.currentUser.language);
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

  static getChatterDisplayNameString(List<AnyChatUser> chatters) {
    var ret = "";
    for (var chatter in chatters){
      ret += chatter.displayName;
      ret += ", ";
    }
    ret = ret.substring(0, ret.length - 2);
    return ret;
  }
}
