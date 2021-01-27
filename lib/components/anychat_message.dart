import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnyChatMessage {
  final DateTime timeStamp;
  final AnyChatUser sender;
  final String text;

  AnyChatMessage(this.sender, this.text, this.timeStamp);

  AnyChatMessage.fromSnapshot(DocumentSnapshot snapshot)
  : assert(snapshot != null),
  // id = snapshot.id,
  timeStamp = snapshot.data()['timestamp'],
  sender = snapshot.data()['sender'],
  text = snapshot.data()['text'];
}