import 'package:flutter/material.dart';

final ThemeData kDefaultTheme = ThemeData(
    useMaterial3: true,
    // primaryColor: Colors.deepPurple,
    // focusColor: Colors.black12,
    // primaryColorDark: Colors.deepPurple[900],
    // primaryColorLight: Colors.white,
    // brightness: Brightness.light,
    // textTheme: Typography.blackHelsinki,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple.shade300, brightness: Brightness.light
        // background: const Color.fromARGB(50, 0, 0, 139),
        ));

final ThemeData kDarkTheme = ThemeData(
    useMaterial3: true,
    // primaryColor: Colors.deepPurple,
    // focusColor: Colors.black12,
    // primaryColorDark: Colors.deepPurple[900],
    // primaryColorLight: Colors.white,
    // brightness: Brightness.dark,
    // textTheme: Typography.whiteHelsinki,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple.shade600, brightness: Brightness.dark
        // background: const Color.fromARGB(50, 0, 0, 139),
        ));

final Color? kDefaultChatBubbleColorLeft = Colors.grey[200];
final Color? kDefaultChatBubbleColorRight = Colors.blue[200];
final Color? kDarkChatBubbleColorLeft = Colors.grey[800];
const Color kDarkChatBubbleColorRight = Color.fromARGB(214, 69, 39, 160);

double? fontSize = 24;

const agoraAppId = '72559be0b8944a8fb70a772d196078ce';
