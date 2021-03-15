import 'package:anychat/Screens/Chat/components/chat.dart';
import 'package:anychat/components/locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'anychat_auth.dart';
import 'conversation.dart';

class AnyChatUser {
  final String id;
  final String displayName;
  final String email;
  String photoUrl;
  final List<String> conversationIds;
  String language;

  AnyChatUser(this.id, this.displayName, this.email, this.photoUrl,
      this.language, this.conversationIds);

  AnyChatUser.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        displayName = snapshot.data()['displayName'],
        email = snapshot.data()['email'],
        photoUrl = snapshot.data()['photoUrl'],
        language = snapshot.data()['language'],
        conversationIds =
            List.castFrom<dynamic, String>(snapshot.data()['conversationIds']);

  static Future<AnyChatUser> findUserById(String id) async {
    return AnyChatUser.fromSnapshot(
        await FirebaseFirestore.instance.collection("users").doc(id).get());
  }

  static Future<void> createConversation() async {
    final conversation =
        await FirebaseFirestore.instance.collection("conversations").add({
      'participants': [AnyChatApp.chatter.id, AnyChatAuth.currentUser.id],
      'timestamp': FieldValue.serverTimestamp()
    });
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    final chatter = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatApp.chatter.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        fresh.conversationIds.add(conversation.id);
        transaction.update(user, {'conversationIds': fresh.conversationIds});
      });
    });
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(chatter)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        fresh.conversationIds.add(conversation.id);
        transaction.update(chatter, {'conversationIds': fresh.conversationIds});
      });
    });
    conversation.get().then((value) => print(value.id));
    print(conversation.id);
    ChatWindow.currentConversation =
        Conversation.fromSnapshot(await conversation.get());
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
    //     'conversationIds': <String>[]
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
                'language': Locale.currentLocale.substring(0, 2),
                'conversationIds': <String>[],
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

  static Future<String> addMessageToConversation(String text) async {
    final conversation = FirebaseFirestore.instance
        .collection("conversations")
        .doc(ChatWindow.currentConversation.id);
    final newMessage = conversation.collection('messages').doc();

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
        transaction.set(newMessage, {
          'timestamp': FieldValue.serverTimestamp(),
          'senderId': AnyChatAuth.currentUser.id,
          'text': text,
        });
      });
    });
    return newMessage.id;
  }

  Future<void> leaveConversation(String conversationId) async {
    final conversation = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    final newMessage = conversation.collection('messages').doc();
    // final message = conversation.collection("messages").doc();
    // final ref = await message.get();
    final user = FirebaseFirestore.instance.collection('users').doc(id);
    // await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
    //   return transaction
    //       .get(message)
    //       .then((DocumentSnapshot doc) => AnyChatMessage.fromSnapshot(doc))
    //       .then((AnyChatMessage fresh) {
    //       .then((AnyChatMessage fresh) {
    //
    //     // AnyChatMessage msg = AnyChatMessage(message.id, FieldValue.serverTimestamp(), id, "This person has left the conversation.", ref.reference);
    //     transaction.update(message, {'participants': fresh.participants});
    //   });
    // });
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        fresh.conversationIds
            .removeWhere((element) => element == conversationId);
        transaction.update(user, {'conversationIds': fresh.conversationIds});
      });
    });
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
        fresh.participants.removeWhere((element) => element == id);
        if (fresh.participants.isEmpty) {
          transaction.delete(conversation);
          await conversation.delete();
          return;
        }
        transaction.update(conversation, {'participants': fresh.participants});
        transaction.set(newMessage, {
          'timestamp': FieldValue.serverTimestamp(),
          'senderId': AnyChatAuth.currentUser.id,
          'text': "This person has left the conversation.",
        });
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

  static Future<void> addTranscribedMessage(String text) async {
    final conversation = FirebaseFirestore.instance
        .collection("conversations")
        .doc(ChatWindow.currentConversation.id);
    final newMessage = conversation.collection('transcribedMessages').doc();
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
        transaction.set(newMessage, {
          'timestamp': FieldValue.serverTimestamp(),
          'senderId': AnyChatAuth.currentUser.id,
          'text': text,
        });
      });
    });
    // await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
    //   return transaction
    //       .get(conversation)
    //       .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
    //       .then((Conversation fresh) async {
    //     final transcribedMessages = fresh.transcribedMessages == null
    //         ? <dynamic>[]
    //         : fresh.transcribedMessages;
    //     transcribedMessages.add({
    //       'timeStamp': DateTime.now(),
    //       'sender': AnyChatAuth.currentUser.id,
    //       'text': text
    //     });
    //     //fresh.messages.putIfAbsent(message.sender.id, message.text.toString);
    //     transaction
    //         .update(conversation, {'transcribedMessages': transcribedMessages});
    //   });
    // });
  }

  static Future<void> clearTranscribedMessages() {
    final messages = FirebaseFirestore.instance
        .collection('conversations')
        .doc(ChatWindow.currentConversation.id)
        .collection('transcribedMessages');
    WriteBatch batch = FirebaseFirestore.instance.batch();
    return messages.get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        batch.delete(doc.reference);
      });
      return batch.commit();
    });
    // return FirebaseFirestore.instance
    //     .collection("conversations")
    //     .doc(ChatWindow.currentConversation.id)
    //     .collection('transcribedMessages').doc(id).delete()
    //     .then((value) => print("Messages Deleted for ${ChatWindow.currentConversation.id}"))
    //     .catchError((error) => print("Failed to delete messages: $error"));
    // await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
    //   return transaction
    //       .get(conversation)
    //       .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
    //       .then((Conversation fresh) {
    //         transaction.delete(transcribedMessages);
    //   });
    // });
    // await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
    //   return transaction
    //       .get(conversation)
    //       .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
    //       .then((Conversation fresh) async {
    //     final transcribedMessages = <dynamic>[];
    //
    //     //fresh.messages.putIfAbsent(message.sender.id, message.text.toString);
    //     transaction
    //         .update(conversation, {'transcribedMessages': transcribedMessages});
    //   });
    // });
  }

// static Stream<QuerySnapshot> findUserByEmail(String email) {
//     return ;
// }

}
