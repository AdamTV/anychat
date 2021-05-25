// For each conversation of each user, an instance of this class must be
// persisted
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationInfo {
  final String id;
  String? incomingLanguage;
  String? outgoingLanguage;

  ConversationInfo(this.id, this.incomingLanguage, this.outgoingLanguage);

  ConversationInfo.fromSnapshot(DocumentSnapshot snapshot)
      : id = snapshot.id,
        incomingLanguage = (snapshot.data() as Map<String, dynamic>?) == null
            ? null
            : (snapshot.data() as Map<String, dynamic>)['incomingLanguage'],
        outgoingLanguage = (snapshot.data() as Map<String, dynamic>?) == null
            ? null
            : (snapshot.data() as Map<String, dynamic>)['outgoingLanguage'];

  static Future<List<ConversationInfo>> getAllConversationInfo(
      String? id) async {
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
