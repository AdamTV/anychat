import 'package:anychat/components/combined_locale_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getSupportedLocales', () {
    test('returns one locale per supported language', () {
      final locales = getSupportedLocales();

      expect(locales, isNotEmpty);
      expect(locales.length, endonymRetrievalMap.length);
      expect(locales, contains(const Locale('en')));
    });

    test('contains no duplicate locales', () {
      final locales = getSupportedLocales();

      expect(locales.toSet().length, locales.length);
    });
  });

  group('endonym helpers', () {
    late AppLocalizations localizations;

    setUpAll(() async {
      localizations = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('getEndonymByLocaleCode returns the endonym for a known code', () {
      expect(getEndonymByLocaleCode('en', localizations), 'English');
      expect(getEndonymByLocaleCode('fr', localizations), 'French');
    });

    test('getEndonymByLocaleCode reports unknown codes', () {
      expect(
          getEndonymByLocaleCode('xx', localizations), 'Unknown Locale (xx)');
    });

    test('getLocaleCodeByEndonym resolves an endonym back to its code', () {
      expect(getLocaleCodeByEndonym('English', localizations), 'en');
    });

    test('getLocaleCodeByEndonym is case and whitespace insensitive', () {
      expect(getLocaleCodeByEndonym('  english ', localizations), 'en');
    });

    test('getLocaleCodeByEndonym falls back to en for unknown endonyms', () {
      expect(getLocaleCodeByEndonym('not a locale', localizations), 'en');
    });

    test('getAllEndonyms maps every supported language', () {
      final endonyms = getAllEndonyms(localizations);

      expect(endonyms.length, endonymRetrievalMap.length);
      expect(endonyms['English'], 'en');
    });
  });
}
