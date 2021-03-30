import 'package:anychat/Screens/signup_screen.dart';
import 'package:anychat/components/already_have_an_account_acheck.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/rounded_password_field.dart';
import 'package:anychat/components/social_icon.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String email;
    String password;
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: LoginBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "LOGIN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.03),
            SvgPicture.asset(
              "assets/icons/login.svg",
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
              text: "LOGIN",
              press: () {
                AnyChatAuth.signInEmail(email, password, false)
                    .then((value) => {
                          if (value != null)
                            {Utilities.initConversationScreen(context, value)}
                          else
                            Utilities.showAlertDialog(
                                context, "Error", "Invalid Credentials")
                        })
                    .catchError((e) => {
                          Utilities.showAlertDialog(context, "Error",
                              "There was an error logging in.")
                        });
              },
            ),
            SizedBox(height: size.height * 0.03),
            AlreadyHaveAnAccountCheck(
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return SignUpScreen();
                    },
                  ),
                );
              },
            ),
            OrDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                facebookIcon(context),
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
                          "Unable to sign in though Twitter. Please try again.");
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
                            "Unable to sign in though Google. Please try again.");
                      }
                    })
              ],
            )
          ],
        ),
      ),
    ));
  }

  SocalIcon facebookIcon(BuildContext context) {
    return SocalIcon(
      key: Key("facebookIcon"),
      iconSrc: "assets/icons/facebook.svg",
      press: () async {
        try {
          var user = await AnyChatAuth.signInFacebook();
          if (user != null) {
            Utilities.initConversationScreen(context, user);
          }
        } catch (e) {
          Utilities.showAlertDialog(context, "Error",
              "Unable to sign in though Facebook. Please try again.");
        }
      },
    );
  }
}

class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({
    Key key,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              "assets/images/main_top.png",
              width: size.width * 0.35,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/login_bottom.png",
              width: size.width * 0.3,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
