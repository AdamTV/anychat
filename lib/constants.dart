import 'package:flutter/material.dart';

const kPrimaryColor = Colors.purple;
const kPrimaryLightColor = Color(0xFFF1E6FF);

final ThemeData kIOSTheme = ThemeData(
  primarySwatch: Colors.red,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);