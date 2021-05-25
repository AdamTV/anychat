import 'package:cloud_firestore/cloud_firestore.dart';

class AnyChatMessage {
  final String id;
  final Timestamp? timestamp;
  final String? senderId;
  final String? text;

  final DocumentReference? reference;

  AnyChatMessage(
      this.id, this.timestamp, this.senderId, this.text, this.reference);

  AnyChatMessage.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        timestamp = (snapshot.data() as Map<String, dynamic>)['timestamp'],
        senderId = (snapshot.data() as Map<String, dynamic>)['senderId'],
        text = (snapshot.data() as Map<String, dynamic>)['text'],
        reference = snapshot.reference;

  compareTo(AnyChatMessage b) {
    return timestamp!.compareTo(b.timestamp!);
  }
}
