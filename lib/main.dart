import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/notifications.dart';
// import 'package:anychat/screens/contacts_screen.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/auth_service.dart';
import 'package:anychat/services/cache_maanger.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifier_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

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
    level: Level.info);

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final notifierService = NotifierService();
    await CacheManager().initSharedPrefs();
    ThemeData cachedTheme = await CacheManager().loadThemeFromCache();
    Locale locale = await CacheManager().loadLocaleFromCache();
    notifierService.updateLocale(locale);
    notifierService.updateTheme(cachedTheme);
    Notifications().init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
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
          .then((value) async => {
                Ads.init(),
                await AuthService.listenToAuthChanges(),
                runApp(ChangeNotifierProvider<NotifierService>(
                  create: (context) => NotifierService(),
                  child: const AnyChat(),
                )),
              })
          .catchError(
              (onError) => {logger.e("Error in main 3", onError, onError)});
    } on Exception catch (e, s) {
      logger.e("Error in main 2", e, s);
    }
  } on Error catch (e) {
    logger.e("Error in main 1", e, e.stackTrace);
  }
}

class AnyChat extends StatelessWidget {
  const AnyChat({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i("Entering _AnyChatState.build");

    final notifierService = Provider.of<NotifierService>(context);

    return Consumer<NotifierService>(builder: (context, settings, child) {
      return MaterialApp(
          navigatorKey: NavigationService().navigatorKey,
          // Use the navigatorKey here
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
          localeResolutionCallback: (locale, supportedLocales) {
            // Check if the current device locale is supported
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode ||
                  supportedLocale.countryCode == locale?.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          locale: notifierService.locale,
          theme: kLightTheme,
          darkTheme: kDarkTheme,
          themeMode: notifierService.themeData.brightness == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark,
          home: const WelcomeScreen());
    });
  }
}

// class _AnyChatState extends State<AnyChat> {

// }
