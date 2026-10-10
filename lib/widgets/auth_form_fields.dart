import 'package:flutter/material.dart';

import 'package:anychat/components/combined_locale_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// The shared email and password input fields used by the login and register
/// forms, validated live through the caller-supplied validators.
class AuthFormFields extends StatelessWidget {
  const AuthFormFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.validateEmail,
    required this.validatePassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Use the minimum space
      mainAxisAlignment:
          MainAxisAlignment.center, // Center the content vertically
      children: <Widget>[
        TextFormField(
          controller: emailController, // Attach the email controller here
          autovalidateMode:
              AutovalidateMode.onUserInteraction, // Enable live validation
          validator: (value) => validateEmail(value), // Validate the email
          decoration: InputDecoration(
            labelText: localizationOf(context).email,
            hintText: localizationOf(context).enterYourEmail,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: passwordController, // Attach the password controller here
          autovalidateMode:
              AutovalidateMode.onUserInteraction, // Enable live validation
          validator: (value) =>
              validatePassword(value), // Validate the password
          decoration: InputDecoration(
            labelText: localizationOf(context).password,
            hintText: localizationOf(context).enterYourPassword,
          ),
          obscureText: true, // Hide the input
        ),
      ],
    );
  }
}

/// Email validation shared by the login and register screens.
String? validateEmailInput(String? value, AppLocalizations localization) {
  final regex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (value == null || value.isEmpty) {
    return localization.emailMustNotBeEmpty;
  } else if (!regex.hasMatch(value)) {
    return localization.entterValidEmail;
  }
  return null;
}
