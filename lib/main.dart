import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'package:devicelocale/devicelocale.dart';

import 'package:anychat/components/constants.dart';
import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/services/auth_service.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifications/notifications_controller.dart';
import 'package:anychat/services/notifier_service.dart';
import 'components/combined_locale_info.dart';

var logger = Logger(
    printer: PrettyPrinter(
        methodCount: 5, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        dateTimeFormat: DateTimeFormat
            .onlyTimeAndSinceStart // Should each log print contain a timestamp
        ),
    level: Level.info);

String chatMessages() => Intl.message(
      'Chat Messages',
      name: 'chatMessages',
    );
String videoCalls() => Intl.message(
      'Video Calls',
      name: 'videoCalls',
    );
String localeName = 'en';
ThemeData? cachedTheme;

void main() async {
  try {
    // Widget binding Initialization
    WidgetsFlutterBinding.ensureInitialized();
    RemoteNotificationObserver().init();

    // Local cache Initialization
    await CacheManager().initSharedPrefs();
    cachedTheme = await CacheManager().loadThemeFromCache();
    Locale locale = await CacheManager().loadLocaleFromCache() ??
        await Devicelocale.currentAsLocale ??
        const Locale('en');
    localeName = locale.languageCode;
    final deviceNotifierService = DeivceNotifierService();
    deviceNotifierService.update(cachedTheme, locale);

    // FlutterFire Initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      webProvider:
          ReCaptchaV3Provider('6Lfg5JopAAAAAAT0qwf8TLduBu-W_gvJJQ9T-cZO'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    AuthService.listenToAuthChanges();

    try {
      // Notifications Initialization
      await NotificationsController.initializeLocalNotifications();
      // await NotificationsController.initializeRemoteNotifications();
      await NotificationsController.initializeIsolateReceivePort();
      await NotificationsController.getInitialNotificationAction();
    } catch (e) {
      logger.e('awesome error:', error: e);
    }

    // Ads.init(),
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DeivceNotifierService()),
          ChangeNotifierProvider(
              create: (context) => RemoteNotificationObserver()),
          ChangeNotifierProvider(
              create: (context) => NotificationsController()),
        ],
        child: const AnyChat(),
      ),
    );
  } on Exception catch (e, s) {
    logger.e("Error in main 1", error: e, stackTrace: s);
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
    NotificationsController.initializeNotificationsEventListeners();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<DeivceNotifierService>(context);
    final notificationsProvider = Provider.of<NotificationsController>(context);

    String initialRoute =
        notificationsProvider.initialAction == null ? '/welcome' : '/call';
    logger.i("Entering _AnyChatState.build at initialRoute: $initialRoute");

    return MaterialApp(
      navigatorKey: NavigationService().navigatorKey,
      routes: NavigationService().routes,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => localizationOf(context).title,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: initialRoute,
      supportedLocales: getSupportedLocales(),
      locale: notifier.locale,
      theme: kLightTheme,
      darkTheme: kDarkTheme,
      themeMode: notifier.themeData?.brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
    );
  }
}
