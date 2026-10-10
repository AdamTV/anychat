import 'package:cloud_firestore/cloud_firestore.dart';

class AnyChatMessage {
  final String? id;
  final Timestamp timestamp;
  final String senderId;
  late final String text;

  final DocumentReference? reference;

  AnyChatMessage(
      this.id, this.timestamp, this.senderId, this.text, this.reference);

  AnyChatMessage.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        timestamp =
            (snapshot.data() as Map<String, dynamic>)['timestamp'] as Timestamp,
        senderId =
            (snapshot.data() as Map<String, dynamic>)['senderId'] as String,
        text = (snapshot.data() as Map<String, dynamic>)['text'] as String,
        reference = snapshot.reference;

  int compareTo(AnyChatMessage b) {
    return timestamp.compareTo(b.timestamp);
  }
}
