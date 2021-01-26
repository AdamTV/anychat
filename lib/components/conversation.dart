import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation{
  final String id;
  final List<String> participants;
  final List<dynamic> messages;
  final DocumentReference reference;

  Conversation._(this.id, this.participants, this.messages, this.reference);

  Conversation.fromSnapshot(DocumentSnapshot snapshot)
  : assert(snapshot != null),
  id = snapshot.id,
  participants = List.castFrom<dynamic, String>(snapshot.data()['participants']),
  messages = (snapshot.data()['messages']),
  reference = snapshot.reference;
}