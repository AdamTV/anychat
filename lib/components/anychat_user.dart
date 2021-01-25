import 'package:anychat/components/locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'anychat_auth.dart';

class AnyChatUser {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  String language;

  AnyChatUser(this.id, this.displayName, this.email, this.photoUrl);

  addUserToFirestore() async {
    FirebaseAuth.instance;

    final users = FirebaseFirestore.instance.collection("users").doc(this.id);
    checkExist(this.id).then((value) => {
      if(!value){
        //print('!value')

        users.set({
          'displayName': displayName,
          'email' : email,
          'photoUrl' : photoUrl,
          'language' : locale.currentLocale
        })
      }
    });
  }

  static Future<bool> checkExist(String id) async {
    bool exists = false;
    try {
      await FirebaseFirestore.instance.collection("users").doc(id)
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

  // static Stream<QuerySnapshot> findUserByEmail(String email) {
  //     return ;
  // }


}
