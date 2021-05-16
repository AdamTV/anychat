import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String _email;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).enterYourEmail,
                style: TextStyle(fontSize: 32),
              ),
              RoundedInputField(
                icon: Icons.mail,
                hintText: AppLocalizations.of(context).email,
                onChanged: (value) {
                  _email = value;
                },
              ),
              SizedBox(height: 20),
              RoundedButton(
                text: AppLocalizations.of(context).send +
                    " " +
                    AppLocalizations.of(context).email,
                press: () async {
                  await _passwordReset();
                  print(_email);
                  Fluttertoast.showToast(
                      msg: AppLocalizations.of(context)
                          .emailSentToResetPassword);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen();
                    }),
                  );
                },
              ),
              RoundedButton(
                text: AppLocalizations.of(context).login,
                press: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  _passwordReset() async {
    try {
      final _auth = FirebaseAuth.instance;
      _formKey.currentState.save();
      await _auth.sendPasswordResetEmail(email: _email);
    } catch (e) {
      if (e.message != null) {
        Fluttertoast.showToast(msg: e.message, toastLength: Toast.LENGTH_LONG);
      }
      print(e);
    }
  }
}
