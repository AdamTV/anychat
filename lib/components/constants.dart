import 'package:flutter/material.dart';

final ThemeData kDefaultTheme = ThemeData(
    backgroundColor: Color(0x00008B),
    primaryColor: Colors.deepPurple,
    primarySwatch: Colors.purple,
    accentColor: Colors.deepPurple[900],
    focusColor: Colors.black12,
    primaryColorDark: Colors.deepPurple[900],
    primaryColorLight: Colors.white,
    brightness: Brightness.light,
    textTheme: Typography.blackMountainView);

final ThemeData kDarkTheme = ThemeData(
    backgroundColor: Color(0x00008B),
    primaryColor: Colors.deepPurple,
    primarySwatch: Colors.purple,
    accentColor: Colors.deepPurple[900],
    focusColor: Colors.black12,
    primaryColorDark: Colors.deepPurple[900],
    primaryColorLight: Colors.white,
    brightness: Brightness.dark,
    textTheme: Typography.whiteMountainView);

final Color? kDefaultChatBubbleColorLeft = Colors.grey[200];
final Color? kDefaultChatBubbleColorRight = Colors.blue[200];
final Color? kDarkChatBubbleColorLeft = Colors.grey[800];
final Color? kDarkChatBubbleColorRight = Colors.deepPurple[800];

final agoraAppId = '72559be0b8944a8fb70a772d196078ce';
