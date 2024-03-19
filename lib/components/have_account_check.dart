import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              ? "${AppLocalizations.of(context)!.doNotHaveAccount} "
              : "${AppLocalizations.of(context)!.haveAccount} ",
          style: Theme.of(context).textTheme.bodyLarge
        ),
          TextButton(
    onPressed: press,
    child: Text(
            login
                ? AppLocalizations.of(context)!.register
                : AppLocalizations.of(context)!.login,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
            )),
      ],
    );
  }
}
