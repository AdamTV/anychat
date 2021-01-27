import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class Utilities{
  static final String apiKey = "AIzaSyATyV6do7Ov4MkT55jyBKW_0gaZL8qE3Vw";
  static final String authority = "translation.googleapis.com";
  static final String unencodedPath = "/language/translate/v2";
  static Map<String, String> queryParameters = Map();

  static Future<String> getGoogleTranslation(String text) async {
    queryParameters.putIfAbsent("key", () => apiKey);
    queryParameters.update("target", (value) => "es", ifAbsent: () => "es");
    queryParameters.update("q", (value) => text, ifAbsent: () => text);
    var uri = Uri.https(authority, unencodedPath, queryParameters);
    Response x = await http.post(uri);
    String body = x.body;
    RegExp translatedTextRegex = RegExp("translatedText(?:.*?\"){2}([^\"]+)");
    Iterable<Match> matches = translatedTextRegex.allMatches(body);
    if(matches.length == 1 && matches.first.groupCount == 1) {
      return matches.first.group(1);
    }
  }
  static Future<void> showMyDialog(BuildContext context, String text) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
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
}