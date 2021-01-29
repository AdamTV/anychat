import 'package:anychat/components/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anychat/components/locale.dart';


import 'anychat_user.dart';

class AnyChatAuth {
  static AnyChatUser currentUser;

  //static User _user;
  static final FacebookLogin facebookSignIn = new FacebookLogin();
  static GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      //'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  // static Future<GoogleSignInAccount> signIn() {
  //   return _googleSignIn.signIn();
  // }

//   static Future<AnyChatUser> signUpWithGoogle() async {
//     final FirebaseAuth _auth = FirebaseAuth.instance;
//
//     GoogleSignInAccount googleSignInAccount;
//     GoogleSignInAuthentication googleSignInAuthentication;
//     AuthCredential credential;
//     UserCredential authResult;
//
//     if (!kIsWeb) {
//       //_googleSignIn.signOut();
//       await _googleSignIn.signIn().then((result) async {
//         googleSignInAccount = result;
//         await result.authentication.then((googleKey) async {
//           print("accessToken: " + googleKey.accessToken.toString());
//           print("idToken: " + googleKey.idToken.toString());
//           print("displayName: " + googleSignInAccount.displayName.toString());
//           credential = GoogleAuthProvider.credential(
//             accessToken: googleKey.accessToken,
//             idToken: googleKey.idToken,
//           );
//           authResult = await _auth.signInWithCredential(credential);
//         }).catchError((err) {
//           print('inner error: ' + err.toString());
//         });
//       }).catchError((err) {
//         print('error occurred');
//       });
//
//       currentUser =
//           AnyChatUser(googleSignInAccount.id, googleSignInAccount.displayName,
//               googleSignInAccount.email, googleSignInAccount.photoUrl,
//               locale.currentLocale.substring(0,2), new List<String>());
//       currentUser.addUserToFirestore();
//       return currentUser;
//       //googleSignInAccount = await _googleSignIn.signIn();
//       //googleSignInAuthentication = await googleSignInAccount.authentication;
//     } else {
//       authResult = await _auth.signInWithPopup(GoogleAuthProvider());
//       await _googleSignIn.signInSilently();
//       print(_googleSignIn.currentUser?.id);
//     }
//
//     //final UserCredential authResult =
//     //await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
//     //     await FirebaseAuth.instance.signInWithCredential(credential);
//
//     if (kIsWeb) {} else {
//       // try{
//       // }catch(e){
//       // var anyChatUser = new AnyChatUser(_googleSignIn.currentUser.displayName,
//       //     _googleSignIn.currentUser.email, _googleSignIn.currentUser.photoUrl);
//       // anyChatUser.addUserToFirestore();
//       // return authResult.user;
//       // return null;
//       // }
//     }
//
// //    final User user = null;
//     final _user = authResult.user;
//
//     if (_user != null) {
//       assert(!_user.isAnonymous);
//       assert(await _user.getIdToken() != null);
//
//       final User _authCurrentUser = _auth.currentUser;
//       assert(_user.uid == _authCurrentUser.uid);
//
//       print('signInWithGoogle succeeded: $_user');
//
//       // Using googleSignInAccount for consistency across platforms
//       // TODO: use authResult user instead?
//       currentUser = new AnyChatUser(
//           _user.providerData[0].uid, _user.displayName,
//           _user.email, _user.photoURL, locale.currentLocale,
//           new List<String>());
//       // var anyChatUser = new AnyChatUser(
//       //     currentUser.uid,
//       //     currentUser.displayName, currentUser.email, currentUser.photoURL);
//       currentUser.addUserToFirestore();
//
//       return currentUser;
//     }
//
//     return null;
//   }
  static Future<AnyChatUser> signInWithGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    GoogleSignInAccount googleSignInAccount;
    GoogleSignInAuthentication googleSignInAuthentication;
    AuthCredential credential;
    UserCredential authResult;

    if (!kIsWeb) {
      //_googleSignIn.signOut();
      await _googleSignIn.signIn().then((result) async {
        googleSignInAccount = result;
        await result.authentication.then((googleKey) async {
          print("accessToken: " + googleKey.accessToken.toString());
          print("idToken: " + googleKey.idToken.toString());
          print("displayName: " + googleSignInAccount.displayName.toString());
          credential = GoogleAuthProvider.credential(
            accessToken: googleKey.accessToken,
            idToken: googleKey.idToken,
          );
          authResult = await _auth.signInWithCredential(credential);
        }).catchError((err) {
          print('inner error: ' + err.toString());
        });
      }).catchError((err) {
        print('error occurred');
      });
      var snapshot = await FirebaseFirestore.instance.collection("users").doc(googleSignInAccount.id).get();
      if(snapshot.exists){
        currentUser = AnyChatUser.fromSnapshot(snapshot);
        return currentUser;
      }else{
        currentUser = new AnyChatUser(
            googleSignInAccount.id, googleSignInAccount.displayName,
            googleSignInAccount.email, googleSignInAccount.photoUrl, locale.currentLocale.substring(0,2),
            new List<String>());
        currentUser.addUserToFirestore();

        return currentUser;
      }
      //googleSignInAccount = await _googleSignIn.signIn();
      //googleSignInAuthentication = await googleSignInAccount.authentication;
    } else {
      authResult = await _auth.signInWithPopup(GoogleAuthProvider());
      await _googleSignIn.signInSilently();
      print(_googleSignIn.currentUser?.id);
    }

    //final UserCredential authResult =
    //await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    //     await FirebaseAuth.instance.signInWithCredential(credential);

    if (kIsWeb) {} else {
      // try{
      // }catch(e){
      // var anyChatUser = new AnyChatUser(_googleSignIn.currentUser.displayName,
      //     _googleSignIn.currentUser.email, _googleSignIn.currentUser.photoUrl);
      // anyChatUser.addUserToFirestore();
      // return authResult.user;
      // return null;
      // }
    }

//    final User user = null;
    final _user = authResult.user;

    if (_user != null) {
      assert(!_user.isAnonymous);
      assert(await _user.getIdToken() != null);

      final User _authCurrentUser = _auth.currentUser;
      assert(_user.uid == _authCurrentUser.uid);

      print('signInWithGoogle succeeded: $_user');

      // Using googleSignInAccount for consistency across platforms
      // TODO: use authResult user instead?
      currentUser = new AnyChatUser(
          _user.providerData[0].uid, _user.displayName,
          _user.email, _user.photoURL, locale.currentLocale,
          new List<String>());
      // var anyChatUser = new AnyChatUser(
      //     currentUser.uid,
      //     currentUser.displayName, currentUser.email, currentUser.photoURL);
      currentUser.addUserToFirestore();

      return currentUser;
    }

    return null;
  }

  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    print("User Signed Out");
  }

  // static GoogleSignIn getGoogleSignIn() {
  //   return _googleSignIn;
  // }

  static Future<AnyChatUser> createAccountEmail(String email, String password,
      String language) async {
    try {
      UserCredential _userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: email,
          password: password);
      var result = _userCredential.user;
      print('result: ' + result.toString());
      AnyChatUser currentU = AnyChatUser(
          result.uid, result.displayName, result.email, result.photoURL,
          language, new List<dynamic>());
      currentUser = currentU;
      currentU.addUserToFirestore();
      return currentU;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      }
    } catch (e) {
      throw(e);
    }
    return null;
  }

  static Future<AnyChatUser> signInEmail(String email, String password) async {
    try {
      UserCredential _userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: email,
          password: password);
      var result = _userCredential.user;
      AnyChatUser currentU = AnyChatUser.fromSnapshot(
          await FirebaseFirestore.instance.collection("users")
              .doc(result.uid)
              .get());
      currentUser = currentU;
      currentU.addUserToFirestore();
      return currentU;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  static Future<AnyChatUser> signInFacebook() async {
    if(kIsWeb)
      facebookSignIn.loginBehavior = FacebookLoginBehavior.webViewOnly;
    final FacebookLoginResult result =
    await facebookSignIn.logIn(['email']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final FacebookAccessToken maccessToken = result.accessToken;
        print('''
         Logged in!
         
         Token: ${maccessToken.token}
         User id: ${maccessToken.userId}
         Expires: ${maccessToken.expires}
         Permissions: ${maccessToken.permissions}
         Declined permissions: ${maccessToken.declinedPermissions}
         ''');
        final facebookAuthCred = FacebookAuthProvider.credential(maccessToken.token);
        UserCredential userCred;
        try{
          userCred = await FirebaseAuth.instance.signInWithCredential(facebookAuthCred);
        }catch (e){
          facebookSignIn.logOut();
          print('caught: ' + e.toString());
          //Utilities.showMyDialog(e.toString());
          throw e;
        }
        final User user = userCred.user;
        AnyChatUser anyChatUser = AnyChatUser(user.uid, user.displayName, user.email, user.photoURL, "need to get lang", List<dynamic>());
        anyChatUser.addUserToFirestore();
        currentUser = anyChatUser;
        return anyChatUser;
        break;
      case FacebookLoginStatus.cancelledByUser:
        print('Login cancelled by the user.');
        break;
      case FacebookLoginStatus.error:
        print('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        break;
    }
    return null;
  }
}