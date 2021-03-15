import 'package:anychat/Screens/Login/login_screen.dart';
import 'package:anychat/Screens/Signup/components/background.dart';
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

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String email;
    String password;
    Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "SIGNUP",
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
            // RoundedInputField(
            //   icon: Icons.language,
            //   hintText: "Language: ${locale.humanReadable} detected",
            //   onChanged: (value) {
            //     language = value;
            //   },
            // ),
            RoundedButton(
              text: "SIGN-UP",
              press: () {
                AnyChatAuth.signInEmail(email, password, true)
                    .then((value) => {
                          if (value != null)
                            {Utilities.initConversationScreen(context, value)}
                        })
                    .catchError((e) => {
                          Utilities.showAlertDialog(
                              context, "Error", e.message.toString())
                        });
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
                  press: () {
                    AnyChatAuth.signInFacebook()
                        .then((value) => {
                              if (value != null)
                                {
                                  Utilities.initConversationScreen(
                                      context, value)
                                }
                            })
                        .catchError((e) => {
                              Utilities.showAlertDialog(
                                  context, "Error", e.message.toString())
                            });
                  },
                ),
                SocalIcon(
                  iconSrc: "assets/icons/twitter.svg",
                  press: () {
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => TwitterLoginScreen(
                    //             consumerKey: "DsqHohkyPJCjhdDByCLwZZYGH",
                    //             consumerSecret: "NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii",
                    //             oauthCallbackHandler:
                    //                 "https://twitterkit-DsqHohkyPJCjhdDByCLwZZYGH")));
                    AnyChatAuth.signInTwitter()
                        .then((value) => {
                              if (value != null)
                                {
                                  Utilities.initConversationScreen(
                                      context, value)
                                }
                            })
                        .catchError((e) => {
                              Utilities.showAlertDialog(
                                  context, "Error", e.message.toString())
                            });
                  },
                ),
                SocalIcon(
                    iconSrc: "assets/icons/google-plus.svg",
                    press: () {
                      AnyChatAuth.signInGoogle()
                          .then((value) => {
                                if (value != null)
                                  {
                                    Utilities.initConversationScreen(
                                        context, value)
                                  }
                              })
                          .catchError((e) => {
                                Utilities.showAlertDialog(
                                    context, "Error", e.message.toString())
                              });
                    })
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<String> test() async {
    await Locale.init();
    return Locale.humanReadable;
  }
}
