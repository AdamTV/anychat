import 'package:anychat/components/locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'anychat_user.dart';

class AnyChatAuth {
  static AnyChatUser currentUser;

  static final FacebookLogin facebookSignIn = new FacebookLogin();
  static GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      //'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  static Future<AnyChatUser> signInGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    GoogleSignInAccount googleSignInAccount;
    AuthCredential credential;
    UserCredential authResult;

    if (!kIsWeb) {
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
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(googleSignInAccount.id)
          .get();
      if (snapshot.exists) {
        currentUser = AnyChatUser.fromSnapshot(snapshot);
        if (currentUser.photoUrl != googleSignInAccount.photoUrl) {
          AnyChatUser.updatePhotoUrl(googleSignInAccount.photoUrl);
        }
        return currentUser;
      } else {
        currentUser = new AnyChatUser(
            googleSignInAccount.id,
            googleSignInAccount.displayName,
            googleSignInAccount.email,
            googleSignInAccount.photoUrl,
            Locale.currentLocale.substring(0, 2), <String>[]);
        currentUser.addUserToFirestore();
        return currentUser;
      }
    } else {
      authResult = await _auth.signInWithPopup(GoogleAuthProvider());
      await _googleSignIn.signInSilently();
      print(_googleSignIn.currentUser?.id);
    }

    final _user = authResult.user;

    if (_user != null) {
      assert(!_user.isAnonymous);
      assert(await _user.getIdToken() != null);

      final User _authCurrentUser = _auth.currentUser;
      assert(_user.uid == _authCurrentUser.uid);

      print('signInWithGoogle succeeded: $_user');

      currentUser = new AnyChatUser(
          _user.providerData[0].uid,
          _user.displayName,
          _user.email,
          _user.photoURL,
          Locale.currentLocale, <String>[]);
      currentUser.addUserToFirestore();

      return currentUser;
    }

    return null;
  }

  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      await facebookSignIn.logOut();
    } catch (e) {
      print("User Signed Out");
    }
  }

  static Future<AnyChatUser> signInEmail(
      String email, String password, bool isSignUp) async {
    try {
      UserCredential _userCredential = isSignUp
          ? await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password)
          : await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
      var result = _userCredential.user;

      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(result.uid)
          .get();
      if (snapshot.exists) {
        currentUser = AnyChatUser.fromSnapshot(snapshot);
        if (currentUser.photoUrl != result.photoURL) {
          AnyChatUser.updatePhotoUrl(result.photoURL);
        }
        return currentUser;
      } else {
        currentUser = new AnyChatUser(
            result.uid,
            result.displayName,
            result.email,
            result.photoURL,
            Locale.currentLocale.substring(0, 2), <String>[]);
        currentUser.addUserToFirestore();
        return currentUser;
      }
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
    if (kIsWeb)
      facebookSignIn.loginBehavior = FacebookLoginBehavior.webViewOnly;
    final FacebookLoginResult result = await facebookSignIn.logIn(['email']);

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
        final facebookAuthCred =
            FacebookAuthProvider.credential(maccessToken.token);
        UserCredential userCred;
        try {
          userCred = await FirebaseAuth.instance
              .signInWithCredential(facebookAuthCred);
        } catch (e) {
          facebookSignIn.logOut();
          print('caught: ' + e.toString());
          throw e;
        }
        final User user = userCred.user;

        var snapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        if (snapshot.exists) {
          currentUser = AnyChatUser.fromSnapshot(snapshot);
          if (currentUser.photoUrl != user.photoURL) {
            AnyChatUser.updatePhotoUrl(user.photoURL);
          }
          return currentUser;
        } else {
          currentUser = new AnyChatUser(user.uid, user.displayName, user.email,
              user.photoURL, Locale.currentLocale.substring(0, 2), <String>[]);
          currentUser.addUserToFirestore();
          return currentUser;
        }
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

  static Future<AnyChatUser> signInTwitter() async {
    // Create a TwitterLogin instance
    final TwitterLogin twitterLogin = new TwitterLogin(
      consumerKey: 'DsqHohkyPJCjhdDByCLwZZYGH',
      consumerSecret: 'NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii',
    );

    final TwitterLoginResult loginResult = await twitterLogin.authorize();

    // Get the Logged In session
    final TwitterSession twitterSession = loginResult.session;

    // Create a credential from the access token
    final AuthCredential twitterAuthCredential = TwitterAuthProvider.credential(
        accessToken: twitterSession.token, secret: twitterSession.secret);

    final userCred =
        await FirebaseAuth.instance.signInWithCredential(twitterAuthCredential);
    final user = userCred.user;

    var snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    if (snapshot.exists) {
      currentUser = AnyChatUser.fromSnapshot(snapshot);
      if (currentUser.photoUrl != user.photoURL) {
        AnyChatUser.updatePhotoUrl(user.photoURL);
      }
      return currentUser;
    } else {
      currentUser = new AnyChatUser(user.uid, user.displayName, user.email,
          user.photoURL, Locale.currentLocale.substring(0, 2), <String>[]);
      currentUser.addUserToFirestore();
      return currentUser;
    }
  }
}
