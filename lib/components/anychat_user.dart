import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'anychat_auth.dart';
import 'conversation.dart';
import 'conversation_info.dart';

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

  static Future<AnyChatUser> getUserById(String id) async {
    return AnyChatUser.fromSnapshot(
        await FirebaseFirestore.instance.collection("users").doc(id).get());
  }

  static Future<Conversation> createConversation(String id) async {
    if (id == AnyChatAuth.currentUser.id) {
      Utilities.showToast(AppLocalizations.of(Utilities.globalKey.currentContext)
              .canNotCreateConvoWithSelf);
      return null;
    }
    final conversation =
        await FirebaseFirestore.instance.collection("conversations").add({
      'participants': [id, AnyChatAuth.currentUser.id],
      'timestamp': FieldValue.serverTimestamp()
    });
    AnyChatAuth.currentConversation =
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
                'language': AnyChatLocale.currentLocale.substring(0, 2),
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
        .doc(AnyChatAuth.currentConversation.id);
    final newMessage = conversation.collection('messages').doc();

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
            transaction.update(conversation,
                {'timestamp': FieldValue.serverTimestamp()});
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
    try {
      await FirebaseFirestore.instance
          .runTransaction((Transaction transaction) {
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
          transaction
              .update(conversation, {'participants': fresh.participants});
          transaction.set(newMessage, {
            'timestamp': FieldValue.serverTimestamp(),
            'senderId': AnyChatAuth.currentUser.id,
            'text': AppLocalizations.of(Utilities.globalKey.currentContext)
                .thisPersonHasLeftConversation,
          });
        });
      });
    } catch (e) {
      print(e);
    }
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
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
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
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
  }

  static Future<void> updateDisplayName(String displayName) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'displayName': displayName});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
  }

  static Future<void> updateEmail(String email) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'email': email});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
  }

  static Future<void> addTranscribedMessage(String text) async {
    final conversation = FirebaseFirestore.instance
        .collection("conversations")
        .doc(AnyChatAuth.currentConversation.id);
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
        .doc(AnyChatAuth.currentConversation.id)
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
    //     .doc(AnyChatAuth.currentConversation.id)
    //     .collection('transcribedMessages').doc(id).delete()
    //     .then((value) => print("Messages Deleted for ${AnyChatAuth.currentConversation.id}"))
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

  static Future<bool> addUserToConversation(AnyChatUser user) async {
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(AnyChatAuth.currentConversation.id);
    final conversation = Conversation.fromSnapshot(await conversationRef.get());
    if (conversation.participants.contains(user.id)) {
      Utilities.showToast(
          "${user.displayName} ${AppLocalizations.of(Utilities.globalKey.currentContext).isAlreadyInThisConversation}");
      return false;
    }
    final newMessage = conversationRef.collection('messages').doc();
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversationRef)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) {
        fresh.participants.add(user.id);
        transaction
            .update(conversationRef, {'participants': fresh.participants});
        transaction.set(newMessage, {
          'timestamp': FieldValue.serverTimestamp(),
          'senderId': AnyChatAuth.currentUser.id,
          'text':
              "${AnyChatAuth.currentUser.displayName} ${AppLocalizations.of(Utilities.globalKey.currentContext).hasAdded} ${user.displayName} ${AppLocalizations.of(Utilities.globalKey.currentContext).toTheConversation}",
        });
      });
    });
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.id)
        .collection("conversations")
        .doc(conversationRef.id);
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
    return true;
  }

  static deleteConversation(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).deleteConversation),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context).areYouSureYouWantToLeave +
                    " " +
                    AppLocalizations.of(context)
                        .youWillNotJoinBackUnlessInvited),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
                Utilities.showToast(AppLocalizations.of(context).cancelled);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context).approve),
              onPressed: () {
                if (AnyChatAuth.currentUser.conversations != null) {
                  AnyChatAuth.currentUser.conversations
                      .removeWhere((element) => element.id == id);
                }
                Navigator.of(context).pop();
                AnyChatAuth.currentConversation = null;
                AnyChatAuth.currentUser.leaveConversation(id);
                Utilities.showToast(
                    AppLocalizations.of(context).successfullyLeftConversation);
                Navigator.pushReplacementNamed(context, "/conversations");
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
                  user = AnyChatUser(doc.id, doc["displayName"], doc["email"],
                      doc["photoUrl"], doc["language"]);
                  print(doc["displayName"]);
                }
              }),
            });
    return user;
  }

  Future<void> deleteAccount() async {
    var convos = await ConversationInfo.getAllConversationInfo(id);
    convos.forEach((element) async {
      await leaveConversation(element.id);
    });
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      transaction
          .delete(FirebaseFirestore.instance.collection('users').doc(id));
      return;
    });
    Navigator.pushReplacementNamed(Utilities.globalKey.currentContext, '/');
    Utilities.showToast(AppLocalizations.of(Utilities.globalKey.currentContext).accountDeleted);
  }

// static Stream<QuerySnapshot> findUserByEmail(String email) {
//     return ;
// }

}
