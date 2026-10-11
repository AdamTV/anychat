import 'dart:async';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'anychat_auth.dart';
import '../components/combined_locale_info.dart';
import 'conversation.dart';
import 'conversation_info.dart';
import 'firestore_batch.dart';

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

  AnyChatUser(this.id, this.displayName, this.email, this.photoUrl, this.theme,
      this.language, this.notificationsEnabled, this.blockedAccounts);

  static AnyChatUser deletedUser(String uid) {
    return AnyChatUser(
        uid,
        localizationOf(Utilities().globalKey.currentContext!).accountDeleted,
        "",
        "",
        "",
        "",
        false, []);
  }

  AnyChatUser.fromSnapshot(DocumentSnapshot snapshot) : id = snapshot.id {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data != null) {
      displayName = data['displayName'] as String? ?? '';
      email = data['email'] as String? ?? '';
      photoUrl = data['photoUrl'] as String? ?? '';
      language = data['language'] as String? ?? 'en';
      blockedAccounts = List<String>.from(
          data['blockedAccounts'] as List<dynamic>? ?? const <dynamic>[]);
      theme = data['theme'] as String? ?? 'system';
      notificationsEnabled = data['notificationsEnabled'] as bool? ?? false;
    } else {
      displayName = '';
      email = '';
      photoUrl = '';
      language = 'en';
      blockedAccounts = [];
      theme = 'system';
      notificationsEnabled = false;
    }
  }

  static Future<AnyChatUser> getUserById(String? id) async {
    return AnyChatUser.fromSnapshot(
        await FirebaseFirestore.instance.collection("users").doc(id).get());
  }

  /// Fetches users with bounded `whereIn` queries rather than one document
  /// read per ID.
  static Future<List<AnyChatUser>> getUsersByIds(Iterable<String> ids) async {
    final uniqueIds = ids.toSet();
    if (uniqueIds.isEmpty) {
      return <AnyChatUser>[];
    }

    final users = <AnyChatUser>[];
    for (final idBatch in chunkForFirestoreInQuery(uniqueIds)) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: idBatch)
          .get();
      users.addAll(snapshot.docs.map(AnyChatUser.fromSnapshot));
    }
    return users;
  }

  static Future<Conversation?> createConversation(AnyChatUser user) async {
    final chatter = FirebaseFirestore.instance.collection("users").doc(user.id);

    if (user.id == AnyChatAuth.currentUser.id) {
      Utilities().showToast(
          localizationOf(Utilities().globalKey.currentContext!)
              .canNotCreateConvoWithSelf);
      return null;
    }
    final conversation =
        await FirebaseFirestore.instance.collection("conversations").add({
      'participants': [user.id, AnyChatAuth.currentUser.id],
      'timestamp': FieldValue.serverTimestamp()
    });
    AnyChatAuth.currentConversation =
        Conversation.fromSnapshot(await conversation.get());
    final currentUser = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
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
    conversation.get().then((value) => logger.d(value.id));
    logger.d(conversation.id);

    AnyChatAuth.currentConversation =
        Conversation.fromSnapshot(await conversation.get());
    final currentUserId = AnyChatAuth.currentUser.id;
    AnyChatAuth.currentChatters = await getUsersByIds(
      AnyChatAuth.currentConversation!.participants
          .where((participantId) => participantId != currentUserId),
    );
    return AnyChatAuth.currentConversation!;
  }

  Future<void> addUserToFirestore() async {
    FirebaseAuth.instance;

    var locale = await Devicelocale.currentAsLocale;
    String localeStr = locale?.languageCode ?? localeName;

    final users = FirebaseFirestore.instance.collection("users").doc(id);
    checkExist(id).then((value) => {
          if (!value)
            {
              //logger.d('!value')
              users.set({
                'displayName': displayName,
                'email': email,
                'photoUrl': photoUrl,
                'language': localeStr,
              })
            }
          else
            {
              Utilities().showToast(
                  localizationOf(Utilities().globalKey.currentContext!)
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

  static Future<void> addMessageToConversation(String text,
      {String? conversationId}) async {
    return await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) {
      return transaction
          .get(FirebaseFirestore.instance
              .collection("conversations")
              .doc(conversationId ?? AnyChatAuth.currentConversation?.id))
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
              'senderId': AnyChatAuth.currentUser.id,
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
    await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) async {
      transaction.delete(userConversation);
    });
    try {
      await FirebaseFirestore.instance
          .runTransaction((Transaction transaction) {
        return transaction
            .get(conversation)
            .then((DocumentSnapshot doc) => Conversation.fromSnapshot(doc))
            .then((Conversation fresh) async {
          fresh.participants
              .removeWhere((element) => element == AnyChatAuth.currentUser.id);
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
            'text': localizationOf(Utilities().globalKey.currentContext!)
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
    var userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    userData.locale = UserData.localeFromString(language);
    await CacheManager().cacheUserData(userData);
  }

  static Future<void> updateDisplayName(String? displayName) async {
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
    var userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    userData.username = displayName!;
    await CacheManager().cacheUserData(userData);
    await NavigationService().pushNamedAndRemoveUntil('/settings',
        predicate: (Route<dynamic> route) =>
            route.settings.name == '/conversations');
  }

  static Future<void> updateEmail(String email) async {
    Utilities().showToast(localizationOf(null).pleaseVerifyYourEmail);
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
                        .doc(AnyChatAuth.currentUser.id))
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) {
                  transaction.update(
                      FirebaseFirestore.instance
                          .collection("users")
                          .doc(AnyChatAuth.currentUser.id),
                      {'email': email, 'emailVerified': true});
                });
              }),
              AnyChatAuth.currentUser =
                  await getUserById(AnyChatAuth.currentUser.id)
            });
  }

  static Future<void> addTranscribedMessage(String text) async {
    logger.d(AnyChatAuth.currentUser.id);
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
          "${user.displayName} ${localizationOf(Utilities().globalKey.currentContext!).isAlreadyInThisConversation}");
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
              "${AnyChatAuth.currentUser.displayName} ${localizationOf(Utilities().globalKey.currentContext!).hasAdded} ${user.displayName} ${localizationOf(Utilities().globalKey.currentContext!).toTheConversation}",
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
    AnyChatAuth.currentChatters.add(user);
    return true;
  }

  static void deleteConversation(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizationOf(context).deleteConversation),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "${localizationOf(context).areYouSureYouWantToLeave} ${localizationOf(context).youWillNotJoinBackUnlessInvited}"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(localizationOf(context).cancel),
              onPressed: () {
                NavigationService().pop();
                Utilities().showToast(localizationOf(context).cancelled);
              },
            ),
            TextButton(
              child: Text(localizationOf(context).approve),
              onPressed: () {
                AnyChatAuth.currentUser.conversations
                    .removeWhere((element) => element.id == id);
                NavigationService().pop();
                AnyChatAuth.currentConversation = null;
                AnyChatAuth.currentUser.leaveConversation(id);
                Utilities().showToast(
                    localizationOf(context).successfullyLeftConversation);
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
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      var convos = await ConversationInfo.getAllConversationInfo(id);
      for (final element in convos) {
        await leaveConversation(element.id);
      }
      final user = FirebaseFirestore.instance
          .collection("users")
          .doc(AnyChatAuth.currentUser.id);
      await FirebaseFirestore.instance
          .runTransaction((Transaction transaction) {
        return transaction
            .get(user)
            .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
            .then((AnyChatUser fresh) {
          transaction.delete(user);
        });
      });
      AnyChatAuth.currentUser = deletedUser('0');
      NavigationService().pushReplacementNamed('/');
      Utilities().showToast(
          localizationOf(Utilities().globalKey.currentContext!).accountDeleted);
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      if (e.runtimeType == FirebaseAuthException) {
        var a = e as FirebaseAuthException;
        a.code == 'requires-recent-login';
        Utilities().showAlertDialog(
            null,
            localizationOf(Utilities().globalKey.currentContext).approve,
            'Please verify your account by logging in, and then try again.');
        NavigationService().popUntil((p0) => p0.isFirst && p0.isCurrent);
        await NavigationService().pushReplacementNamed('/welcome');
        await AnyChatAuth.signOut();
        return;
      }
    }
  }

  Future<void> blockAccount(String id) async {
    var user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        if (!blockedAccounts.contains(id)) blockedAccounts.add(id);
        transaction.update(user, {'blockedAccounts': blockedAccounts});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
  }

  Future<void> unblockAccount(String? id) async {
    var user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);

    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        blockedAccounts.removeWhere((element) => element == id);
        transaction.update(user, {'blockedAccounts': blockedAccounts});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
  }

  static Future<void> updateTheme(ThemeMode newValue) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'theme': newValue.name});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
    var userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    var newPref = userData.theme.brightness;
    if (newValue == ThemeMode.light) {
      newPref = Brightness.light;
    } else if (newValue == ThemeMode.dark) {
      newPref = Brightness.dark;
    } else {
      newPref = MediaQuery.of(Utilities().globalKey.currentContext!)
          .platformBrightness;
    }
    userData.theme = userData.theme.copyWith(brightness: newPref);
    await CacheManager().cacheUserData(userData);
    // await NavigationService().pushReplacementNamed('/settings');
  }

  static Future<void> updateNotifications(bool value) async {
    final user = FirebaseFirestore.instance
        .collection("users")
        .doc(AnyChatAuth.currentUser.id);
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) {
      return transaction
          .get(user)
          .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
          .then((AnyChatUser fresh) {
        transaction.update(user, {'notificationsEnabled': value});
      });
    });
    AnyChatAuth.currentUser = await getUserById(AnyChatAuth.currentUser.id);
    var userData =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    userData.notificationsEnabled = value;
    await CacheManager().cacheUserData(userData);
    // await NavigationService().pushReplacementNamed('/settings');
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
