import 'dart:isolate';
import 'dart:ui';

import 'package:anychat/components/combined_locale_info.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/services/notifications/utils/common_functions.dart'
    if (dart.library.html) 'package:awesome_notifications/utils/common_web_functions.dart';
import 'package:anychat/services/notifications/notifications_util.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsController extends ChangeNotifier {
  static final NotificationsController _instance =
      NotificationsController._internal();

  factory NotificationsController() {
    return _instance;
  }

  NotificationsController._internal();

  String _firebaseToken = '';
  String get firebaseToken => _firebaseToken;

  String _nativeToken = '';
  String get nativeToken => _nativeToken;

  ReceivedAction? initialAction;

  // ***************************************************************
  //    INITIALIZATIONS
  // ***************************************************************
  static Future<void> initializeLocalNotifications() async {
    await initializeIsolateReceivePort();
    await AwesomeNotifications().initialize(
        // 'resource://drawable/logo_icon',
        null,
        [
          NotificationChannel(
            channelGroupKey: 'chat',
            channelKey: 'chats',
            channelName: Intl.withLocale(localeName, () => chatMessages()),
            channelDescription: Intl.withLocale(localeName, () => chatMessages()),
            channelShowBadge: true,
            importance: NotificationImportance.Max,
            ledColor: Colors.white,
            defaultColor: const Color(0xFF9D50DD),
          ),
          NotificationChannel(
              channelGroupKey: 'call',
              channelKey: 'call_channel',
              channelName: Intl.withLocale(localeName, () => videoCalls()),
              channelDescription:Intl.withLocale(localeName, () => videoCalls()),
              defaultColor: const Color(0xFF9D50DD),
              importance: NotificationImportance.Max,
              ledColor: Colors.white,
              channelShowBadge: true,
              locked: true,
              defaultRingtoneType: DefaultRingtoneType.Ringtone),
          // NotificationChannel(
          //     channelGroupKey: 'basic_tests',
          //     channelKey: 'basic_channel',
          //     channelName: 'Basic notifications',
          //     channelDescription: 'Notification channel for basic tests',
          //     defaultColor: const Color(0xFF9D50DD),
          //     ledColor: Colors.white,
          //     importance: NotificationImportance.High),
          // NotificationChannel(
          //     channelGroupKey: 'basic_tests',
          //     channelKey: 'badge_channel',
          //     channelName: 'Badge indicator notifications',
          //     channelDescription:
          //         'Notification channel to activate badge indicator',
          //     channelShowBadge: true,
          //     defaultColor: const Color(0xFF9D50DD),
          //     ledColor: Colors.yellow),
          // NotificationChannel(
          //     channelGroupKey: 'category_tests',
          //     channelKey: 'call_channel',
          //     channelName: 'Calls Channel',
          //     channelDescription: 'Channel with call ringtone',
          //     defaultColor: const Color(0xFF9D50DD),
          //     importance: NotificationImportance.Max,
          //     ledColor: Colors.white,
          //     channelShowBadge: true,
          //     locked: true,
          //     defaultRingtoneType: DefaultRingtoneType.Ringtone),
          // NotificationChannel(
          //     channelGroupKey: 'category_tests',
          //     channelKey: 'alarm_channel',
          //     channelName: 'Alarms Channel',
          //     channelDescription: 'Channel with alarm ringtone',
          //     defaultColor: const Color(0xFF9D50DD),
          //     importance: NotificationImportance.Max,
          //     ledColor: Colors.white,
          //     channelShowBadge: true,
          //     locked: true,
          //     defaultRingtoneType: DefaultRingtoneType.Alarm),
          // NotificationChannel(
          //     channelGroupKey: 'channel_tests',
          //     channelKey: 'updated_channel',
          //     channelName: 'Channel to update',
          //     channelDescription: 'Notifications with not updated channel',
          //     defaultColor: const Color(0xFF9D50DD),
          //     ledColor: Colors.white),
          // NotificationChannel(
          //   channelGroupKey: 'chat_tests',
          //   channelKey: 'chats',
          //   channelName: 'Chat groups',
          //   channelDescription:
          //       'This is a simple example channel of a chat group',
          //   channelShowBadge: true,
          //   importance: NotificationImportance.Max,
          //   ledColor: Colors.white,
          //   defaultColor: const Color(0xFF9D50DD),
          // ),
          // NotificationChannel(
          //     channelGroupKey: 'vibration_tests',
          //     channelKey: 'low_intensity',
          //     channelName: 'Low intensity notifications',
          //     channelDescription:
          //         'Notification channel for notifications with low intensity',
          //     defaultColor: Colors.green,
          //     ledColor: Colors.green,
          //     vibrationPattern: lowVibrationPattern),
          // NotificationChannel(
          //     channelGroupKey: 'vibration_tests',
          //     channelKey: 'medium_intensity',
          //     channelName: 'Medium intensity notifications',
          //     channelDescription:
          //         'Notification channel for notifications with medium intensity',
          //     defaultColor: Colors.yellow,
          //     ledColor: Colors.yellow,
          //     vibrationPattern: mediumVibrationPattern),
          // NotificationChannel(
          //     channelGroupKey: 'vibration_tests',
          //     channelKey: 'high_intensity',
          //     channelName: 'High intensity notifications',
          //     channelDescription:
          //         'Notification channel for notifications with high intensity',
          //     defaultColor: Colors.red,
          //     ledColor: Colors.red,
          //     vibrationPattern: highVibrationPattern),
          // NotificationChannel(
          //     channelGroupKey: 'privacy_tests',
          //     channelKey: "private_channel",
          //     channelName: "Privates notification channel",
          //     channelDescription: "Privates notification from lock screen",
          //     playSound: true,
          //     defaultColor: Colors.red,
          //     ledColor: Colors.red,
          //     vibrationPattern: lowVibrationPattern,
          //     defaultPrivacy: NotificationPrivacy.Private),
          // NotificationChannel(
          //     channelGroupKey: 'sound_tests',
          //     icon: 'resource://drawable/res_power_ranger_thunder',
          //     channelKey: "custom_sound",
          //     channelName: "Custom sound notifications",
          //     channelDescription: "Notifications with custom sound",
          //     playSound: true,
          //     soundSource: 'resource://assets/sounds/res_morph_power_rangers',
          //     defaultColor: Colors.red,
          //     ledColor: Colors.red,
          //     vibrationPattern: lowVibrationPattern),
          // NotificationChannel(
          //     channelGroupKey: 'sound_tests',
          //     channelKey: "silenced",
          //     channelName: "Silenced notifications",
          //     channelDescription: "The most quiet notifications",
          //     playSound: false,
          //     enableVibration: false,
          //     enableLights: false),
          // NotificationChannel(
          //     channelGroupKey: 'media_player_tests',
          //     icon: 'resource://drawable/res_media_icon',
          //     channelKey: 'media_player',
          //     channelName: 'Media player controller',
          //     channelDescription: 'Media player controller',
          //     defaultPrivacy: NotificationPrivacy.Public,
          //     enableVibration: false,
          //     enableLights: false,
          //     playSound: false,
          //     locked: true),
          // NotificationChannel(
          //     channelGroupKey: 'image_tests',
          //     channelKey: 'big_picture',
          //     channelName: 'Big pictures',
          //     channelDescription: 'Notifications with big and beautiful images',
          //     defaultColor: const Color(0xFF9D50DD),
          //     ledColor: const Color(0xFF9D50DD),
          //     vibrationPattern: lowVibrationPattern,
          //     importance: NotificationImportance.High),
          // NotificationChannel(
          //     channelGroupKey: 'layout_tests',
          //     channelKey: 'big_text',
          //     channelName: 'Big text notifications',
          //     channelDescription: 'Notifications with a expandable body text',
          //     defaultColor: Colors.blueGrey,
          //     ledColor: Colors.blueGrey,
          //     vibrationPattern: lowVibrationPattern),
          // NotificationChannel(
          //     channelGroupKey: 'layout_tests',
          //     channelKey: 'inbox',
          //     channelName: 'Inbox notifications',
          //     channelDescription: 'Notifications with inbox layout',
          //     defaultColor: const Color(0xFF9D50DD),
          //     ledColor: const Color(0xFF9D50DD),
          //     vibrationPattern: mediumVibrationPattern),
          // NotificationChannel(
          //   channelGroupKey: 'schedule_tests',
          //   channelKey: 'scheduled',
          //   channelName: 'Scheduled notifications',
          //   channelDescription: 'Notifications with schedule functionality',
          //   defaultColor: const Color(0xFF9D50DD),
          //   ledColor: const Color(0xFF9D50DD),
          //   vibrationPattern: lowVibrationPattern,
          //   importance: NotificationImportance.High,
          //   defaultRingtoneType: DefaultRingtoneType.Alarm,
          //   criticalAlerts: true,
          // ),
          // NotificationChannel(
          //     channelGroupKey: 'layout_tests',
          //     icon: 'resource://drawable/res_download_icon',
          //     channelKey: 'progress_bar',
          //     channelName: 'Progress bar notifications',
          //     channelDescription: 'Notifications with a progress bar layout',
          //     defaultColor: Colors.deepPurple,
          //     ledColor: Colors.deepPurple,
          //     vibrationPattern: lowVibrationPattern,
          //     onlyAlertOnce: true),
          // NotificationChannel(
          //     channelGroupKey: 'grouping_tests',
          //     channelKey: 'grouped',
          //     channelName: 'Grouped notifications',
          //     channelDescription: 'Notifications with group functionality',
          //     groupKey: 'grouped',
          //     groupSort: GroupSort.Desc,
          //     groupAlertBehavior: GroupAlertBehavior.Children,
          //     defaultColor: Colors.lightGreen,
          //     ledColor: Colors.lightGreen,
          //     vibrationPattern: lowVibrationPattern,
          //     importance: NotificationImportance.High)
        ],
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'chat',
              channelGroupName: Intl.withLocale(localeName, () => chatMessages())),
          NotificationChannelGroup(
              channelGroupKey: 'call',
              channelGroupName: Intl.withLocale(localeName, () => videoCalls())),
        ],
        //   NotificationChannelGroup(
        //       channelGroupKey: 'image_tests', channelGroupName: 'Images tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'schedule_tests',
        //       channelGroupName: 'Schedule tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'chat_tests', channelGroupName: 'Chat tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'channel_tests',
        //       channelGroupName: 'Channel tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'sound_tests', channelGroupName: 'Sound tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'vibration_tests',
        //       channelGroupName: 'Vibration tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'privacy_tests',
        //       channelGroupName: 'Privacy tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'layout_tests',
        //       channelGroupName: 'Layout tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'grouping_tests',
        //       channelGroupName: 'Grouping tests'),
        //   NotificationChannelGroup(
        //       channelGroupKey: 'media_player_tests',
        //       channelGroupName: 'Media Player tests')
        // ],
        );
    _instance.initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static Future<void> initializeNotificationsEventListeners() async {
    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationsController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationsController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationsController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationsController.onDismissActionReceivedMethod);
  }

  // ***************************************************************
  //    ON ACTION EVENT REDIRECTION TO MAIN ISOLATE
  // ***************************************************************

  static ReceivePort? receivePort;
  static Future<void> initializeIsolateReceivePort() async {
    receivePort = ReceivePort('Notification action port in main isolate');
    receivePort!.listen((serializedData) {
      final receivedAction = ReceivedAction().fromMap(serializedData);
      onActionReceivedMethodImpl(receivedAction);
    });

    // This initialization only happens on main isolate
    IsolateNameServer.registerPortWithName(
        receivePort!.sendPort, 'notification_action_port');
  }

  // ***************************************************************
  //    NOTIFICATIONS EVENT LISTENERS
  // ***************************************************************

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    var message =
        'Notification created on ${receivedNotification.createdLifeCycle?.name}';
    logger.i("Notifications Controller ", message);
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    var message1 =
        'Notification displayed on ${receivedNotification.displayedLifeCycle?.name}';
    var message2 =
        'Notification displayed at ${receivedNotification.displayedDate}';

    logger.i("Notifications Controller ", message1);
    logger.i("Notifications Controller ", message2);
    Fluttertoast.showToast(
        msg: message1,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.blue,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    var message =
        'Notification dismissed on ${receivedAction.dismissedLifeCycle?.name}';
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        gravity: ToastGravity.BOTTOM);
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivePort != null) {
      await onActionReceivedMethodImpl(receivedAction);
    } else {
      logger.i("Notifications Controller ",
          'onActionReceivedMethod was called inside a parallel dart isolate, where receivePort was never initialized.');
      SendPort? sendPort =
          IsolateNameServer.lookupPortByName('notification_action_port');

      if (sendPort != null) {
        logger.i("Notifications Controller ",
            'Redirecting the execution to main isolate process in listening...');
        dynamic serializedData = receivedAction.toMap();
        sendPort.send(serializedData);
      }
    }
  }

  static Future<void> onActionReceivedMethodImpl(
      ReceivedAction receivedAction) async {
    var message =
        'Action ${receivedAction.actionType?.name} received on ${receivedAction.actionLifeCycle?.name}';
    logger.i("Notifications Controller ", message);

    // Always ensure that all plugins was initialized
    WidgetsFlutterBinding.ensureInitialized();

    bool isSilentAction =
        receivedAction.actionType == ActionType.SilentAction ||
            receivedAction.actionType == ActionType.SilentBackgroundAction;

    // SilentBackgroundAction runs on background thread and cannot show
    // UI/visual elements
    if (receivedAction.actionType != ActionType.SilentBackgroundAction) {
      Fluttertoast.showToast(
          msg: '${isSilentAction ? 'Silent action' : 'Action'}'
              ' received on ${receivedAction.actionLifeCycle?.name}',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor:
              isSilentAction ? Colors.blueAccent : kLightTheme.primaryColor,
          gravity: ToastGravity.BOTTOM);
    }
    var actionBasedOnSenderCheck =
        receivedAction.payload?['senderID'] == AnyChatAuth.currentUser.id
            ? null
            : receivedAction.channelKey;

    switch (actionBasedOnSenderCheck) {
      case 'call_channel':
        if (receivedAction.actionLifeCycle !=
            NotificationLifeCycle.Terminated) {
          await receiveCallNotificationAction(receivedAction);
        }
        break;

      case 'alarm_channel':
        await receiveAlarmNotificationAction(receivedAction);
        break;

      case 'chats':
        await receiveChatNotificationAction(receivedAction);
        break;

      default:
        if (isSilentAction) {
          logger.i("Notifications Controller ", receivedAction.toString());
          logger.i("Notifications Controller ", "start");
          await Future.delayed(const Duration(seconds: 4));
          final url = Uri.parse("http://google.com");
          final re = await http.get(url);
          logger.i("Notifications Controller ", re.body);
          logger.i("Notifications Controller ", "long task done");
          break;
        }
        if (!AwesomeStringUtils.isNullOrEmpty(receivedAction.buttonKeyInput)) {
          receiveButtonInputText(receivedAction);
        } else {
          receiveStandardNotificationAction(receivedAction);
        }
        break;
    }
  }

  // ***************************************************************
  //    NOTIFICATIONS HANDLING METHODS
  // ***************************************************************

  static Future<void> receiveButtonInputText(
      ReceivedAction receivedAction) async {
    logger.i("Notifications Controller ",
        'Input Button Message: "${receivedAction.buttonKeyInput}"');
    Fluttertoast.showToast(
        msg: 'Msg: ${receivedAction.buttonKeyInput}',
        backgroundColor: kLightTheme.primaryColor,
        textColor: Colors.white);
  }

  static Future<void> receiveStandardNotificationAction(
      ReceivedAction receivedAction) async {
    loadSingletonPage(NavigationService().navigatorKey.currentState,
        targetPage: '/chat', receivedAction: receivedAction);
  }

  static Future<void> receiveChatNotificationAction(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'REPLY') {
      await AnyChatUser.addMessageToConversation(receivedAction.buttonKeyInput,
          conversationId: receivedAction.groupKey);
      await NotificationUtils.createMessagingNotification(
        channelKey: 'chats',
        groupKey: receivedAction.groupKey ?? '',
        chatName: localizationOf(null).newMessage,
        username: AnyChatAuth.currentUser.displayName,
        largeIcon: AnyChatAuth.currentUser.photoUrl,
        message: receivedAction.buttonKeyInput,
      );
    } else {
      loadSingletonPage(NavigationService().navigatorKey.currentState,
          targetPage: '/chat', receivedAction: receivedAction);
    }
  }

  static Future<void> receiveAlarmNotificationAction(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('stringValue', "abc");
      await NotificationUtils.showAlarmNotification(id: receivedAction.id!);
    }
  }

  static Future<void> receiveCallNotificationAction(
      ReceivedAction receivedAction) async {
    switch (receivedAction.buttonKeyPressed) {
      case 'REJECT':
        // Is not necessary to do anything, because the reject button is
        // already auto dismissible
        break;

      case 'ACCEPT':
      default:
        AnyChatAuth.currentConversation =
            await Conversation.getConversationById(
                receivedAction.payload?['conversationId'] ?? '');
        loadSingletonPage(Utilities().globalKey.currentState,
            targetPage: '/call', receivedAction: receivedAction);
        break;
    }
  }

  Future<void> interceptInitialCallActionRequest() async {
    ReceivedAction? receivedAction =
        await AwesomeNotifications().getInitialNotificationAction();

    if (receivedAction?.channelKey == 'call_channel') {
      initialAction = receivedAction;
    }
  }

  // static Future<void> initializeRemoteNotifications() async {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   await AwesomeNotificationsFcm().initialize(
  //     onFcmTokenHandle: NotificationsController.myFcmTokenHandle,
  //     onNativeTokenHandle: NotificationsController.myNativeTokenHandle,
  //     onFcmSilentDataHandle: NotificationsController.mySilentDataHandle,
  //     licenseKeys:
  //         // On this example app, the app ID / Bundle Id are different
  //         // for each platform, so i used the main Bundle ID + 1 variation
  //         [
  //       // me.carda.awesomeNotificationsFcmExample
  //       '2024-01-02==kZDwJQkSR7mrjEgDk7afWDSrqYCiqW6Ao/7wn/w6v5OKOgAnoEWt'
  //           'gqO0ELI1BxWNzSde2gbaW+9Ki6Tx94pU2gQRJuJxXGsvcmCRla1mB/0U/rPh'
  //           'f77bxgPRG+PHn9+p9sQ5nfvY6Ytw9IvDn4NjH3ccbjoXFRrs7R/ou9aapq2a'
  //           'jRHqXlIzDR1ihyQHC91Wvkviw2qTOEYDhR5hE4T2l1iHsTTpeXOqWk0XmgnC'
  //           'gO18e4Hv0P5WKICCull+PCh+OXQYTK5x0UwQPNOGN20rQu5zR9C0ph0hFQxk'
  //           'WLa/ft206pBZmWDf4HiyAawXPoR1AMWAh/t0cjh8gRTTNfHeog==',
  //
  //       // me.carda.awesome_notifications_fcm_example
  //       '2024-01-02==lYUBqt9kKmObnP7UzWd2KK9FOTOySkVATX/j/CGEzSlSKsQx5y5S9'
  //           'RKHG1lP1TZ5KHO6+wwkNbzxmni4uJ418WM3ywTY199bHAp5MHWxZEEgvMMG4/'
  //           '/V2W0acFhSgxH6GL/6XNYvhS2RwaX7X/z4NX7Z4dgZVOn0VW3GRyg7I/zLcgl'
  //           'Dhh+n9obRuGnZI+Xakw2id97PSG4QZOCw15A0LzE1lip/Fzj0cMRsqpvcAW2K'
  //           'VWYZm5ZmK2yKVcop1kxiq1faZGL1fBteJCQ8YeQKpqS+aaVmexdJXmB7sJVl0'
  //           '5o87ORRfijpO+Q6gmTYfjYxoiQMismHUx6NAnoB/txaLw=='
  //     ],
  //   );
  // }

  static getInitialNotificationAction() async {
    await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  ///  *********************************************
  ///     REMOTE NOTIFICATION EVENTS
  ///  *********************************************

  /// Use this method to execute on background when a silent data arrives
  /// (even while terminated)
  @pragma("vm:entry-point")
  static Future<void> mySilentDataHandle(/*FcmSilentData silentData*/) async {
    Fluttertoast.showToast(
        msg: 'Silent data received',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16);

    // print('"SilentData": ${silentData.toString()}');

    //  if (silentData.createdLifeCycle != NotificationLifeCycle.Foreground) {
    //   print("bg");
    // } else {
    //   print("FOREGROUND");
    // }

    logger.d('mySilentDataHandle received a FcmSilentData execution');
    await executeLongTaskInBackground();
  }

  /// Use this method to detect when a new fcm token is received
  @pragma("vm:entry-point")
  static Future<void> myFcmTokenHandle(String token) async {
    if (token.isNotEmpty) {
      Fluttertoast.showToast(
          msg: 'Fcm token received',
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16);

      // debugPrint('Firebase Token:"$token"');
    } else {
      Fluttertoast.showToast(
          msg: 'Fcm token deleted',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16);

      // debugPrint('Firebase Token deleted');
    }

    _instance._firebaseToken = token;
    _instance.notifyListeners();
  }

  /// Use this method to detect when a new native token is received
  @pragma("vm:entry-point")
  static Future<void> myNativeTokenHandle(String token) async {
    Fluttertoast.showToast(
        msg: 'Native token received',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16);
    // debugPrint('Native Token:"$token"');

    _instance._nativeToken = token;
    _instance.notifyListeners();
  }

  static Future<void> executeLongTaskInBackground() async {
    logger.d("starting long task");
    await Future.delayed(const Duration(seconds: 4));
    final url = Uri.parse("http://google.com");
    final re = await http.get(url);
    logger.d(re.body);
    logger.d("long task done");
  }
}
