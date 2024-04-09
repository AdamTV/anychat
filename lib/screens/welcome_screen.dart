import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/combined_locale_info.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1),
      child: PopScope(
          child: Scaffold(
              body: WelcomeBackground(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: size.height * 0.15,
                    child: Image.asset(
                        "assets/icons/anychat-text-only-${Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light'}Theme.png"),
                  ),
                  SizedBox(height: size.height * 0.05),
                  SizedBox(
                    height: size.height * 0.45,
                    child: Image.asset(
                      "assets/icons/globecomplexSphere.webp",
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),
                  TextButton(
                    child: Text(
                      textScaler: const TextScaler.linear(2.0),
                      localizationOf(context).login_caps,
                    ),
                    onPressed: () {
                      NavigationService().pushNamed("/login");
                    },
                  ),
                  TextButton(
                    child: Text(
                      textScaler: const TextScaler.linear(2.0),
                      localizationOf(context).register_caps,
                    ),
                    onPressed: () {
                      NavigationService().pushNamed("/register");
                    },
                  ),
                ],
              ),
            ),
          )),
          onPopInvoked: (didPop) async => false),
    );
  }
}

class WelcomeBackground extends StatelessWidget {
  final Widget child;

  const WelcomeBackground({
    super.key,
    required this.child,
  });

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
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: SizedBox(
        height: size.height,
        width: size.width,

        child: Stack(
          alignment: Alignment.center,
          children: children,
        ),
      ),
    );
  }
}
