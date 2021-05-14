import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/social_icon.dart';
import 'package:anychat/components/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'anychat_user.dart';
import 'conversation.dart';

class AnyChatAuth {
  static AnyChatUser currentUser;
  static String linkedAccountPhotoUrl;
  static Conversation currentConversation;
  static List<AnyChatUser> currentChatters = <AnyChatUser>[];


  static final FacebookLogin facebookSignIn = new FacebookLogin();
  static GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      //'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  static Future<AnyChatUser> signInApple() async {

    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(clientId: "ca.alphatechnology.anychat", redirectUri: Uri.parse("https://fortunate-phase-wheel.glitch.me/callbacks/sign_in_with_apple"))
    );

    final oAuthProvider = OAuthProvider('apple.com');
    final credential = oAuthProvider.credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );
    final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseUser = authResult.user;
    var snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .get();
      if (snapshot.exists) {
        var currentUser = AnyChatUser.fromSnapshot(snapshot);
        linkedAccountPhotoUrl = "";
        AnyChatAuth.currentUser = currentUser;
        return currentUser;
      } else {
        if (await AnyChatUser.findUserByEmail(firebaseUser.email) == null) {
          var  currentUser = new AnyChatUser(firebaseUser.uid, '${appleIdCredential.givenName ?? ""} ${appleIdCredential.familyName ?? ""}', firebaseUser.email,
              firebaseUser.photoURL ?? "", AnyChatLocale.currentLocale.substring(0, 2));
          currentUser.addUserToFirestore();
          AnyChatAuth.currentUser = currentUser;
          return currentUser;
        }else{
          Fluttertoast.showToast(msg: 'Email already in use.');
          return null;
        }
      }
  }

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
          .doc(authResult.user.uid)
          .get();
      if (snapshot.exists) {
        currentUser = AnyChatUser.fromSnapshot(snapshot);
        linkedAccountPhotoUrl = googleSignInAccount.photoUrl;
        return currentUser;
      } else {
        currentUser = new AnyChatUser(
            authResult.user.uid,
            googleSignInAccount.displayName,
            googleSignInAccount.email,
            googleSignInAccount.photoUrl,
            AnyChatLocale.currentLocale.substring(0, 2));
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
          authResult.user.uid,
          _user.displayName,
          _user.email,
          _user.photoURL,
          AnyChatLocale.currentLocale);
      currentUser.addUserToFirestore();

      return currentUser;
    } else {
      throw Error();
    }
  }

  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      await facebookSignIn.logOut();
      // TODO: Sign-out Twitter & Apple
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
        linkedAccountPhotoUrl = result.photoURL;
        return currentUser;
      } else {
        String displayName = result.displayName;
        if (result.displayName == null) {
          displayName = result.email;
        }
        currentUser = new AnyChatUser(
            result.uid,
            displayName,
            result.email,
            result.photoURL,
            AnyChatLocale.currentLocale.substring(0, 2));
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
          linkedAccountPhotoUrl = user.photoURL;
          return currentUser;
        } else {
          currentUser = new AnyChatUser(user.uid, user.displayName, user.email,
              user.photoURL, AnyChatLocale.currentLocale.substring(0, 2));
          currentUser.addUserToFirestore();
          return currentUser;
        }
        break;
      case FacebookLoginStatus.cancelledByUser:
        print('Login cancelled by the user.');
        throw Exception();
        break;
      case FacebookLoginStatus.error:
        print('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        throw Exception();
        break;
    }
    return null;
  }
  static SocialIcon facebookIcon(BuildContext context) {
    return SocialIcon(
      key: Key("facebookIcon"),
      iconSrc: "assets/icons/facebook.svg",
      press: () async {
        try {
          var user = await AnyChatAuth.signInFacebook();
          if (user != null) {
            Utilities.initConversationScreen(context, user);
          }
        } catch (e) {
          Utilities.showAlertDialog(context, AppLocalizations.of(context).error,
              ModalRoute.of(context).settings.name == "/login"
                  ? AppLocalizations.of(context).errorLoggingInFacebook
                  : AppLocalizations.of(context).unableRegisterFacebook);
        }
      },
    );
  }
  static SocialIcon googleIcon(BuildContext context){
    return SocialIcon(
        iconSrc: "assets/icons/google-plus.svg",
        press: () async {
          try {
            var user = await AnyChatAuth.signInGoogle();
            if (user != null) {
              Utilities.initConversationScreen(context, user);
            }
          } catch (e) {
            Utilities.showAlertDialog(context, AppLocalizations.of(context).error,
                ModalRoute.of(context).settings.name == "/login"
                    ? AppLocalizations.of(context).errorLoggingInGoogle
                    : AppLocalizations.of(context).unableRegisterGoogle);
          }
        });
  }
  static SocialIcon appleIcon(BuildContext context){
    return SocialIcon(
        iconSrc: "assets/icons/apple.svg",
        press: () async {
          try {
            var user = await AnyChatAuth.signInApple();
            if (user != null) {
              Utilities.initConversationScreen(context, user);
            }
          } catch (e) {
            Utilities.showAlertDialog(context, AppLocalizations.of(context).error,
                ModalRoute.of(context).settings.name == "/login"
                    ? AppLocalizations.of(context).errorLoggingInApple
                    : AppLocalizations.of(context).unableRegisterApple);
          }
        }
    );
  }
  static SocialIcon twitterIcon(BuildContext context){
    return SocialIcon(
      iconSrc: "assets/icons/twitter.svg",
      press: () async {
        try {
          var user = await AnyChatAuth.signInTwitter();
          if (user != null) {
            Utilities.initConversationScreen(context, user);
          }
        } catch (e) {
          Utilities.showAlertDialog(context, AppLocalizations.of(context).error,
              ModalRoute.of(context).settings.name == "/login"
                  ? AppLocalizations.of(context).errorLoggingInTwitter
                  : AppLocalizations.of(context).unableRegisterTwitter);
        }
      },
    );
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
      linkedAccountPhotoUrl = user.photoURL;
      return currentUser;
    } else {
      currentUser = new AnyChatUser(user.uid, user.displayName, user.email,
          user.photoURL, AnyChatLocale.currentLocale.substring(0, 2));
      currentUser.addUserToFirestore();
      return currentUser;
    }
  }
}
