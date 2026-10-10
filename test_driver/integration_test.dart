// Legacy integration test driver entry point.
//
// Kept for `flutter drive --driver=test_driver/integration_test.dart` workflows.
// The primary integration test lives in integration_test/app_test.dart and runs
// with `flutter test integration_test/app_test.dart -d <device-id>`.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
