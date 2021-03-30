import 'package:anychat/Screens/chat_screen.dart';
import 'package:anychat/Screens/conversations_screen.dart';
import 'package:anychat/components/locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_speech/generated/google/protobuf/any.pb.dart';

import 'ConversationInfo.dart';
import 'anychat_auth.dart';
import 'anychat_auth.dart';
import 'conversation.dart';

class AnyChatUser {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String language;
  List<ConversationInfo> conversations = [];

  AnyChatUser(
      this.id, this.displayName, this.email, this.photoUrl, this.language);

  AnyChatUser.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        id = snapshot.id,
        displayName = snapshot.data()['displayName'],
        email = snapshot.data()['email'],
        photoUrl = snapshot.data()['photoUrl'],
        language = snapshot.data()['language'];

  static Future<AnyChatUser> findUserById(String id) async {
    return AnyChatUser.fromSnapshot(
        await FirebaseFirestore.instance.collection("users").doc(id).get());
  }

  static Future<Conversation> createConversation(String id) async {
    final conversation =
        await FirebaseFirestore.instance.collection("conversations").add({
      'participants': [id, AnyChatAuth.currentUser.id],
      'timestamp': FieldValue.serverTimestamp()
    });
    ChatWindow.currentConversation =
        Conversation.fromSnapshot(await conversation.get());
    final currentUser = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    final userConversationInfo =
        currentUser.collection("conversations").doc(conversation.id);
    final chatter = FirebaseFirestore.instance.collection("users").doc(id);
    var user = AnyChatUser.fromSnapshot(await chatter.get());
    final chatterConversationInfo =
        chatter.collection("conversations").doc(conversation.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(currentUser)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        transaction.set(userConversationInfo, {
          'incomingLanguage': AnyChatAuth.currentUser.language,
          'outgoingLanguage': user.language,
        });
      });
    });
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(chatter)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        transaction.set(chatterConversationInfo, {
          'incomingLanguage': user.language,
          'outgoingLanguage': AnyChatAuth.currentUser.language,
        });
      });
    });
    AnyChatAuth.currentUser.conversations
        .add(ConversationInfo.fromSnapshot(await userConversationInfo.get()));
    conversation.get().then((value) => print(value.id));
    print(conversation.id);
    return Conversation.fromSnapshot(await conversation.get());
  }

  addUserToFirestore() {
    FirebaseAuth.instance;

    final users = FirebaseFirestore.instance.collection("users").doc(this.id);
    checkExist(this.id).then((value) => {
          if (!value)
            {
              //print('!value')

              users.set({
                'displayName': displayName,
                'email': email,
                'photoUrl': photoUrl,
                'language': Locale.currentLocale.substring(0, 2),
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
    final userConversation = FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection("conversations")
        .doc(conversationId);
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
      transaction.delete(userConversation);
      return;
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
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'photoUrl': photoUrl});
      });
    });
    AnyChatAuth.currentUser = await findUserById(AnyChatAuth.currentUser.id);
  }

  static Future<void> updateLanguage(String language) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'language': language});
      });
    });
    AnyChatAuth.currentUser = await findUserById(AnyChatAuth.currentUser.id);
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

  static Future<void> addUserToConversation(AnyChatUser user) async {
    final conversation = FirebaseFirestore.instance
        .collection('conversations')
        .doc(ChatWindow.currentConversation.id);
    final newMessage = conversation.collection('messages').doc();
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) {
        fresh.participants.add(user.id);
        transaction.update(conversation, {'participants': fresh.participants});
        transaction.set(newMessage, {
          'timestamp': FieldValue.serverTimestamp(),
          'senderId': AnyChatAuth.currentUser.id,
          'text':
              "${AnyChatAuth.currentUser.displayName} has added ${user.displayName} to the conversation.",
        });
      });
    });
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.id)
        .collection("conversations")
        .doc(conversation.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(ref)
          .then((DocumentSnapshot doc) => ConversationInfo.fromSnapshot(doc))
          .then((ConversationInfo fresh) {
        transaction.set(ref, {
          'incomingLanguage': user.language,
          'outgoingLanguage': AnyChatAuth.currentUser.language
        });
      });
    });
  }

  static deleteConversation(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Conversation"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Are you sure you want to leave this conversation? "
                    "You will not be able to join back unless somebody "
                    "invites you."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                    msg: "Cancelled",
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 3,
                    backgroundColor: Colors.red,
                    textColor: Theme.of(context).primaryColorLight,
                    fontSize: 16.0);
              },
            ),
            TextButton(
              child: Text('Approve'),
              onPressed: () {
                if (AnyChatAuth.currentUser.conversations != null) {
                  AnyChatAuth.currentUser.conversations
                      .removeWhere((element) => element.id == id);
                }
                Navigator.of(context).pop();
                ChatWindow.currentConversation = null;
                AnyChatAuth.currentUser.leaveConversation(id);
                Fluttertoast.showToast(
                    msg: "Successfully left conversation",
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 3,
                    backgroundColor: Colors.red,
                    textColor: Theme.of(context).primaryColorLight,
                    fontSize: 16.0);
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConversationsScreen()));
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConversationsScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  static Future<AnyChatUser> findUserByEmail(String email) async {
    AnyChatUser user;
    await FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) => {
      querySnapshot.docs.forEach((doc) {
        if (doc['email'] == email) {
          user = AnyChatUser(
              doc.id,
              doc["displayName"],
              doc["email"],
              doc["photoUrl"],
              doc["language"]);
          print(doc["displayName"]);
        }
      }),
    });
    return user;
  }

// static Stream<QuerySnapshot> findUserByEmail(String email) {
//     return ;
// }

}
