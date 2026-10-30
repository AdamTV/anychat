import 'dart:async';

import 'package:anychat/components/utilities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/combined_locale_info.dart';
import 'anychat_auth.dart';
import 'anychat_user.dart';

/// Thrown when the user backs out of sign-in, or when the failure has already
/// been explained to them, so callers should not show another error.
class SignInCancelledException implements Exception {
  const SignInCancelledException();
}

class AnyChatPhoneAuth {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static BuildContext? get _context => Utilities().globalKey.currentContext;

  static Future<AnyChatUser?> signIn() async {
    final l10n = localizationOf(_context);
    final input = await _prompt(
      title: l10n.phoneNumber,
      hint: l10n.enterYourPhoneNumber,
      keyboardType: TextInputType.phone,
    );
    if (input == null) throw const SignInCancelledException();
    final phoneNumber = input.replaceAll(RegExp(r'[\s\-().]'), '');

    try {
      final credential = kIsWeb
          ? await _signInWeb(phoneNumber)
          : await _signInMobile(phoneNumber);
      final user = credential.user;
      if (user == null) return null;
      return await AnyChatAuth.loadOrCreateUser(user,
          displayName: user.displayName ?? user.phoneNumber);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-phone-number' => l10n.invalidPhoneNumber,
        'invalid-verification-code' ||
        'session-expired' =>
          l10n.invalidVerificationCode,
        _ => null,
      };
      if (message == null) rethrow;
      await Utilities().showAlertDialog(_context, l10n.error, message);
      throw const SignInCancelledException();
    }
  }

  /// Web verifies with an invisible reCAPTCHA, then confirms the SMS code.
  static Future<UserCredential> _signInWeb(String phoneNumber) async {
    final confirmation = await _auth.signInWithPhoneNumber(phoneNumber);
    final code = await _promptForCode(phoneNumber);
    if (code == null) throw const SignInCancelledException();
    return confirmation.confirm(code);
  }

  /// Android may verify the number on its own (instant verification or SMS
  /// auto-retrieval), in which case the code dialog is dismissed for the user.
  static Future<UserCredential> _signInMobile(String phoneNumber) {
    final completer = Completer<UserCredential>();
    BuildContext? codeDialogContext;

    void finish(Future<UserCredential> Function() signIn) {
      if (!completer.isCompleted) completer.complete(signIn());
    }

    void fail(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    _auth
        .verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (credential) {
            finish(() => _auth.signInWithCredential(credential));
            final dialogContext = codeDialogContext;
            if (dialogContext != null && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
          verificationFailed: fail,
          codeSent: (verificationId, _) async {
            final code = await _promptForCode(phoneNumber,
                onShown: (dialogContext) => codeDialogContext = dialogContext);
            codeDialogContext = null;
            if (code == null) {
              fail(const SignInCancelledException());
              return;
            }
            finish(() => _auth.signInWithCredential(
                PhoneAuthProvider.credential(
                    verificationId: verificationId, smsCode: code)));
          },
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError(fail);

    return completer.future;
  }

  static Future<String?> _promptForCode(String phoneNumber,
      {void Function(BuildContext dialogContext)? onShown}) {
    final l10n = localizationOf(_context);
    return _prompt(
      title: l10n.verificationCode,
      hint: l10n.enterSmsCode(phoneNumber),
      keyboardType: TextInputType.number,
      onShown: onShown,
    );
  }

  static Future<String?> _prompt({
    required String title,
    required String hint,
    required TextInputType keyboardType,
    void Function(BuildContext dialogContext)? onShown,
  }) async {
    final context = _context;
    if (context == null) return null;
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        onShown?.call(dialogContext);
        return _TextPromptDialog(
            title: title, hint: hint, keyboardType: keyboardType);
      },
    );
    return (value == null || value.isEmpty) ? null : value;
  }
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hint,
    required this.keyboardType,
  });

  final String title;
  final String hint;
  final TextInputType keyboardType;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = localizationOf(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(l10n.send),
        ),
      ],
    );
  }
}
