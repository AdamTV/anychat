import 'package:flutter/material.dart';

class ThemeOption {
  final String name;
  final ThemeMode themeMode;

  ThemeOption(this.name, this.themeMode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          themeMode == other.themeMode;

  @override
  int get hashCode => name.hashCode ^ themeMode.hashCode;
}
