import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/database/conversation_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// SMS conversations with phone contacts, through the alpha-text bridge.
//
// The conversation id is deterministic — smsConversationId mirrors the
// Cloud Function bridge (functions/sms_bridge.js) — so a reply from a
// contact lands in the same thread the user started, with no Firestore
// query. Firestore auto-generated ids never contain "-", so the "sms-"
// prefix is an unambiguous marker for SMS threads.

/// Digits of a phone contact, e.g. "+1 555 0100" -> "15550100".
String smsDigits(String contact) => contact.replaceAll(RegExp(r'[^0-9]'), '');

/// Deterministic conversation id for (uid, phone contact).
String smsConversationId(String uid, String contact) =>
    'sms-$uid-${smsDigits(contact)}';

/// Synthetic participant id representing a phone contact. It never
/// resolves to a real users/{id} doc; the chat UI already renders a
/// placeholder sender for unknown ids.
String smsContactParticipantId(String contact) => 'sms:+${smsDigits(contact)}';

/// The phone number behind an [smsContactParticipantId], or null when
/// [participantId] is not a phone contact.
String? smsContactFromParticipantId(String participantId) =>
    participantId.startsWith('sms:+') ? participantId.substring(4) : null;

/// True when [conversationId] names an SMS thread. The "sms-" prefix is
/// unambiguous because Firestore auto-generated ids never contain "-".
bool isSmsConversationId(String? conversationId) =>
    conversationId?.startsWith('sms-') ?? false;

/// Language fields to initialize on a per-user SMS conversation info doc,
/// or null when the doc already exists so the user's settings survive
/// reopening the thread.
Map<String, String>? smsConversationInfoDefaults(
        {required bool infoExists, required String language}) =>
    infoExists
        ? null
        : {'incomingLanguage': language, 'outgoingLanguage': language};

/// Canonical E.164 form of [contact], or null when it is not a valid E.164
/// number. Formatting characters (spaces, dots, dashes, parentheses) are
/// dropped; the result must be "+" and 7-15 digits without a leading zero.
/// Firestore rules and the bridge (functions/sms_bridge.js) require this
/// exact form, so every client opens the same thread id for a contact.
String? canonicalSmsContact(String contact) {
  final compact = contact.replaceAll(RegExp(r'[\s().-]'), '');
  return RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(compact) ? compact : null;
}

/// True when [contact] is a textable E.164 phone number.
bool isValidSmsContact(String contact) => canonicalSmsContact(contact) != null;

/// Opens (or reuses) the SMS conversation with [rawContact] and makes it the
/// current one. Writes the same documents the bridge writes for inbound
/// messages: the conversation doc and the per-user conversation info that
/// the chat list and translation pipeline read. Outbound messages in this
/// conversation carry channel "sms" (see addMessageToConversation), which
/// the relaySmsMessage trigger forwards through alpha-text's number pool.
/// Throws [ArgumentError] when [rawContact] is not a valid E.164 number.
Future<Conversation> openSmsConversation(String rawContact) async {
  final contact = canonicalSmsContact(rawContact);
  if (contact == null) {
    throw ArgumentError.value(rawContact, 'rawContact', 'not an E.164 number');
  }
  final uid = AnyChatAuth.currentUser.id;
  final conversationId = smsConversationId(uid, contact);
  final language = AnyChatAuth.currentUser.language;

  final conversationDoc = FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId);
  final infoDoc = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('conversations')
      .doc(conversationId);
  await FirebaseFirestore.instance
      .runTransaction((Transaction transaction) async {
    final existingInfo = await transaction.get(infoDoc);
    transaction.set(
        conversationDoc,
        {
          'participants': [uid, smsContactParticipantId(contact)],
          'smsOwner': uid,
          'smsContact': contact,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    final defaults = smsConversationInfoDefaults(
        infoExists: existingInfo.exists, language: language);
    if (defaults != null) {
      transaction.set(infoDoc, defaults);
    }
  });

  final info = ConversationInfo.fromSnapshot(await infoDoc.get());
  AnyChatAuth.currentUser.conversations
      .removeWhere((element) => element.id == conversationId);
  AnyChatAuth.currentUser.conversations.add(info);

  AnyChatAuth.currentConversation =
      Conversation.fromSnapshot(await conversationDoc.get());
  AnyChatAuth.currentChatters = [
    AnyChatUser.deletedUser(smsContactParticipantId(contact)),
  ];
  return AnyChatAuth.currentConversation!;
}
