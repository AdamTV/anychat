import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anychat/components/locale.dart';


import 'anychat_user.dart';

class AnyChatAuth {
  static AnyChatUser currentUser;
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

      currentUser = AnyChatUser(googleSignInAccount.id, googleSignInAccount.displayName,
          googleSignInAccount.email, googleSignInAccount.photoUrl, locale.currentLocale, new List<String>());
      currentUser.addUserToFirestore();
      return currentUser;
      //googleSignInAccount = await _googleSignIn.signIn();
      //googleSignInAuthentication = await googleSignInAccount.authentication;
    }else{
      authResult = await _auth.signInWithPopup(GoogleAuthProvider());
      await _googleSignIn.signInSilently();
      print(_googleSignIn.currentUser?.id);
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

      final User _authCurrentUser = _auth.currentUser;
      assert(_user.uid == _authCurrentUser.uid);

      print('signInWithGoogle succeeded: $_user');

      // Using googleSignInAccount for consistency across platforms
      // TODO: use authResult user instead?
      currentUser = new AnyChatUser(
          _user.providerData[0].uid, _user.displayName,
          _user.email, _user.photoURL, locale.currentLocale, new List<String>());
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

  static Future<User> createAccount() async {
    try {
      UserCredential _userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: "barray.allen@example.com",
          password: "SuperSecretPassword!");
      return _userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }
}
