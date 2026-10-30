import 'package:anychat/components/utilities.dart';
import 'package:anychat/database/sms_conversation.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/material.dart';

// Localization for these literals is a follow-up; see the fork's README.

/// Opens the New SMS dialog: text a phone contact from anychat's number
/// pool. Replies arrive as chat messages from the contact and go through
/// the normal translation pipeline.
Future<void> showNewSmsDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('New SMS'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          hintText: 'Phone number (E.164, e.g. +14155551234)',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final contact = canonicalSmsContact(controller.text);
            if (contact == null) {
              return;
            }
            Navigator.of(dialogContext).pop();
            try {
              await openSmsConversation(contact);
            } catch (error, stackTrace) {
              logger.e('Could not open SMS conversation',
                  error: error, stackTrace: stackTrace);
              Utilities().showToast(
                  'Could not start the SMS conversation. Try again.');
              return;
            }
            NavigationService().pushNamed('/chat');
          },
          child: const Text('Start'),
        ),
      ],
    ),
  );
}
