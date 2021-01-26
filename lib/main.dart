import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/constants.dart';
import 'package:anychat/components/locale.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
  locale.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AnyChat',
      theme: defaultTargetPlatform == TargetPlatform.iOS // NEW
      ? kIOSTheme // NEW
      : kDefaultTheme,
      home: WelcomeScreen(),
    );
  }
}
