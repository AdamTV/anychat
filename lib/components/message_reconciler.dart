import 'package:anychat/database/anychat_message.dart';

typedef TranslateMessages = Future<Map<String, String>> Function(
  List<AnyChatMessage> messages,
);

class TranslatedMessage {
  final AnyChatMessage message;
  final String translation;

  const TranslatedMessage(this.message, this.translation);
}

/// Serializes full query snapshots and caches translations by document identity
/// and content. Metadata changes replace the model, never append another bubble.
class MessageReconciler {
  Future<void> _pending = Future<void>.value();
  List<TranslatedMessage> _messages = [];
  bool _disposed = false;

  List<TranslatedMessage> get messages => List.unmodifiable(_messages);

  Future<bool> reconcile(
    List<AnyChatMessage> snapshot,
    TranslateMessages translate,
  ) {
    final immutableSnapshot = List<AnyChatMessage>.of(snapshot);
    final result = _pending.then((_) => _apply(immutableSnapshot, translate));
    // An unsuccessful translation must not poison subsequent snapshots.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> _apply(
    List<AnyChatMessage> snapshot,
    TranslateMessages translate,
  ) async {
    if (_disposed) return false;
    final previous = {for (final entry in _messages) entry.message.id: entry};
    final byId = {for (final message in snapshot) message.id!: message};
    final changed = byId.values.where((message) {
      final old = previous[message.id]?.message;
      return old == null ||
          old.text != message.text ||
          old.senderId != message.senderId;
    }).toList();
    final translations = changed.isEmpty
        ? <String, String>{}
        : await translate(changed);
    if (_disposed) return false;
    _messages = [
      for (final message in byId.values)
        TranslatedMessage(
          message,
          translations[message.id] ?? previous[message.id]?.translation ?? '',
        ),
    ];
    return true;
  }

  void dispose() {
    _disposed = true;
    _messages = [];
  }
}
