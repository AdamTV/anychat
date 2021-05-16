// For each conversation of each user, an instance of this class must be
// persisted
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationInfo {
  final String id;
  String incomingLanguage;
  String outgoingLanguage;

  ConversationInfo(this.id, this.incomingLanguage, this.outgoingLanguage);

  ConversationInfo.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        incomingLanguage = snapshot.data() == null
            ? null
            : snapshot.data()['incomingLanguage'],
        outgoingLanguage = snapshot.data() == null
            ? null
            : snapshot.data()['outgoingLanguage'];

  static Future<List<ConversationInfo>> getAllConversationInfo(
      String id) async {
    var ret = <ConversationInfo>[];

    var test = await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("conversations")
        .get();

    for (var doc in test.docs) {
      ret.add(ConversationInfo.fromSnapshot(doc));
    }

    return ret;
  }
}
