import 'dart:async';

import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_maanger.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'anychat_auth.dart';
import 'conversation.dart';
import 'conversation_info.dart';

class AnyChatUser {
  late String id;
  late String displayName = '';
  late final String email;
  late String photoUrl = '';
  late final String language;
  late final List<String> blockedAccounts;
  List<ConversationInfo> conversations = [];
  late String theme;
  late bool notificationsEnabled;

  AnyChatUser(
      this.id,
      this.displayName,
      this.email,
      this.language,
      this.photoUrl,
      this.theme,
      this.notificationsEnabled,
      this.blockedAccounts);

  static AnyChatUser deletedUser(String uid) {
    return AnyChatUser(
        uid,
        AppLocalizations.of(Utilities().globalKey.currentContext!)!
            .accountDeleted,
        "",
        "",
        "",
        "",
        false,
        []);
  }

  AnyChatUser.fromSnapshot(DocumentSnapshot snapshot) : id = snapshot.id {
    final data = snapshot.data();
    if (data != null) {
      displayName = (snapshot.data() as Map<String, dynamic>)['displayName'];
      email = (snapshot.data() as Map<String, dynamic>)['email'];
      photoUrl = (snapshot.data() as Map<String, dynamic>)['photoUrl'] ?? '';
      language = (snapshot.data() as Map<String, dynamic>)['language'];
      blockedAccounts = List.castFrom<dynamic, String>(
          (snapshot.data() as Map<String, dynamic>)['blockedAccounts'] ?? []);
      theme = (snapshot.data() as Map<String, dynamic>)['theme'] ?? 'system';
      notificationsEnabled =
          (snapshot.data() as Map<String, dynamic>)['notificationsEnabled'] ??
              false;
    }
  }

  static Future<AnyChatUser> getUserById(String? id) async {
    return AnyChatUser.fromSnapshot(
        await FirebaseFirestore.instance.collection("users").doc(id).get());
  }

  static Future<Conversation?> createConversation(AnyChatUser user) async {
    final chatter = FirebaseFirestore.instance.collection("users").doc(user.id);

    if (user.id == AnyChatAuth.currentUser!.id) {
      Utilities().showToast(
          AppLocalizations.of(Utilities().globalKey.currentContext!)!
              .canNotCreateConvoWithSelf);
      return null;
    }
    final conversation =
        await FirebaseFirestore.instance.collection("conversations").add({
      'participants': [user.id, AnyChatAuth.currentUser!.id],
      'timestamp': FieldValue.serverTimestamp()
    });
    AnyChatAuth.currentConversation =
        Conversation.fromSnapshot(await conversation.get());
    final currentUser = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser!.id);
    final userConversationInfo =
        currentUser.collection("conversations").doc(conversation.id);
    final chatterConversationInfo =
        chatter.collection("conversations").doc(conversation.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(currentUser)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) async {
        transaction.set(userConversationInfo, {
          'incomingLanguage': AnyChatAuth.currentUser!.language,
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
          'outgoingLanguage': AnyChatAuth.currentUser!.language,
        });
      });
    });
    AnyChatAuth.currentUser!.conversations
        .add(ConversationInfo.fromSnapshot(await userConversationInfo.get()));
    conversation.get().then((value) => logger.d(value.id));
    logger.d(conversation.id);

    AnyChatAuth.currentConversation =
        Conversation.fromSnapshot(await conversation.get());
    List<AnyChatUser> temp = <AnyChatUser>[];
    for (var id in AnyChatAuth.currentConversation!.participants) {
      if (id != AnyChatAuth.currentUser!.id) {
        temp.add(AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get()));
      }
      AnyChatAuth.currentChatters = temp;
    }
    return AnyChatAuth.currentConversation!;
  }

  addUserToFirestore() {
    FirebaseAuth.instance;

    final users = FirebaseFirestore.instance.collection("users").doc(id);
    checkExist(id).then((value) => {
          if (!value)
            {
              //logger.d('!value')

              users.set({
                'displayName': displayName,
                'email': email,
                'photoUrl': photoUrl,
                'language': AnyChatLocale.currentLocale!.substring(0, 2),
              })
            }
          else
            {
              Utilities().showToast(
                  AppLocalizations.of(Utilities().globalKey.currentContext!)!
                      .pleaseLoginInstead)
            }
        });
  }

  static Future<bool> checkExist(String? id) async {
    bool exists = false;
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .get()
          .then((doc) {
        if (doc.exists) {
          exists = true;
        } else {
          exists = false;
        }
      });
      return exists;
    } catch (e) {
      return false;
    }
  }

  static Future<void> addMessageToConversation(String text) async {
    return await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) {
      return transaction
          .get(FirebaseFirestore.instance
              .collection("conversations")
              .doc(AnyChatAuth.currentConversation!.id))
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
        transaction.update(
            FirebaseFirestore.instance
                .collection("conversations")
                .doc(AnyChatAuth.currentConversation!.id),
            {'timestamp': FieldValue.serverTimestamp()});
        transaction.set(
            FirebaseFirestore.instance
                .collection("conversations")
                .doc(AnyChatAuth.currentConversation!.id)
                .collection('messages')
                .doc(),
            {
              'timestamp': FieldValue.serverTimestamp(),
              'senderId': AnyChatAuth.currentUser!.id,
              'text': text,
            });
      });
    });
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
    } as Future Function(Transaction));
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
            'senderId': AnyChatAuth.currentUser!.id,
            'text': AppLocalizations.of(Utilities().globalKey.currentContext!)!
                .thisPersonHasLeftConversation,
          });
        });
      });
    } catch (e) {
      logger.d(e);
    }
  }

  static Future<void> updatePhotoUrl(String? photoUrl) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser!.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'photoUrl': photoUrl});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser!.id);
  }

  static Future<void> updateLanguage(String language) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser!.id);
    FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'language': language});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser!.id);
    var userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser!.id);
    userData.locale = UserData.localeFromString(language);
    await CacheManager().cacheUserData(userData);
  }

  static Future<void> updateDisplayName(String? displayName) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser!.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'displayName': displayName});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser!.id);
  }

  static Future<void> updateEmail(String email) async {
    Utilities().showToast("Please verify your email");
    var acs = ActionCodeSettings(
      // URL you want to redirect back to. The domain (www.example.com) for this
      // URL must be whitelisted in the Firebase Console.
        url: 'https://app.anychat.ca/__/auth/action',
        // This must be true
        handleCodeInApp: true,
        iOSBundleId: 'ca.alphatech.anychat',
        androidPackageName: 'ca.alphatech.anychat',
        // installIfNotAvailable
        androidInstallApp: true,
        // minimumVersion
        androidMinimumVersion: '12');
    FirebaseAuth.instance.currentUser
        ?.sendEmailVerification(acs)
        .then((value) async => {
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                return transaction
                    .get(FirebaseFirestore.instance
                        .collection("users")
                        .doc(AnyChatAuth.currentUser!.id))
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) {
                  transaction.update(
                      FirebaseFirestore.instance
                          .collection("users")
                          .doc(AnyChatAuth.currentUser!.id),
                      {'email': email, 'emailVerified': true});
                });
              }),
              AnyChatAuth.currentUser =
                  await getUserById(AnyChatAuth.currentUser!.id)
            });
  }

  static Future<void> addTranscribedMessage(String text) async {
    logger.d(AnyChatAuth.currentUser!.id);
    final conversation = FirebaseFirestore.instance
        .collection("conversations")
        .doc(AnyChatAuth.currentConversation!.id);
    final newMessage = conversation.collection('transcribedMessages').doc();
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(conversation)
          .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
          .then((Conversation fresh) async {
        transaction.set(newMessage, {
          'timestamp': FieldValue.serverTimestamp(),
          'senderId': AnyChatAuth.currentUser!.id,
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
        .doc(AnyChatAuth.currentConversation!.id)
        .collection('transcribedMessages');
    WriteBatch batch = FirebaseFirestore.instance.batch();
    return messages.get().then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      return batch.commit();
    });
    // return FirebaseFirestore.instance
    //     .collection("conversations")
    //     .doc(AnyChatAuth.currentConversation.id)
    //     .collection('transcribedMessages').doc(id).delete()
    //     .then((value) => logger.d("Messages Deleted for ${AnyChatAuth.currentConversation.id}"))
    //     .catchError((error) => logger.d("Failed to delete messages: $error"));
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
        .doc(AnyChatAuth.currentConversation!.id);
    final conversation = Conversation.fromSnapshot(await conversationRef.get());
    if (conversation.participants.contains(user.id)) {
      Utilities().showToast(
          "${user.displayName} ${AppLocalizations.of(Utilities().globalKey.currentContext!)!.isAlreadyInThisConversation}");
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
          'senderId': AnyChatAuth.currentUser!.id,
          'text':
              "${AnyChatAuth.currentUser!.displayName} ${AppLocalizations.of(Utilities().globalKey.currentContext!)!.hasAdded} ${user.displayName} ${AppLocalizations.of(Utilities().globalKey.currentContext!)!.toTheConversation}",
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
          'outgoingLanguage': AnyChatAuth.currentUser!.language
        });
      });
    });
    AnyChatAuth.currentChatters.add(user);
    return true;
  }

  static deleteConversation(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteConversation),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "${AppLocalizations.of(context)!.areYouSureYouWantToLeave} ${AppLocalizations.of(context)!.youWillNotJoinBackUnlessInvited}"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                NavigationService().goBack();
                Utilities().showToast(AppLocalizations.of(context)!.cancelled);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.approve),
              onPressed: () {
                AnyChatAuth.currentUser!.conversations
                    .removeWhere((element) => element.id == id);
                NavigationService().goBack();
                AnyChatAuth.currentConversation = null;
                AnyChatAuth.currentUser!.leaveConversation(id);
                Utilities().showToast(
                    AppLocalizations.of(context)!.successfullyLeftConversation);
                NavigationService().pushNamedAndRemoveUntil("/conversations",
                    predicate: (Route<dynamic> route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<AnyChatUser?> findUserByEmail(String? email) async {
    AnyChatUser? user;
    await FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              for (final doc in querySnapshot.docs)
                {
                  if (doc['email'] == email)
                    {
                      user = AnyChatUser.fromSnapshot(doc),
                      logger.d(doc["displayName"])
                    }
                }
            });
    return user;
  }

  static Future<List<AnyChatUser>> findUsersByEmail(String? email) async {
    List<AnyChatUser> users = [];
    await FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              for (final doc in querySnapshot.docs)
                {
                  if (email != null &&
                      doc['email']
                          .toString()
                          .toLowerCase()
                          .contains(email.toLowerCase()))
                    {
                      users.add(AnyChatUser.fromSnapshot(doc)),
                      logger.d(doc["displayName"])
                    }
                }
            });
    return users;
  }

  static Future<List<AnyChatUser>> findUsersByDisplayName(
      String? displayName) async {
    List<AnyChatUser> users = [];
    await FirebaseFirestore.instance
        .collection('users')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              for (final doc in querySnapshot.docs)
                {
                  if (displayName != null &&
                      doc['displayName']
                          .toString()
                          .toLowerCase()
                          .contains(displayName.toLowerCase()))
                    {
                      users.add(AnyChatUser.fromSnapshot(doc)),
                      logger.d(doc["displayName"])
                    }
                }
            });
    return users;
  }

  Future<void> deleteAccount() async {
    var convos = await ConversationInfo.getAllConversationInfo(id);
    for (final element in convos) {
      await leaveConversation(element.id);
    }
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      transaction
          .delete(FirebaseFirestore.instance.collection('users').doc(id));
      return;
    } as Future Function(Transaction));
    Navigator.pushReplacementNamed(Utilities().globalKey.currentContext!, '/');
    Utilities().showToast(
        AppLocalizations.of(Utilities().globalKey.currentContext!)!
            .accountDeleted);
  }

  Future<void> blockAccount(String id) async {
    var user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser!.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        if (!blockedAccounts.contains(id)) blockedAccounts.add(id);
        transaction.update(user, {'blockedAccounts': blockedAccounts});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser!.id);
  }

  Future<void> unblockAccount(String? id) async {
    var user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser!.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        blockedAccounts.removeWhere((element) => element == id);
        transaction.update(user, {'blockedAccounts': blockedAccounts});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser!.id);
  }

  // void addSubscription(
  //     String name,
  //     StreamSubscription<QuerySnapshot<Object?>>? subscription) {
  //   _subscriptions.putIfAbsent(name, subscription as StreamSubscription Function());
  // }
  //
  // void cancelAllSubscriptions() {
  //   _subscriptions.clear(); // Clear the list after canceling all subscriptions
  // }

// static Stream<QuerySnapshot> findUserByEmail(String email) {
//     return ;
// }
}
