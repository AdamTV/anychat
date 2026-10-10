import 'package:anychat/services/cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // UserData.themeFromString reads Utilities().globalKey.currentContext, which
  // requires an initialized widget binding even outside of testWidgets.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserData JSON serialization', () {
    test('toJson/fromJson round trip preserves all fields', () {
      final userData = UserData(
        id: 'user-123',
        username: 'qa_agent',
        email: 'qa@example.com',
        theme: ThemeData.light(),
        locale: const Locale('en'),
        notificationsEnabled: true,
      );

      final restored = UserData.fromJson(userData.toJson());

      expect(restored.id, 'user-123');
      expect(restored.username, 'qa_agent');
      expect(restored.email, 'qa@example.com');
      expect(restored.theme.brightness, Brightness.light);
      expect(restored.locale, const Locale('en'));
      expect(restored.notificationsEnabled, isTrue);
    });

    test('fromJson parses notificationsEnabled as a boolean string', () {
      final restored = UserData.fromJson({
        'id': 'user-1',
        'username': 'agent',
        'email': 'agent@example.com',
        'theme': 'light',
        'locale': 'en',
        'notificationsEnabled': 'false',
      });

      expect(restored.notificationsEnabled, isFalse);
    });
  });

  group('UserData.localeFromString', () {
    test('parses a bare language code', () {
      expect(UserData.localeFromString('en'), const Locale('en'));
    });

    test('parses a language and country code', () {
      expect(UserData.localeFromString('zh_CN'), const Locale('zh', 'CN'));
    });
  });

  group('UserData.localeToString', () {
    test('returns the language code', () {
      expect(UserData.localeToString(const Locale('en')), 'en');
      expect(UserData.localeToString(const Locale('zh', 'CN')), 'zh');
    });
  });

  group('UserData.themeToString', () {
    test('maps theme brightness to its string form', () {
      expect(UserData.themeToString(ThemeData.light()), 'light');
      expect(UserData.themeToString(ThemeData.dark()), 'dark');
      expect(UserData.themeToString(null), 'light');
    });
  });

  group('UserData.getThemeMode', () {
    test('maps theme brightness to a ThemeMode', () {
      final light = UserData(
        id: 'user-1',
        username: 'agent',
        email: 'agent@example.com',
        theme: ThemeData.light(),
        locale: const Locale('en'),
        notificationsEnabled: true,
      );
      final dark = UserData(
        id: 'user-1',
        username: 'agent',
        email: 'agent@example.com',
        theme: ThemeData.dark(),
        locale: const Locale('en'),
        notificationsEnabled: true,
      );

      expect(light.getThemeMode(), ThemeMode.light);
      expect(dark.getThemeMode(), ThemeMode.dark);
    });
  });
}
