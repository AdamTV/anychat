import 'package:anychat/Screens/Conversations/conversations_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/Screens/Login/components/background.dart';
import 'package:anychat/components/social_icon.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/Screens/Signup/signup_screen.dart';
import 'package:anychat/components/already_have_an_account_acheck.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/rounded_password_field.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Body extends StatelessWidget {
  const Body({
    Key key,
  }) : super(key: key);

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
              "LOGIN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.03),
            kIsWeb
                ? Image.network("assets/icons/login.svg",
                    height: size.height * 0.35)
                : SvgPicture.asset(
                    "assets/icons/login.svg",
                    height: size.height * 0.35,
                  ),
            SizedBox(height: size.height * 0.03),
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
                AnyChatAuth.signInEmail(email, password).then((value) => {
                      if (value != null)
                        {initConversationScreen(context, value)}
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
                SocalIcon(
                  iconSrc: "assets/icons/facebook.svg",
                  press: () {},
                ),
                SocalIcon(
                  iconSrc: "assets/icons/twitter.svg",
                  press: () {},
                ),
                SocalIcon(
                  iconSrc: "assets/icons/google-plus.svg",
                  press: () {
                    AnyChatAuth.signInWithGoogle().then((value) => {
                          if (value != null)
                            {initConversationScreen(context, value)}
                        });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  initConversationScreen(BuildContext context, AnyChatUser value) {
    String id = AnyChatAuth.currentUser.id;
    // Check if user has conversations
    FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id)
        .get()
        .then((value) => AnyChatUser.fromSnapshot(value))
        .then((AnyChatUser user) => {
              if (user.conversations.isNotEmpty)
                {
                  ConversationsScreen.conversations =
                      user.conversations.cast<String>(),
                }
              else
                {ConversationsScreen.conversations = new List<String>()},
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ConversationsScreen()))
            });
  }
}
