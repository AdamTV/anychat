import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/combined_locale_info.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String? _email;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: WelcomeBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              localizationOf(context).title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              localizationOf(context).enterYourEmail,
              style: const TextStyle(fontSize: 32),
            ),
            TextField(
              // icon: Icons.mail,
              decoration: InputDecoration.collapsed(
                  hintText: localizationOf(context).email),
              onChanged: (value) {
                _email = value;
              },
            ),
            // SvgPicture.asset(
            //   "assets/icons/chat.svg",
            //   height: size.height * 0.45,
            // ),
            ElevatedButton(
              child: Text(
                  "${localizationOf(context).send} ${localizationOf(context).email}"),
              onPressed: () async {
                await _passwordReset();
                logger.d(_email);
                NavigationService().pushNamed('/login');
              },
            ),
            ElevatedButton(
              child: Text(localizationOf(context).login),
              onPressed: () {
                NavigationService().pushNamed("/login");
              },
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _passwordReset() async {
    try {
      final auth = FirebaseAuth.instance;
      _formKey.currentState!.save();
      await auth.sendPasswordResetEmail(email: _email!);
      if (mounted) {
        Utilities().showToast(localizationOf(context).emailSentToResetPassword);
      }
    } catch (e) {
      if ((e is FirebaseException) && e.message != null) {
        Utilities().showToast(e.message!);
      } else if (mounted) {
        Utilities().showToast(localizationOf(context).error);
      }
      logger.d(e);
    }
  }
}
