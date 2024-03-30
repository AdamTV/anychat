import 'dart:async';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:html/parser.dart';
import 'anychat_user.dart';
import 'combined_locale_info.dart';

class Utilities {
  final String apiKey = "AIzaSyATyV6do7Ov4MkT55jyBKW_0gaZL8qE3Vw";
  final String authority = "translation.googleapis.com";
  final String unencodedPath = "/language/translate/v2";
  Map<String, dynamic> queryParameters = {};
  GlobalKey<NavigatorState> globalKey = NavigationService().navigatorKey;

  Utilities._privateConstructor();
  static final Utilities _instance = Utilities._privateConstructor();

  // Factory constructor to return the same instance
  factory Utilities() {
    return _instance;
  }

  Future<String> getGoogleTranslation(String? language, String? text) async {
    queryParameters.putIfAbsent("key", () => apiKey);
    String? isoCode = language;
    queryParameters.update("target", (value) => isoCode,
        ifAbsent: () => isoCode);
    queryParameters.update("q", (value) => text, ifAbsent: () => text);
    var uri = Uri.https(authority, unencodedPath, queryParameters);
    logger.d(uri);
    http.Response x = await http.post(uri);
    String body = x.body;
    logger.d(body);
    RegExp translatedTextRegex = RegExp("translatedText(?:.*?\"){2}([^\"]+)");
    Iterable<Match> matches = translatedTextRegex.allMatches(body);
    if (matches.length == 1 && matches.first.groupCount == 1) {
      return parseFragment(matches.first.group(1)!).text!;
    } else {
      throw Exception("Could not getGoogleTranslation -> uri: $uri");
    }
  }

  static const cloudApiMaxQ = 128;
  Future<Map<String?, List<String>>> getBatchGoogleTranslation(
      Map<String?, List<String?>> map) async {
    Map<String?, List<String>> translatedMap = {};
    queryParameters.putIfAbsent("key", () => apiKey);
    RegExp translatedTextRegex = RegExp("translatedText(?:.*?\"){2}([^\"]+)");
    for (var mapEntry in map.entries) {
      var key = mapEntry.key;
      translatedMap.putIfAbsent(key, () => []);
      queryParameters.update("target", (value) => key, ifAbsent: () => key);
      var value = mapEntry.value;
      for (int i = 0; i < value.length; i += cloudApiMaxQ) {
        int end = i + cloudApiMaxQ;
        if (cloudApiMaxQ > value.length) {
          end = value.length;
        } else if (end > value.length) {
          end = value.length;
        }
        var sublist = value.sublist(i, end);
        queryParameters.update("q", (v) => sublist, ifAbsent: () => sublist);
        var uri = Uri.https(authority, unencodedPath, queryParameters);
        http.Response x = await http.post(uri);
        Iterable<Match> matches = translatedTextRegex.allMatches(x.body);
        if (matches.isNotEmpty) {
          for (var match in matches) {
            translatedMap[key]!.add(parseFragment(match.group(1)!).text!);
          }
        } else {
          throw Exception("Could not getGoogleTranslation -> uri: $uri");
        }
      }
    }
    return translatedMap;
  }

  Future<void> showAlertDialog(
      BuildContext? context, String title, String text) async {
    return showDialog<void>(
      context: context ?? globalKey.currentContext!,
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
              child: Text(localizationOf(context).approve),
              onPressed: () {
                NavigationService().goBack();
              },
            ),
          ],
        );
      },
    );
  }

  void initConversationScreen(AnyChatUser value) {
    // Check if user has conversations
    FirebaseFirestore.instance
        .collection("users")
        .doc(value.id)
        .get()
        .then((value) => AnyChatUser.fromSnapshot(value))
        .then((AnyChatUser user) => {
              NavigationService().pushNamedAndRemoveUntil("/conversations",
                  predicate: (Route<dynamic> route) => route.isFirst)
            })
        .catchError((e) => {
              NavigationService().pushNamedAndRemoveUntil("/conversations",
                  predicate: (Route<dynamic> route) => route.isFirst)
            });
  }

  Future<bool> handlePermission(Permission permission) async {
    final status = await permission.request();
    logger.d(status);
    return status.isGranted;
  }

  String getChatterDisplayNameString(List<AnyChatUser> users) {
    var ret = "";
    var ids = <String?>[];
    for (var user in users) {
      if (user.id != AnyChatAuth.currentUser.id && !ids.contains(user.id)) {
        ids.add(user.id);
        ret += user.displayName;
        ret += ", ";
      }
    }
    try {
      ret = ret.substring(0, ret.length - 2);
    } on Error catch (e) {
      logger.e("Error", e, e.stackTrace);

      // logger.e(_.toString(), time: DateTime.now(), error: _, stackTrace: e);
    }
    return ret;
  }

  void showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        fontSize: 16.0);
  }

  void setThemeFromDropdownValue(String? newValue) async {
    var user = await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    var newPref = user.theme.brightness;
    if (newValue ==
        localizationOf(Utilities().globalKey.currentContext!)!.light) {
      newPref = Brightness.light;
    } else if (newValue ==
        localizationOf(Utilities().globalKey.currentContext!)!.dark) {
      newPref = Brightness.dark;
    }
    user.theme = user.theme.copyWith(brightness: newPref);
    CacheManager().cacheUserData(user);
  }

  Text biDirectionalText(
    BuildContext context,
    String data, {
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    return Text(data,
        key: key,
        style: style ??
            const TextStyle(
              decoration: TextDecoration.none,
            ),
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection ?? Directionality.of(context),
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor);
  }
}
