import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'anychat_user.dart';

class AnyChatAuth {
  //static User _user;

  // SignInOption option = SignInOption;
  static GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      //'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  static Future<GoogleSignInAccount> signIn() {
    Firebase.initializeApp();
    return _googleSignIn.signIn();
  }

  static Future<AnyChatUser> signInWithGoogle() async {
    await Firebase.initializeApp();
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

      final AnyChatUser user = AnyChatUser(googleSignInAccount.id, googleSignInAccount.displayName,
          googleSignInAccount.email, googleSignInAccount.photoUrl);
      user.addUserToFirestore();
      return user;
      //googleSignInAccount = await _googleSignIn.signIn();
      //googleSignInAuthentication = await googleSignInAccount.authentication;
    }else{
      authResult = await _auth.signInWithPopup(GoogleAuthProvider());
    }

    //final UserCredential authResult =
    //await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    //     await FirebaseAuth.instance.signInWithCredential(credential);

    if (kIsWeb) {
    } else {
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

      final User currentUser = _auth.currentUser;
      assert(_user.uid == currentUser.uid);

      print('signInWithGoogle succeeded: $_user');

      // Using googleSignInAccount for consistency across platforms
      // TODO: use authResult user instead?
      var anyChatUser = new AnyChatUser(
          _user.providerData[0].uid, _user.displayName,
          _user.email, _user.photoURL);
      // var anyChatUser = new AnyChatUser(
      //     currentUser.uid,
      //     currentUser.displayName, currentUser.email, currentUser.photoURL);
      anyChatUser.addUserToFirestore();

      return anyChatUser;
    }

    return null;
  }

  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    print("User Signed Out");
  }

  // static User getUser() {
  //   return _user;
  // }

  static GoogleSignIn getGoogleSignIn() {
    return _googleSignIn;
  }
}
