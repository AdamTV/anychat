import 'dart:async';

import 'package:anychat/components/composer_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComposerSendGuard', () {
    late List<String> sent;
    late int errors;
    late ComposerSendGuard guard;

    setUp(() {
      sent = [];
      errors = 0;
      guard = ComposerSendGuard();
    });

    test('a second submit is ignored while the first is in flight', () async {
      final blocked = Completer<void>();
      // Start the first send without awaiting it so it stays in flight.
      final first = guard.send(
        'hello',
        sendAction: (text) {
          sent.add(text);
          return blocked.future;
        },
      );
      // Second submit races the first (Enter + tap). It must be a no-op.
      final second = await guard.send(
        'hello',
        sendAction: (text) {
          sent.add(text);
          return Future<void>.value();
        },
      );
      expect(second, isFalse);
      expect(sent, ['hello']);
      blocked.complete();
      await first;
      // After the first send resolves the controller is cleared.
      expect(guard.controller.text, isEmpty);
    });

    test('two rapid submits enqueue exactly one provider send', () async {
      final blocked = Completer<void>();
      // Fire both submits back-to-back while the first action is pending,
      // modelling Enter and a tap landing within the same frame.
      final first = guard.send(
        'double tap',
        sendAction: (text) {
          sent.add(text);
          return blocked.future;
        },
      );
      final second = await guard.send(
        'double tap',
        sendAction: (text) => Future<void>.value(),
      );
      expect(second, isFalse);
      blocked.complete();
      await first;
      expect(sent, ['double tap']);
      expect(guard.controller.text, isEmpty);
    });

    test('failure keeps the draft and reports an error', () async {
      guard.controller.text = 'will fail';
      await guard.send(
        'will fail',
        sendAction: (text) => throw StateError('no-network'),
        onError: () => errors++,
      );
      expect(errors, 1);
      // Draft restored: the composer still holds the unsent text.
      expect(guard.controller.text, 'will fail');
      expect(sent, isEmpty);
    });

    test('an ignored submit while in flight reports no error', () async {
      final blocked = Completer<void>();
      final first = guard.send('first', sendAction: (text) => blocked.future);
      var secondErrored = false;
      final started = await guard.send(
        'first',
        sendAction: (text) => Future<void>.value(),
        onError: () => secondErrored = true,
      );
      expect(started, isFalse);
      expect(secondErrored, isFalse);
      blocked.complete();
      await first;
    });

    test('empty and whitespace-only text is not sent', () async {
      final startedBlank = await guard.send(
        '   ',
        sendAction: (text) => Future<void>.value(),
      );
      expect(startedBlank, isFalse);
      expect(sent, isEmpty);
    });

    test('a send can proceed after a previous failure', () async {
      guard.controller.text = 'retry me';
      await guard.send(
        'retry me',
        sendAction: (text) => throw StateError('offline'),
        onError: () => errors++,
      );
      expect(errors, 1);
      // Now the network is back; the same draft sends.
      final started = await guard.send(
        'retry me',
        sendAction: (text) async {
          sent.add(text);
        },
      );
      expect(started, isTrue);
      expect(sent, ['retry me']);
      expect(guard.controller.text, isEmpty);
    });
  });

  group('ComposerSendGuard widget integration', () {
    testWidgets('composer clears on success and keeps draft on failure', (
      tester,
    ) async {
      final host = GlobalKey<_GuardHostState>();
      await tester.pumpWidget(MaterialApp(home: _GuardHost(key: host)));

      // Success path: typing then submitting empties the field.
      await tester.enterText(find.byType(TextField), 'sent ok');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(host.currentState!.successCount, 1);

      // Failure path: the draft remains in the field.
      await tester.enterText(find.byType(TextField), 'will fail');
      host.currentState!.failNext = true;
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(host.currentState!.successCount, 1); // unchanged
      expect(host.currentState!.guard.controller.text, 'will fail');
    });
  });
}

class _GuardHost extends StatefulWidget {
  const _GuardHost({super.key});

  @override
  State<_GuardHost> createState() => _GuardHostState();
}

class _GuardHostState extends State<_GuardHost> {
  late final ComposerSendGuard guard = ComposerSendGuard();
  bool failNext = false;
  int successCount = 0;

  Future<void> send(String text) async {
    if (failNext) {
      failNext = false;
      throw StateError('offline');
    }
    successCount++;
  }

  @override
  void dispose() {
    guard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        Expanded(child: TextField(controller: guard.controller)),
        TextButton(
          onPressed: () async {
            await guard.send(
              guard.controller.text,
              sendAction: (text) => send(text),
            );
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
