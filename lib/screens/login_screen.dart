import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/have_account_check.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/rounded_password_field.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _email;
  String? _password;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: LoginBackground(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.login_caps,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.03),
            SvgPicture.asset(
              "assets/icons/login.svg",
              height:
                  size.height < 750 ? size.height * 0.25 : size.height * 0.35,
              alignment: Alignment.topLeft,
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
            RoundedButton(
              text: AppLocalizations.of(context)!.login_caps,
              press: () async {
                try {
                  var user =
                      await AnyChatAuth.signInEmail(_email, _password, false);
                  if (user != null)
                    Utilities.initConversationScreen(context, user);
                  else
                    Utilities.showAlertDialog(
                        context,
                        AppLocalizations.of(context)!.error,
                        AppLocalizations.of(context)!.invalidCredentials);
                } catch (e) {
                  Utilities.showAlertDialog(
                      context,
                      AppLocalizations.of(context)!.error,
                      AppLocalizations.of(context)!.errorLoggingIn);
                }

                // AnyChatAuth.signInEmail(_email, _password, false)
                //     .then((value) =>
                // {
                //   if (value != null)
                //     Utilities.initConversationScreen(context, value)
                //   else
                //     Utilities.showAlertDialog(
                //         context,
                //         AppLocalizations
                //             .of(context)
                //             .error,
                //         AppLocalizations
                //             .of(context)
                //             .invalidCredentials),
                // })
                //     .catchError((e) =>
                // {
                //   Utilities.showAlertDialog(
                //       context,
                //       AppLocalizations
                //           .of(context)
                //           .error,
                //       AppLocalizations
                //           .of(context)
                //           .errorLoggingIn)
                // });
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/forgotPassword',
                );
              },
              child: Text(
                AppLocalizations.of(context)!.forgotPassword,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            HaveAccountCheck(
              press: () {
                Navigator.pushNamed(context, "/register");
              },
            ),
            OrDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnyChatAuth.googleIcon(context),
                AnyChatAuth.appleIcon(context),
                AnyChatAuth.facebookIcon(context),
                AnyChatAuth.twitterIcon(context),
              ],
            )
          ],
        ),
      ),
    ));
  }
}

class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var children = <Widget>[];
    children.addAll({
      Positioned(
        top: size.width >= 750 ? (kIsWeb ? -250 : size.width * -0.06) : 0,
        left: size.width >= 750 ? (kIsWeb ? -225 : size.width * -0.05) : 0,
        child: Image.asset(
          "assets/images/main_top.png",
          width: size.width * 0.35,
        ),
      ),
      Positioned(
        bottom: size.width >= 750 ? (kIsWeb ? -100 : size.width * -0.05) : 0,
        right: size.width >= 750 ? (kIsWeb ? -150 : size.width * -0.05) : 0,
        child: Image.asset(
          "assets/images/login_bottom.png",
          width: size.width * 0.3,
        ),
      ),
    });
    children.add(child);
    return Container(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: children,
      ),
    );
  }
}
