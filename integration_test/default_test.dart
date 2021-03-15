import 'package:anychat/Screens/Login/login_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/social_icon.dart';
import 'package:anychat/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("ensure no auth shows login screen", (WidgetTester tester) async {
    await tester.pumpWidget(await app.main());
    await FirebaseAuth.instance.signOut();
    expect(find.text("LOGIN"), findsOneWidget);
  });
  // testWidgets("ensure facebook auth", (WidgetTester tester) async {
  //   await tester.pumpWidget(await app.main());
  //   await FirebaseAuth.instance.signOut();
  //   // await tester.tap(find.text("LOGIN"));
  //   await tester.pumpAndSettle();
  //   await AnyChatAuth.signInFacebook();
  //   await tester.pumpAndSettle();
  //
  //   // final testKey = Key("facebookIcon");
  //   // await tester.pumpWidget(LoginScreen());
  //   // var icon = SocalIcon(
  //   //     key: Key("facebookIcon"),
  //   //     iconSrc: "assets/icons/facebook.svg");
  //   // await tester.tap(find.byKey(testKey));
  //
  //   expect(find.text("Log into your Facebook account to connect to AnyChat"), findsOneWidget);
  // });
}