import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/call_screen.dart';
import 'package:disposables/disposables.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:rxdart/rxdart.dart';

import 'conversation.dart';
import 'conversation_info.dart';

final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

class Notifications implements Disposable {
  FlutterRingtonePlayer flutterRingtonePlayer = FlutterRingtonePlayer();

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  init() async {
    try {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    } catch (e) {
      logger.d('ERROR - must be on the web');
      return;
    }
    _requestPermissions();
    _configureSelectNotificationSubject();

// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logo_icon');
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    // final MacOSInitializationSettings initializationSettingsMacOS =
    //     MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            // macOS: initializationSettingsMacOS
        );
    await flutterLocalNotificationsPlugin!.initialize(initializationSettings,
        onDidReceiveNotificationResponse : selectNotification);
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String? payload) async {
      logger.d(payload);
      var conversationId = payload!.substring(5);
      var convo = await Conversation.getConversationById(conversationId);
      AnyChatAuth.currentConversation = convo;
      if (payload.toLowerCase().contains('ring')) {
        CallScreen.requestPermissionAndNavigate();
      } else if (payload.toLowerCase().contains('chat')) {
        var info = await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser!.id);
        AnyChatAuth.currentUser!.conversations
            .add(info.firstWhere((element) => element.id == conversationId));
        await Utilities.globalKey.currentState!.pushNamed('/chat');
      }
    });
  }

  void selectNotification(NotificationResponse payload) async {
    logger.d('selectNotification');
    flutterRingtonePlayer.stop();
    selectNotificationSubject.add(payload.payload);

    // if (payload != null) {
    //   debugPrint('notification payload: $payload');
    // }
    // await Navigator.pushNamed(
    //   context,
    //   MaterialPageRoute<void>(builder: (context) => ChatScreen(payload)),
    // );
  }

  Future<void> showNotification(
      String? title, String body, String payload) async {
    if (Utilities.prefs.getBool('notifications') != null &&
        !Utilities.prefs.getBool('notifications')!) {
      return;
    }
    logger.d('showNotification');
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        payload.contains('ring')
            ? AndroidNotificationDetails(
                AppLocalizations.of(Utilities.globalKey.currentContext!)!.title,
                'your channel name',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                styleInformation: const BigTextStyleInformation(''),
                playSound: false)
            : AndroidNotificationDetails(
                AppLocalizations.of(Utilities.globalKey.currentContext!)!.title,
                'your channel name',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                styleInformation: const BigTextStyleInformation(''),
              );
    var iosPlatformSpecs = payload.contains('ring')
        ? const DarwinNotificationDetails(presentSound: false)
        : const DarwinNotificationDetails(presentSound: true);
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosPlatformSpecs);
    if (flutterLocalNotificationsPlugin == null) {
      await init();
    }
    if (payload.contains("ring")) {
      () async {
        flutterRingtonePlayer.playRingtone();
        await Future.delayed(
            const Duration(seconds: 15), () => flutterRingtonePlayer.stop());
      }.call();
    }
    await flutterLocalNotificationsPlugin!
        .show(0, title, body, platformChannelSpecifics, payload: payload);
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    logger.d('received notification');
    return Future.value();
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
  }
  
  @override
  bool get isDisposed => selectNotificationSubject.isClosed;
}
