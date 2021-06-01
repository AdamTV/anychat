import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String?> participants;

  // final List<dynamic> messages;
  final List<dynamic>? transcribedMessages;
  final Timestamp? timestamp;
  final DocumentReference reference;

  // Conversation._(
  //     this.id, this.participants, this.reference, this.transcribedMessages, this.timestamp);

  Conversation.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        participants = List.castFrom<dynamic, String?>(
            (snapshot.data() as Map<String, dynamic>)['participants']),
        // messages = ((snapshot.data() as Map<String, dynamic>)['messages']),
        transcribedMessages =
            ((snapshot.data() as Map<String, dynamic>)['transcribedMessages']),
        timestamp = (snapshot.data() as Map<String, dynamic>)['timestamp'],
        reference = snapshot.reference;

  static Future<Conversation> getConversationById(String id) async {
    return Conversation.fromSnapshot(await FirebaseFirestore.instance
        .collection('conversations')
        .doc(id)
        .get());
  }
}
