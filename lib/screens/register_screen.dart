import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/have_account_check.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/components/rounded_password_field.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();

  static bool isUserAgreeToTerms() {
    return _RegisterScreenState.isUserAgreeToTerms();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
            // Text(
            //   AppLocalizations.of(context)!.register_caps,
            //   style: const TextStyle(fontWeight: FontWeight.bold),
            // ),
            // SizedBox(height: size.height * 0.03),
            // SvgPicture.asset(
            //   "assets/icons/signup.svg",
            //   height:
            //       size.height < 750 ? size.height * 0.25 : size.height * 0.35,
            // ),
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
                          labelText: AppLocalizations.of(context)!.email,
                          hintText: 'Enter your email',
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller:
                            _passwordController, // Attach the password controller here
                        autovalidateMode: AutovalidateMode
                            .onUserInteraction, // Enable live validation
                        validator: (value) =>
                            _validatePassword(value), // Validate the password
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                        ),
                        obscureText: true, // Hide the input
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() &&
                              isUserAgreeToTerms()) {
                            // If the form is valid, display a Snackbar.
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Loading')));
                            try {
                              var user = await AnyChatAuth.signInEmail(
                                  _emailController.text,
                                  _passwordController.text,
                                  true);
                              if (user != null) {
                                Utilities().showToast(AppLocalizations.of(
                                        mounted
                                            ? context
                                            : Utilities()
                                                .globalKey
                                                .currentContext!)!
                                    .accountCreatedEnterSettings);
                                Navigator.pushNamed(
                                    mounted
                                        ? context
                                        : Utilities().globalKey.currentContext!,
                                    '/settings');
                              } else {
                                throw Error();
                              }
                            } catch (e) {
                              Utilities().showAlertDialog(
                                  mounted
                                      ? context
                                      : Utilities().globalKey.currentContext!,
                                  AppLocalizations.of(mounted
                                          ? context
                                          : Utilities()
                                              .globalKey
                                              .currentContext!)!
                                      .error,
                                  AppLocalizations.of(mounted
                                          ? context
                                          : Utilities()
                                              .globalKey
                                              .currentContext!)!
                                      .unableRegister);
                            }
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.register),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: size.width * 0.50,
              child: CheckboxListTile(
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
                          launchUrl(Uri(
                              scheme: 'https',
                              host: 'anychat.ca',
                              path: 'privacy-policy'));
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
                            launchUrl(Uri(
                                scheme: 'https',
                                host: 'anychat.ca',
                                path: 'eula'));
                          }),
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
            ),
            // ElevatedButton(
            //   child: Text(AppLocalizations.of(context)!.register_caps),
            //   onPressed: () async {
            //     if (!isUserAgreeToTerms()) return;
            //     try {
            //       var user =
            //           await AnyChatAuth.signInEmail(_email, _password, true);
            //       if (user != null) {
            //         Utilities().showToast(AppLocalizations.of(mounted
            //                 ? context
            //                 : Utilities().globalKey.currentContext!)!
            //             .accountCreatedEnterSettings);
            //         Navigator.pushNamed(
            //             mounted
            //                 ? context
            //                 : Utilities().globalKey.currentContext!,
            //             '/settings');
            //       } else {
            //         throw Error();
            //       }
            //     } catch (e) {
            //       Utilities().showAlertDialog(
            //           mounted ? context : Utilities().globalKey.currentContext!,
            //           AppLocalizations.of(mounted
            //                   ? context
            //                   : Utilities().globalKey.currentContext!)!
            //               .error,
            //           AppLocalizations.of(mounted
            //                   ? context
            //                   : Utilities().globalKey.currentContext!)!
            //               .unableRegister);
            //     }
            //   },
            // ),
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
      return 'Email cannot be empty';
    } else if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static bool isUserAgreeToTerms() {
    if (!userAgreedToTerms) {
      showDialog<void>(
          context: Utilities().globalKey.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(AppLocalizations.of(context)!.error),
                content: Text(AppLocalizations.of(context)!
                    .toJoinAnyChatConfirmPrivacyPolicy),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () {
                      NavigationService().goBack();
                      Utilities()
                          .showToast(AppLocalizations.of(context)!.cancelled);
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
    super.key,
    required this.child,
  });

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
