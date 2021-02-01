import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnyChatMessage {
  final String id;
  final Timestamp timestamp;
  final String senderId;
  final String text;

  final DocumentReference reference;

  AnyChatMessage(this.id, this.timestamp, this.senderId, this.text, this.reference);

  AnyChatMessage.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        timestamp = snapshot.data()['timestamp'],
        senderId = snapshot.data()['senderId'],
        text = snapshot.data()['text'],
        reference = snapshot.reference;
}
