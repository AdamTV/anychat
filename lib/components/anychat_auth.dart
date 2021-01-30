import 'package:anychat/components/locale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
// import 'package:twitter_login/twitter_login.dart';
// import 'package:flutter_twitter/flutter_twitter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:twitter_login/twitter_login.dart';

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
  static Future<AnyChatUser> signInGoogle() async {
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
            locale.currentLocale.substring(0, 2),
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
          _user.providerData[0].uid,
          _user.displayName,
          _user.email,
          _user.photoURL,
          locale.currentLocale,
          new List<String>());
      // var anyChatUser = new AnyChatUser(
      //     currentUser.uid,
      //     currentUser.displayName, currentUser.email, currentUser.photoURL);
      currentUser.addUserToFirestore();

      return currentUser;
    }

    return null;
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    await facebookSignIn.logOut();
    print("User Signed Out");
  }

  // static GoogleSignIn getGoogleSignIn() {
  //   return _googleSignIn;
  // }

  // static Future<AnyChatUser> createAccountEmail(
  //     String email, String password, String language) async {
  //   try {
  //     UserCredential _userCredential = await FirebaseAuth.instance
  //         .createUserWithEmailAndPassword(email: email, password: password);
  //     var result = _userCredential.user;
  //     print('result: ' + result.toString());
  //     AnyChatUser currentU = AnyChatUser(result.uid, result.displayName,
  //         result.email, result.photoURL, language, new List<dynamic>());
  //     currentUser = currentU;
  //     currentU.addUserToFirestore();
  //     return currentU;
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'weak-password') {
  //       throw Exception('The password provided is too weak.');
  //     } else if (e.code == 'email-already-in-use') {
  //       throw Exception('The account already exists for that email.');
  //     }
  //   } catch (e) {
  //     throw (e);
  //   }
  //   return null;
  // }

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
            locale.currentLocale.substring(0, 2),
            new List<String>());
        currentUser.addUserToFirestore();
        return currentUser;
      }
      // AnyChatUser currentU = AnyChatUser.fromSnapshot(
      //     await FirebaseFirestore.instance.collection("users")
      //         .doc(result.uid)
      //         .get());
      // currentUser = currentU;
      // currentU.addUserToFirestore();
      // return currentU;
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
          //Utilities.showMyDialog(e.toString());
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
          currentUser = new AnyChatUser(
              user.uid,
              user.displayName,
              user.email,
              user.photoURL,
              locale.currentLocale.substring(0, 2),
              new List<String>());
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
final twitterLogin = TwitterLogin(
                // Consumer API keys
                apiKey: 'DsqHohkyPJCjhdDByCLwZZYGH',
                // Consumer API Secret keys
                apiSecretKey: 'NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii',
                // Registered Callback URLs in TwitterApp
                // Android is a deeplink
                // iOS is a URLScheme
                redirectURI: 'https://anychat-c414a.firebaseapp.com/__/auth/handler',
                // Forces the user to enter their credentials
                // to ensure the correct users account is authorized.
              );
              // If you want to implement Twitter account switching, set [force_login] to true
              // login(forceLogin: true);
              final authResult = await twitterLogin.login();
              switch (authResult.status) {
                case TwitterLoginStatus.loggedIn:
                  // success
                  print('====== Login success ======');
                  break;
                case TwitterLoginStatus.cancelledByUser:
                  // cancel
                  print('====== Login cancel ======');
                  break;
                case TwitterLoginStatus.error:
                  // error
                  print('====== Login error ======');
                  break;
              }

    // TwitterLogin twitterLogin = TwitterLogin(
    //     consumerKey: "DsqHohkyPJCjhdDByCLwZZYGH",
    //     consumerSecret: "NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii");
    // final TwitterLoginResult result = await twitterLogin.authorize();
    // String newMessage;
    // if (result.status == TwitterLoginStatus.loggedIn) {
    //   return _signInWithTwitter(result.session.token, result.session.secret);
    // } else if (result.status == TwitterLoginStatus.cancelledByUser) {
    //   newMessage = 'Login cancelled by user.';
    // } else {
    //   newMessage = "Error: " + result.errorMessage;
    // }
    // print(newMessage);
    // return null;
    // // setState(() {
    // //   message = newMessage;
    // // });
  }

  static Future<AnyChatUser> _signInWithTwitter(
      String token, String secret) async {
    final AuthCredential credential =
        TwitterAuthProvider.credential(accessToken: token, secret: secret);
    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);
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
      currentUser = new AnyChatUser(
          user.uid,
          user.displayName,
          user.email,
          user.photoURL,
          locale.currentLocale.substring(0, 2),
          new List<String>());
      currentUser.addUserToFirestore();
      return currentUser;
    }
  }
// static Future<AnyChatUser>signInTwitter() async {
//   final twitterLogin = TwitterLogin(
//     // Consumer API keys
//     apiKey: 'DsqHohkyPJCjhdDByCLwZZYGH',
//     // Consumer API Secret keys
//     apiSecretKey: 'NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii',
//     // Registered Callback URLs in TwitterApp
//     // Android is a deeplink
//     // iOS is a URLScheme
//     redirectURI: 'https://anychat-c414a.firebaseapp.com/__/auth/handler',
//     // Forces the user to enter their credentials
//     // to ensure the correct users account is authorized.
//   );
//   // If you want to implement Twitter account switching, set [force_login] to true
//   // login(forceLogin: true);
//   final authResult = await twitterLogin.login();
//   switch (authResult.status) {
//     case TwitterLoginStatus.loggedIn:
//     // success
//       print('====== Login success ======');
//       break;
//     case TwitterLoginStatus.cancelledByUser:
//     // cancel
//       print('====== Login cancel ======');
//       break;
//     case TwitterLoginStatus.error:
//     // error
//       print('====== Login error ======');
//       break;
//   }
// }
}
