import 'package:anychat/components/anychat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;

  // final List<dynamic> messages;
  final List<dynamic> transcribedMessages;
  final Timestamp timestamp;
  final DocumentReference reference;

  // Conversation._(
  //     this.id, this.participants, this.reference, this.transcribedMessages, this.timestamp);

  Conversation.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        participants =
            List.castFrom<dynamic, String>(snapshot.data()['participants']),
        // messages = (snapshot.data()['messages']),
        transcribedMessages = (snapshot.data()['transcribedMessages']),
        timestamp = snapshot.data()['timestamp'],
        reference = snapshot.reference;

  static Future<Conversation> getConversationById(String id) async {
    return Conversation.fromSnapshot(await FirebaseFirestore.instance
        .collection('conversations')
        .doc(id)
        .get());
  }
}
