// Integration test for the AnyChat Flutter client.
//
// Run on a connected device or emulator with:
//   flutter test integration_test/app_test.dart -d <device-id>
//
// The test boots the real app widget tree (same providers as main()), verifies
// the welcome screen renders, and drives a navigation interaction.

import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/login_screen.dart';
import 'package:anychat/services/notifications/notifications_controller.dart';
import 'package:anychat/services/notifier_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to the welcome screen and navigates to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DeivceNotifierService()),
          ChangeNotifierProvider(create: (context) => RemoteNotificationObserver()),
          ChangeNotifierProvider(create: (context) => NotificationsController()),
        ],
        child: const AnyChat(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The welcome screen renders the localized login and register actions.
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('REGISTER'), findsOneWidget);

    // Drive the app: tapping LOGIN navigates to the login screen.
    await tester.tap(find.text('LOGIN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
