import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnyChatMessage {
  final AnyChatUser sender;
  final String text;

  AnyChatMessage(this.sender, this.text);

  AnyChatMessage.fromSnapshot(DocumentSnapshot snapshot)
  : assert(snapshot != null),
  sender = snapshot.data()['sender'],
  text = snapshot.data()['text'];
}