import 'package:anychat/database/anychat_user.dart';
import 'package:flutter/material.dart';

/// Owns the text composer's send lifecycle for a single chat screen.
///
/// The guard exists so a double submit (keyboard Enter plus a tap on the send
/// button, or two quick taps) can never enqueue two provider sends: while one
/// is in flight further submits are ignored. On success the composer controller
/// is cleared; on failure the draft is restored and an [onError] callback fires
/// so the message is never lost as if it had been sent.
///
/// The send action and error surface are injectable so this logic can be
/// exercised in a widget test without Firebase.
class ComposerSendGuard {
  ComposerSendGuard({TextEditingController? controller})
    : _controller = controller ?? TextEditingController();

  final TextEditingController _controller;

  bool _inFlight = false;

  /// The composer's text controller, exposed so the screen can bind its
  /// TextField to it.
  TextEditingController get controller => _controller;

  /// True while a submit is awaiting the provider. A send started during this
  /// window is ignored by [send].
  bool get isSending => _inFlight;

  /// Sends [text] if it is non-empty and no send is already in flight.
  ///
  /// Returns true when a submit started, false when it was ignored (empty text
  /// or an earlier send still in flight). The controller is cleared only after
  /// [sendAction] completes; on failure the original text is kept so the user
  /// can retry and [onError] is invoked.
  Future<bool> send(
    String text, {
    Future<void> Function(String) sendAction =
        AnyChatUser.addMessageToConversation,
    void Function()? onError,
  }) async {
    if (_inFlight) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _inFlight = true;
    try {
      await sendAction(trimmed);
      // Only clear the composer once the provider accepted the message. The
      // screen's onChanged then flips its composing flag back off.
      _controller.clear();
    } catch (_) {
      onError?.call();
    } finally {
      _inFlight = false;
    }
    return true;
  }

  /// Disposes the composer controller when the owning screen is disposed.
  void dispose() => _controller.dispose();
}
