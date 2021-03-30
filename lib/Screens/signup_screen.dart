import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Screens/login_screen.dart';
import 'package:anychat/components/already_have_an_account_acheck.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/locale.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/rounded_password_field.dart';
import 'package:anychat/components/social_icon.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SignUpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String email;
    String password;
    Size size = MediaQuery.of(context).size;
    return SignupBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "SIGN-UP",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.03),
            kIsWeb
                ? Image.network("assets/icons/signup.svg",
                height: size.height * 0.35)
                : SvgPicture.asset(
              "assets/icons/signup.svg",
              height: size.height * 0.35,
            ),
            RoundedInputField(
              hintText: "Your Email",
              onChanged: (value) {
                email = value;
              },
            ),
            RoundedPasswordField(
              onChanged: (value) {
                password = value;
              },
            ),
            RoundedButton(
              text: "SIGN-UP",
              press: () async {
                try {
                  var user = await AnyChatAuth.signInEmail(email, password, true);
                  if (user != null) {
                    Utilities.initConversationScreen(context, user);
                  }
                } catch (e) {
                  Utilities.showAlertDialog(context, "Error",
                      "Unable to register to AnyChat. Please try again.");
                }
              },
            ),
            SizedBox(height: size.height * 0.03),
            AlreadyHaveAnAccountCheck(
              login: false,
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginScreen();
                    },
                  ),
                );
              },
            ),
            OrDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SocalIcon(
                  iconSrc: "assets/icons/facebook.svg",
                  press: () async {
                    try {
                      var user = await AnyChatAuth.signInFacebook();
                      if (user != null) {
                        Utilities.initConversationScreen(context, user);
                      }
                    } catch (e) {
                      Utilities.showAlertDialog(context, "Error",
                          "Unable to register though Facebook. Please try again.");
                    }
                  },
                ),
                SocalIcon(
                  iconSrc: "assets/icons/twitter.svg",
                  press: () async {
                    try {
                      var user = await AnyChatAuth.signInTwitter();
                      if (user != null) {
                        Utilities.initConversationScreen(context, user);
                      }
                    } catch (e) {
                      Utilities.showAlertDialog(context, "Error",
                          "Unable to register though Twitter. Please try again.");
                    }
                  },
                ),
                SocalIcon(
                    iconSrc: "assets/icons/google-plus.svg",
                    press: () async {
                      try {
                        var user = await AnyChatAuth.signInGoogle();
                        if (user != null) {
                          Utilities.initConversationScreen(context, user);
                        }
                      } catch (e) {
                        Utilities.showAlertDialog(context, "Error",
                            "Unable to register though Google. Please try again.");
                      }
                    })
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SignupBackground extends StatelessWidget {
  final Widget child;

  const SignupBackground({
    Key key,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      width: double.infinity,
      // Here i can use size.width but use double.infinity because both work as a same
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              "assets/images/signup_top.png",
              width: size.width * 0.35,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              "assets/images/main_bottom.png",
              width: size.width * 0.25,
            ),
          ),
          child,
        ],
      ),
    );
  }
}