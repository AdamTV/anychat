import 'package:anychat/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'anychat_message.dart';
import 'firestore_batch.dart';

class Conversation {
  final String id;
  final List<String> participants;

  // final List<dynamic> messages;
  final List<dynamic>? transcribedMessages;
  final Timestamp? timestamp;
  final DocumentReference reference;

  // Conversation._(
  //     this.id, this.participants, this.reference, this.transcribedMessages, this.timestamp);

  Conversation.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        participants = List.castFrom<dynamic, String>((snapshot.data()
            as Map<String, dynamic>)['participants'] as List<dynamic>),
        // messages = ((snapshot.data() as Map<String, dynamic>)['messages']),
        transcribedMessages = ((snapshot.data()
            as Map<String, dynamic>)['transcribedMessages'] as List<dynamic>?),
        timestamp = (snapshot.data() as Map<String, dynamic>)['timestamp']
            as Timestamp?,
        reference = snapshot.reference;

  static Future<Conversation> getConversationById(String id) async {
    return Conversation.fromSnapshot(await FirebaseFirestore.instance
        .collection('conversations')
        .doc(id)
        .get());
  }

  static Future<List<Conversation>> getConversationsByIds(
      Iterable<String> ids) async {
    final uniqueIds = ids.toSet();
    if (uniqueIds.isEmpty) {
      return <Conversation>[];
    }

    final conversations = <Conversation>[];
    for (final idBatch in chunkForFirestoreInQuery(uniqueIds)) {
      final snapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where(FieldPath.documentId, whereIn: idBatch)
          .get();
      conversations.addAll(snapshot.docs.map(Conversation.fromSnapshot));
    }
    return conversations;
  }

  static Future<AnyChatMessage?> getLatestMessageByConversationId(
      String id) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      return snapshot.docs.isEmpty
          ? null
          : AnyChatMessage.fromSnapshot(snapshot.docs.first);
    } catch (error, stackTrace) {
      logger.e('error getting chat messages: ',
          error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
}
