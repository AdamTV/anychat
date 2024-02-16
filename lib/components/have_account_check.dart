import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HaveAccountCheck extends StatelessWidget {
  final bool login;
  final Function? press;

  const HaveAccountCheck({
    Key? key,
    this.login = true,
    this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          login
              ? "${AppLocalizations.of(context)!.doNotHaveAccount} "
              : "${AppLocalizations.of(context)!.haveAccount} ",
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        GestureDetector(
          onTap: press as void Function()?,
          child: Text(
            login
                ? AppLocalizations.of(context)!.register
                : AppLocalizations.of(context)!.login,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
