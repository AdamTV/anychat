// Widget test for the OrDivider component: it must render the localized
// "OR" label between two divider lines.

import 'package:anychat/components/or_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OrDivider renders the localized label between two dividers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('en')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: OrDivider()),
      ),
    );

    expect(find.text('OR'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
