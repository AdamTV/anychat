import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
  // final List<dynamic> messages;
  final List<dynamic> transcribedMessages;
  final DocumentReference reference;

  Conversation._(this.id, this.participants, this.reference, this.transcribedMessages);

  Conversation.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        participants =
            List.castFrom<dynamic, String>(snapshot.data()['participants']),
        // messages = (snapshot.data()['messages']),
        transcribedMessages = (snapshot.data()['transcribedMessages']),
        reference = snapshot.reference;
}
