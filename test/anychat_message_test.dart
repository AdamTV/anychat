import 'package:anychat/database/anychat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AnyChatMessage messageAt(int seconds) => AnyChatMessage(
      'id-$seconds', Timestamp(seconds, 0), 'sender-1', 'hello', null);

  group('AnyChatMessage fields', () {
    test('exposes the values it was constructed with', () {
      final message = AnyChatMessage(
          'abc', Timestamp(5, 0), 'sender-9', 'translated text', null);

      expect(message.id, 'abc');
      expect(message.senderId, 'sender-9');
      expect(message.text, 'translated text');
      expect(message.timestamp.seconds, 5);
      expect(message.reference, isNull);
    });
  });

  group('AnyChatMessage.compareTo', () {
    test('orders messages by timestamp ascending', () {
      final earlier = messageAt(100);
      final later = messageAt(200);

      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
    });

    test('returns zero for identical timestamps', () {
      expect(messageAt(100).compareTo(messageAt(100)), 0);
    });

    test('distinguishes nanoseconds within the same second', () {
      final first = AnyChatMessage('a', Timestamp(100, 1), 's', 't', null);
      final second = AnyChatMessage('b', Timestamp(100, 2), 's', 't', null);

      expect(first.compareTo(second), lessThan(0));
    });
  });
}
