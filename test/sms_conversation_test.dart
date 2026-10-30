import 'package:anychat/database/sms_conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSmsConversationId', () {
    test('recognizes bridge SMS thread ids', () {
      expect(
          isSmsConversationId(smsConversationId('uid1', '+15550100')), isTrue);
    });

    test('rejects normal chat ids and missing ids', () {
      expect(isSmsConversationId('AbC123autoId'), isFalse);
      expect(isSmsConversationId(null), isFalse);
    });
  });

  group('smsContactFromParticipantId', () {
    test('recovers the phone number of an SMS participant', () {
      expect(smsContactFromParticipantId(smsContactParticipantId('+15550100')),
          '+15550100');
    });

    test('ignores ordinary user ids', () {
      expect(smsContactFromParticipantId('AbC123uid'), isNull);
    });
  });

  group('canonicalSmsContact', () {
    test('keeps canonical E.164 numbers', () {
      expect(canonicalSmsContact('+15550100'), '+15550100');
    });

    test('drops formatting characters', () {
      expect(canonicalSmsContact(' +1 (555) 010-0100 '), '+15550100100');
      expect(canonicalSmsContact('+1.555.0100'), '+15550100');
    });

    test('rejects numbers that are not E.164', () {
      expect(canonicalSmsContact('15550100'), isNull);
      expect(canonicalSmsContact('+05550100'), isNull);
      expect(canonicalSmsContact('+123456'), isNull);
      expect(canonicalSmsContact('+1234567890123456'), isNull);
      expect(canonicalSmsContact('+1555abc0100'), isNull);
      expect(isValidSmsContact('call me'), isFalse);
    });

    test('canonical contacts give one thread id across formats', () {
      expect(smsConversationId('uid1', canonicalSmsContact('+1 555 0100')!),
          'sms-uid1-15550100');
      expect(smsContactParticipantId(canonicalSmsContact('+1-555-0100')!),
          'sms:+15550100');
    });
  });

  group('smsConversationInfoDefaults', () {
    test('initializes both languages for a new thread', () {
      expect(smsConversationInfoDefaults(infoExists: false, language: 'fr'),
          {'incomingLanguage': 'fr', 'outgoingLanguage': 'fr'});
    });

    test('leaves existing language settings untouched', () {
      expect(smsConversationInfoDefaults(infoExists: true, language: 'fr'),
          isNull);
    });
  });
}
