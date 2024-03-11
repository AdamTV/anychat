import 'package:flutter/material.dart';

final ThemeData kDefaultTheme = ThemeData(
    useMaterial3: false,
    primaryColor: Colors.deepPurple,
    focusColor: Colors.black12,
    primaryColorDark: Colors.deepPurple[900],
    primaryColorLight: Colors.white,
    brightness: Brightness.light,
    textTheme: Typography.blackHelsinki,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple).copyWith(
        secondary: Colors.deepPurple[900],
        background: Color.fromARGB(50, 0, 0, 139),
        brightness: Brightness.light));

final ThemeData kDarkTheme = ThemeData(
    useMaterial3: false,
    primaryColor: Colors.deepPurple,
    focusColor: Colors.black12,
    primaryColorDark: Colors.deepPurple[900],
    primaryColorLight: Colors.white,
    brightness: Brightness.dark,
    textTheme: Typography.whiteHelsinki,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple).copyWith(
        secondary: Colors.deepPurple[900],
        background: Color.fromARGB(50, 0, 0, 139),
        brightness: Brightness.dark));

final Color? kDefaultChatBubbleColorLeft = Colors.grey[200];
final Color? kDefaultChatBubbleColorRight = Colors.blue[200];
final Color? kDarkChatBubbleColorLeft = Colors.grey[800];
final Color? kDarkChatBubbleColorRight = const Color.fromARGB(214, 69, 39, 160);

double? fontSize = 24;

const agoraAppId = '72559be0b8944a8fb70a772d196078ce';
