import 'package:anychat/components/rounded_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // This size provide us total height and width of our screen
    return PopScope(
        child: Scaffold(
            body: WelcomeBackground(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: size.height * 0.05),
                SvgPicture.asset(
                  "assets/icons/chat.svg",
                  height: size.height * 0.45,
                ),
                SizedBox(height: size.height * 0.05),
                RoundedButton(
                  text: AppLocalizations.of(context)!.login_caps,
                  press: () {
                    Navigator.pushNamed(context, "/login");
                  },
                ),
                RoundedButton(
                  text: AppLocalizations.of(context)!.register_caps,
                  press: () {
                    Navigator.pushNamed(context, "/register");
                  },
                ),
              ],
            ),
          ),
        )),
        onPopInvoked: (didPop) async => false);
  }
}

class WelcomeBackground extends StatelessWidget {
  final Widget child;

  const WelcomeBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    Size size = MediaQuery.of(context).size;
    // if (!kIsWeb) {
    children.addAll({
      Positioned(
        top: size.width >= 750 ? (kIsWeb ? -200 : size.width * -0.05) : 0,
        left: size.width >= 750 ? (kIsWeb ? -175 : size.width * -0.05) : 0,
        child: Image.asset(
          "assets/images/main_top.png",
          width: size.width * 0.3,
        ),
      ),
      Positioned(
        bottom: size.width >= 750 ? (kIsWeb ? -175 : size.width * -0.05) : 0,
        left: size.width >= 750 ? (kIsWeb ? -175 : size.width * -0.05) : 0,
        child: Image.asset(
          "assets/images/main_bottom.png",
          width: size.width * 0.2,
        ),
      ),
    });
    // }
    children.add(child);
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Stack(
        alignment: Alignment.center,
        children: children,
      ),
    );
  }
}
