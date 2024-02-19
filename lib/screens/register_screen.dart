import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/have_account_check.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/rounded_password_field.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();

  static bool isUserAgreeToTerms() {
    return _RegisterScreenState.isUserAgreeToTerms();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _email;
  String? _password;
  static bool userAgreedToTerms = false;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: SignupBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.register_caps,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.03),
            SvgPicture.asset(
              "assets/icons/signup.svg",
              height:
                  size.height < 750 ? size.height * 0.25 : size.height * 0.35,
            ),
            RoundedInputField(
              hintText: AppLocalizations.of(context)!.email,
              onChanged: (value) {
                _email = value;
              },
            ),
            RoundedPasswordField(
              onChanged: (value) {
                _password = value;
              },
            ),
            CheckboxListTile(
              title: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: AppLocalizations.of(context)!.byContinuingIAgree,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)!.privacyPolicy,
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launch(
                            'https://www.alphatechnology.ca/anychat-privacy-policy');
                      },
                  ),
                  TextSpan(
                    text: " ${AppLocalizations.of(context)!.and} ",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)!.eula,
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launch('https://www.alphatechnology.ca/anychat-eula');
                      },
                  ),
                ]),
              ),
              value: userAgreedToTerms,
              onChanged: (newValue) {
                setState(() {
                  userAgreedToTerms = newValue!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            RoundedButton(
              text: AppLocalizations.of(context)!.register_caps,
              press: () async {
                if (!isUserAgreeToTerms()) return;
                try {
                  var user =
                      await AnyChatAuth.signInEmail(_email, _password, true);
                  if (user != null) {
                    Utilities.showToast(AppLocalizations.of(context)!
                        .accountCreatedEnterSettings);
                    Navigator.pushNamed(context, '/settings');
                  } else {
                    throw Error();
                  }
                } catch (e) {
                  Utilities.showAlertDialog(
                      context,
                      AppLocalizations.of(context)!.error,
                      AppLocalizations.of(context)!.unableRegister);
                }
              },
            ),
            SizedBox(height: size.height * 0.03),
            HaveAccountCheck(
              login: false,
              press: () {
                Navigator.pushNamed(context, "/login");
              },
            ),
            const OrDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // AnyChatAuth.googleIcon(context),
                AnyChatAuth.appleIcon(context),
                // AnyChatAuth.facebookIcon(context),
                // AnyChatAuth.twitterIcon(context),
              ],
            )
          ],
        ),
      ),
    ));
  }

  static bool isUserAgreeToTerms() {
    if (!userAgreedToTerms) {
      showDialog<void>(
          context: Utilities.globalKey.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(AppLocalizations.of(context)!.error),
                content: Text(AppLocalizations.of(context)!
                    .toJoinAnyChatConfirmPrivacyPolicy),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Utilities.showToast(
                          AppLocalizations.of(context)!.cancelled);
                    },
                  )
                ]);
          });
      return false;
    } else {
      return true;
    }
  }
}

class SignupBackground extends StatelessWidget {
  final Widget child;

  const SignupBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var children = <Widget>[];
    children.addAll({
      Positioned(
        top: size.width >= 750 ? (kIsWeb ? -200 : size.width * -0.05) : 0,
        left: size.width >= 750 ? (kIsWeb ? -200 : size.width * -0.05) : 0,
        child: Image.asset(
          "assets/images/signup_top.png",
          width: size.width * 0.35,
        ),
      ),
      Positioned(
        bottom: size.width >= 750 ? (kIsWeb ? -250 : size.width * -0.1) : 0,
        left: size.width >= 750 ? (kIsWeb ? -175 : size.width * -0.05) : 0,
        child: Image.asset(
          "assets/images/main_bottom.png",
          width: size.width * 0.25,
        ),
      )
    });
    children.add(child);
    return SizedBox(
      height: size.height,
      width: double.infinity,
      // Here i can use size.width but use double.infinity because both work as a same
      child: Stack(
        alignment: Alignment.center,
        children: children,
      ),
    );
  }
}
