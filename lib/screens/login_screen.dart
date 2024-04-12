import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/have_account_check.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';

import '../components/combined_locale_info.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: LoginBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Text(
            //   localizationOf(context).login_caps,
            //   style: const TextStyle(fontWeight: FontWeight.bold),
            // ),
            // SizedBox(height: size.height * 0.03),
            Center(
              // Center the content vertically and horizontally
              child: Container(
                padding: const EdgeInsets.all(16.0),
                width: 300, // Specify the width of the Container
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Use the minimum space
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center the content vertically
                    children: <Widget>[
                      TextFormField(
                        controller:
                            _emailController, // Attach the email controller here
                        autovalidateMode: AutovalidateMode
                            .onUserInteraction, // Enable live validation
                        validator: (value) =>
                            _validateEmail(value), // Validate the email
                        decoration: InputDecoration(
                          labelText: localizationOf(context).email,
                          hintText: localizationOf(context).enterYourEmail,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller:
                            _passwordController, // Attach the password controller here
                        autovalidateMode: AutovalidateMode
                            .onUserInteraction, // Enable live validation
                        validator: (value) =>
                            _validatePassword(value), // Validate the password
                        decoration: InputDecoration(
                          labelText: localizationOf(context).password,
                          hintText: localizationOf(context).enterYourPassword,
                        ),
                        obscureText: true, // Hide the input
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // If the form is valid, display a Snackbar.
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(localizationOf(context).login)));
                            try {
                              var user = await AnyChatAuth.signInEmail(
                                  _emailController.text,
                                  _passwordController.text,
                                  false);
                              if (user != null) {
                                Utilities().initConversationScreen(user);
                              } else {
                                Utilities().showAlertDialog(
                                    mounted
                                        ? context
                                        : Utilities().globalKey.currentContext!,
                                    localizationOf(Utilities()
                                                .globalKey
                                                .currentContext!)
                                        .error,
                                    localizationOf(mounted
                                            ? context
                                            : Utilities()
                                                .globalKey
                                                .currentContext!)
                                        .invalidCredentials);
                              }
                            } on Error catch (e) {
                              // logger.e("Error", time: DateTime.now(), error: e, stackTrace: e.stackTrace);
                              logger.e("Error", e, e.stackTrace);
                              if (context.mounted) {
                                Utilities().showAlertDialog(
                                    context,
                                    localizationOf(context).error,
                                    localizationOf(context)
                                        .errorLoggingIn);
                              }
                            }
                          }
                        },
                        child: Text(localizationOf(context).login),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                NavigationService().pushNamed(
                  '/forgotPassword',
                );
              },
              child: Text(
                localizationOf(context).forgotPassword,
                style:  Theme.of(context).textTheme.bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            HaveAccountCheck(
              press: () {
                NavigationService().pushReplacementNamed("/register");
              },
            ),
            const OrDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                AnyChatAuth.flutterSocialButton(context, ButtonType.google),
                AnyChatAuth.flutterSocialButton(context, ButtonType.apple),
                // AnyChatAuth.flutterSocialButton(context, ButtonType.facebook),
              ],
            )
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is removed from the widget tree
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (value == null || value.isEmpty) {
      return localizationOf(context).emailMustNotBeEmpty;
    } else if (!regex.hasMatch(value)) {
      return localizationOf(context).entterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null) {
      return localizationOf(context).passwordMustNotBeEmpty;
    }
    return null;
  }
}

class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({
    super.key,
    required this.child,
  });

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
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: children,
      ),
    );
  }
}
