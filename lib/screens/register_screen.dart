import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/have_account_check.dart';
import 'package:anychat/components/or_divider.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifications/notifications_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/combined_locale_info.dart';

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
            //   localizationOf(context).register_caps,
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
                          labelText: localizationOf(context).email,
                          hintText: 'Enter your email',
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
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                        ),
                        obscureText: true, // Hide the input
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() &&
                              isUserAgreeToTerms()) {
                            // If the form is valid, display a Snackbar.
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Loading')));
                            try {
                              var user = await AnyChatAuth.signInEmail(
                                  _emailController.text,
                                  _passwordController.text,
                                  true);
                              if (user != null) {
                                Utilities().showToast(localizationOf(mounted
                                        ? context
                                        : Utilities().globalKey.currentContext!)
                                    .accountCreatedEnterSettings);
                                await AnyChatUser.updateNotifications(
                                    await NotificationUtils
                                        .requestBasicPermissionToSendNotifications(
                                            context));
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
                                  localizationOf(mounted
                                          ? context
                                          : Utilities()
                                              .globalKey
                                              .currentContext!)
                                      .error,
                                  localizationOf(mounted
                                          ? context
                                          : Utilities()
                                              .globalKey
                                              .currentContext!)
                                      .unableRegister);
                            }
                          }
                        },
                        child: Text(localizationOf(context).register),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              // width: size.width * 0.50,
              child: CheckboxListTile(
                title: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: localizationOf(context).byContinuingIAgree,
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextSpan(
                      text: localizationOf(context).privacyPolicy,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri(
                              scheme: 'https',
                              host: 'anychat.ca',
                              path: 'privacy-policy'));
                        },
                    ),
                    TextSpan(
                        text: " ${localizationOf(context).and} ",
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextSpan(
                        text: localizationOf(context).eula,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.blue),
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
            SizedBox(height: size.height * 0.03),
            HaveAccountCheck(
              login: false,
              press: () {
                NavigationService().pushNamed("/login");
              },
            ),
            const OrDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                AnyChatAuth.flutterSocialButton(context, ButtonType.google),
                AnyChatAuth.flutterSocialButton(context, ButtonType.apple),
                // AnyChatAuth.flutterSocialButton(context, ButtonType.facebook),
                // AnyChatAuth.twitterIcon(context),
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
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    } else if (!regex.hasMatch(value)) {
      return 'Password must contain a:\n'
          'Upper case letter\n'
          'Lower case letter\n'
          'Number\n'
          'Special character (~!@#\$%^&*()_)';
    } else {
      Map<String, int> charCounts = {};
      for (int i = 0; i < value.length; i++) {
        charCounts[value[i]] = (charCounts[value[i]] ?? 0) + 1;
        if (charCounts[value[i]]! > 2) {
          return "Characters must not \n"
              "repeat more than twice."; // Found a character that repeats more than twice
        }
      }
    }

    return null;
  }

  static bool isUserAgreeToTerms() {
    if (!userAgreedToTerms) {
      showDialog<void>(
          context: Utilities().globalKey.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(localizationOf(context).error),
                content: Text(
                    localizationOf(context).toJoinAnyChatConfirmPrivacyPolicy),
                actions: <Widget>[
                  TextButton(
                    child: Text(localizationOf(context).cancel),
                    onPressed: () {
                      NavigationService().goBack();
                      Utilities().showToast(localizationOf(context).cancelled);
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
