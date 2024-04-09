import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/combined_locale_info.dart';

class HaveAccountCheck extends StatelessWidget {
  final bool login;
  final Function()? press;

  const HaveAccountCheck({
    super.key,
    this.login = true,
    this.press,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          login
              ? "${localizationOf(context).doNotHaveAccount} "
              : "${localizationOf(context).haveAccount} ",
          style: Theme.of(context).textTheme.bodyLarge
        ),
          TextButton(
    onPressed: press,
    child: Text(
            login
                ? localizationOf(context).register
                : localizationOf(context).login,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
            )),
      ],
    );
  }
}
