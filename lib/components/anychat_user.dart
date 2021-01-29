import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/components/locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'anychat_auth.dart';
import 'anychat_message.dart';
import 'conversation.dart';

class AnyChatUser {
  final String id;
  final String displayName;
  final String email;
  String photoUrl;
  final List<dynamic> conversations;
  String language;

  AnyChatUser(this.id, this.displayName, this.email, this.photoUrl,
      this.language, this.conversations);

  AnyChatUser.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        displayName = snapshot.data()['displayName'],
        email = snapshot.data()['email'],
        photoUrl = snapshot.data()['photoUrl'],
        language = snapshot.data()['language'],
        conversations = snapshot.data()['conversations'];

  static Future<void> createConversation() async {
    final convo =
        await FirebaseFirestore.instance.collection("conversations").add({
      'participants': [AnyChatApp.chatter.id, AnyChatAuth.currentUser.id],
      'messages': new List<String>()
    });
    final user = await FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    final chatter = await FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatApp.chatter.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        fresh.conversations.add(convo.id);
        transaction.update(user, {'conversations': fresh.conversations});
      });
    });
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(chatter)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        fresh.conversations.add(convo.id);
        transaction.update(chatter, {'conversations': fresh.conversations});
      });
    });
    convo.get().then((value) => print(value.id));
    print(convo.id);
    ChatWindow.currentConversation =
        Conversation.fromSnapshot(await convo.get());
    //ChatWindow.currentConversation = Conversation.fromSnapshot(await convo.get());
    // return FirebaseFirestore.instance.runTransaction((Transaction transaction) {
    //   return transaction
    //       .get(convo)
    //       .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
    //       .then((Conversation fresh) async {
    //         fresh.messages.add(message);
    //         transaction.update(convo, {
    //           'messages' : fresh.messages
    //         });
    //         //return Conversation.fromSnapshot(await convo.get());
    //
    //     // final newRatings = fresh.numRatings + 1;
    //     // final newAverage =
    //     //     ((fresh.numRatings * fresh.avgRating) + review.rating) / newRatings;
    //
    //     // transaction.update(convo, {
    //     //   'numRatings': newRatings,
    //     //   'avgRating': newAverage,
    //     // });
    //
    //     // transaction.set(newReview, {
    //     //   'rating': review.rating,
    //     //   'text': review.text,
    //     //   'userName': review.userName,
    //     //   'timestamp': review.timestamp ?? FieldValue.serverTimestamp(),
    //     //   'userId': review.userId,
    //     // });
    //
    //   });
    //});
  }

  addUserToFirestore() {
    FirebaseAuth.instance;

    final users = FirebaseFirestore.instance.collection("users").doc(this.id);
    // if(!checkExist(this.id)){
    //   users.set({
    //     'displayName': displayName,
    //     'email': email,
    //     'photoUrl': photoUrl,
    //     'language': locale.currentLocale,
    //     'conversations': new List<String>()
    //   });
    // }
    checkExist(this.id).then((value) => {
          if (!value)
            {
              //print('!value')

              users.set({
                'displayName': displayName,
                'email': email,
                'photoUrl': photoUrl,
                'language': locale.currentLocale.substring(0, 2),
                'conversations': new List<String>()
              })
            }
        });
  }

  static Future<bool> checkExist(String id) async {
    bool exists = false;
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .get()
          .then((doc) {
        if (doc.exists)
          exists = true;
        else
          exists = false;
      });
      return exists;
    } catch (e) {
      return false;
    }
  }

  static Future<void> addMessageToConversation(AnyChatMessage message) async {
    // final messages = FirebaseFirestore.instance.collection("conversations").doc(ChatWindow.currentConversation.id).collection("messages").doc().get().then((DocumentSnapshot value) =>
    // {
    //
    // });
    final conversation = FirebaseFirestore.instance
        .collection("conversations")
        .doc(ChatWindow.currentConversation.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
        fresh.messages.add({
          'timeStamp': message.timeStamp.toString(),
          'sender': message.sender.id,
          'text': message.text
        });
        //fresh.messages.putIfAbsent(message.sender.id, message.text.toString);
        transaction.update(conversation, {'messages': fresh.messages});
      });
    });
  }

  static Future<void> updatePhotoUrl(String photoUrl) async {
    AnyChatAuth.currentUser.photoUrl = photoUrl;
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        //fresh.messages.putIfAbsent(message.sender.id, message.text.toString);
        transaction.update(user, {'photoUrl': photoUrl});
      });
    });
  }
// static Stream<QuerySnapshot> findUserByEmail(String email) {
//     return ;
// }

}
