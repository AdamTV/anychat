import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final ThemeData kDefaultTheme = ThemeData(
    primaryColor: Colors.deepPurple,
    focusColor: Colors.black12,
    primaryColorDark: Colors.deepPurple[900],
    primaryColorLight: Colors.white,
    brightness: Brightness.light,
    textTheme: Typography.blackMountainView, colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.purple).copyWith(secondary: Colors.deepPurple[900]).copyWith(background: const Color(0x0000008b)));

final ThemeData kDarkTheme = ThemeData(
    primaryColor: Colors.deepPurple,
    focusColor: Colors.black12,
    primaryColorDark: Colors.deepPurple[900],
    primaryColorLight: Colors.white,
    brightness: debugBrightnessOverride,
    textTheme: Typography.whiteMountainView, colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.purple).copyWith(secondary: Colors.deepPurple[900]).copyWith(background: const Color(0x0000008b)));

final Color? kDefaultChatBubbleColorLeft = Colors.grey[200];
final Color? kDefaultChatBubbleColorRight = Colors.blue[200];
final Color? kDarkChatBubbleColorLeft = Colors.grey[800];
final Color? kDarkChatBubbleColorRight = Colors.deepPurple[800];

const agoraAppId = '72559be0b8944a8fb70a772d196078ce';
