import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation{
  final String id;
  final List<String> participants;
  final List<String> messages;

  Conversation._(this.id, this.participants, this.messages);

  Conversation.fromSnapshot(DocumentSnapshot snapshot)
  : assert(snapshot != null),
  id = snapshot.id,
  participants = List.castFrom<dynamic, String>(snapshot.data()['participants']),
  messages = List.castFrom<dynamic, String>(snapshot.data()['messages']);
}