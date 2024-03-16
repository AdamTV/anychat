import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/notifications.dart';
// import 'package:anychat/screens/contacts_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/auth_service.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';

import 'components/utilities.dart';
import 'firebase_options.dart';

var logger = Logger(
    printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: true // Should each log print contain a timestamp
        ),
    level: Level.debug);

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    Notifications().init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance
        .activate(
          // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
          // argument for `webProvider`
          webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
          // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
          // your preferred provider. Choose from:
          // 1. Debug provider
          // 2. Safety Net provider
          // 3. Play Integrity provider
          androidProvider: AndroidProvider.debug,
          // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
          // your preferred provider. Choose from:
          // 1. Debug provider
          // 2. Device Check provider
          // 3. App Attest provider
          // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
          appleProvider: AppleProvider.appAttest,
        )
        .then((value) => {
              Ads.init(),
              Utilities.init().then((value) => {runApp(const AnyChat())}),
              AuthService.listenToAuthChanges()
            });
  } on Error catch (e) {
    logger.e("Error", e, e.stackTrace);
  }
}

class AnyChat extends StatefulWidget {
  const AnyChat({super.key});

  @override
  State<AnyChat> createState() => _AnyChatState();
}

class _AnyChatState extends State<AnyChat> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey:
            NavigationService().navigatorKey, // Use the navigatorKey here
        routes: NavigationService().routes,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context)!.title,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AnyChatLocale.supportedLocales,
        theme: kDefaultTheme,
        darkTheme: kDarkTheme,
        themeMode: Utilities.getThemeMode(),
        home: const WelcomeScreen());
  }

  @override
  void dispose() {
    super.dispose();
  }
}
