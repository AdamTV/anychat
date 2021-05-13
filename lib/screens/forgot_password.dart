import 'package:anychat/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPassword extends StatelessWidget {

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
              TextFormField(
                onSaved: (newEmail) {
                  _email = newEmail;
                },
                onChanged: (value){_email = value;},
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).email,
                  icon: Icon(
                    Icons.mail,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text(AppLocalizations.of(context).send + " " + AppLocalizations.of(context).email),
                onPressed: () async {
                  await _passwordReset();
                  print(_email);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return LoginScreen();
                    }),
                  );
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context).login),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
  _passwordReset() async {
    try{
      final _auth = FirebaseAuth.instance;
      _formKey.currentState.save();
      await _auth.sendPasswordResetEmail(email: _email);
    }catch (e){
      if (e.message != null) {
        Fluttertoast.showToast(msg: e.message, toastLength: Toast.LENGTH_LONG);
      }
      print(e);
    }
  }
}