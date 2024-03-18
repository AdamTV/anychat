import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/login_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              AppLocalizations.of(context)!.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              AppLocalizations.of(context)!.enterYourEmail,
              style: const TextStyle(fontSize: 32),
            ),
            RoundedInputField(
              icon: Icons.mail,
              hintText: AppLocalizations.of(context)!.email,
              onChanged: (value) {
                _email = value;
              },
            ),
            // SvgPicture.asset(
            //   "assets/icons/chat.svg",
            //   height: size.height * 0.45,
            // ),
            ElevatedButton(
              child:
                  Text("${AppLocalizations.of(context)!.send} ${AppLocalizations.of(context)!.email}"),
              onPressed: () async {
                await _passwordReset();
                logger.d(_email);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const LoginScreen();
                    }),
                  );
                }
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.login),
              onPressed: () {
                Navigator.pushNamed(context, "/login");
              },
            ),
          ],
        ),
      ),
    ));
  }

  _passwordReset() async {
    try {
      final auth = FirebaseAuth.instance;
      _formKey.currentState!.save();
      await auth.sendPasswordResetEmail(email: _email!);
      if (mounted) {
        Utilities()
            .showToast(AppLocalizations.of(context)!.emailSentToResetPassword);
      }
    } catch (e) {
      if ((e is FirebaseException) && e.message != null) {
        Utilities().showToast(e.message!);
      } else if (mounted) {
        Utilities().showToast(AppLocalizations.of(context)!.error);
      }
      logger.d(e);
    }
  }
}
