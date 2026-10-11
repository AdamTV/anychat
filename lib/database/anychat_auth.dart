import 'dart:async';
import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:twitter_login/twitter_login.dart';

import 'anychat_user.dart';
import '../components/combined_locale_info.dart';
import 'conversation.dart';

class AnyChatAuth {
  static late AnyChatUser currentUser;
  static String? linkedAccountPhotoUrl;
  static Conversation? currentConversation;
  static List<AnyChatUser> currentChatters = <AnyChatUser>[];
  // static String? currentMessage;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  static bool isUserInitialized() {
    try {
      var x = AnyChatAuth.currentUser.id;
      logger.d("Current User Id: $x");
      return true;
    } catch (e) {
      logger.d("Caught exception in isUserInitialized: $e");
      return false;
    }
  }

  static Future<AnyChatUser?> signInApple() async {
    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
            clientId: "ca.alphatechnology.anychat",
            redirectUri: Uri.parse(
                "https://fortunate-phase-wheel.glitch.me/callbacks/sign_in_with_apple")));

    final oAuthProvider = OAuthProvider('apple.com');
    final credential = oAuthProvider.credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );
    final authResult =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseUser = authResult.user!;
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
        var locale = await Devicelocale.currentAsLocale;
        String localeStr = locale?.languageCode ?? localeName;
        var currentUser = AnyChatUser(
            firebaseUser.uid,
            '${appleIdCredential.givenName ?? ""} ${appleIdCredential.familyName ?? ""}',
            firebaseUser.email ?? "",
            firebaseUser.photoURL ?? "",
            UserData.themeToString(
                Theme.of(Utilities().globalKey.currentContext!)),
            localeStr,
            true,
            []);
        currentUser.addUserToFirestore();
        AnyChatAuth.currentUser = currentUser;

        return currentUser;
      } else {
        Utilities().showToast(
            localizationOf(Utilities().globalKey.currentContext!).emailInUse);
        return null;
      }
    }
  }

  static Future<AnyChatUser?> signInGoogle() async {
    final FirebaseAuth auth = FirebaseAuth.instance;

    GoogleSignInAccount? googleSignInAccount;
    AuthCredential credential;
    late UserCredential authResult;

    if (!kIsWeb) {
      await _googleSignIn.signIn().then((result) async {
        googleSignInAccount = result;
        await result!.authentication.then((googleKey) async {
          logger.d("accessToken: ${googleKey.accessToken}");
          logger.d("idToken: ${googleKey.idToken}");
          logger.d("displayName: ${googleSignInAccount!.displayName}");
          credential = GoogleAuthProvider.credential(
            accessToken: googleKey.accessToken,
            idToken: googleKey.idToken,
          );
          authResult = await auth.signInWithCredential(credential);
        }).catchError((Object e) {
          logger.e("Error", error: e);

          // logger.e(err.message.toString(),
          //     time: DateTime.now(), error: err, stackTrace: err.stackTrace);
        });
      }).catchError((Object e) {
        logger.e("Error", error: e);

        // logger.e(err.message.toString(),
        //     time: DateTime.now(), error: err, stackTrace: err.stackTrace);
      });
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(authResult.user!.uid)
          .get();
      if (snapshot.exists) {
        currentUser = AnyChatUser.fromSnapshot(snapshot);

        linkedAccountPhotoUrl = googleSignInAccount!.photoUrl;
        return currentUser;
      } else {
        var locale = await Devicelocale.currentAsLocale;
        String localeStr = locale?.languageCode ?? localeName;
        currentUser = AnyChatUser(
            authResult.user!.uid,
            googleSignInAccount!.displayName ?? "",
            googleSignInAccount!.email,
            googleSignInAccount!.photoUrl ?? "",
            UserData.themeToString(
                Theme.of(Utilities().globalKey.currentContext!)),
            localeStr,
            true,
            []);
        currentUser.addUserToFirestore();

        return currentUser;
      }
    } else {
      authResult = await auth.signInWithPopup(GoogleAuthProvider());
      await _googleSignIn.signInSilently();
      logger.d(_googleSignIn.currentUser?.id);
    }

    final user = authResult.user;

    if (user != null) {
      assert(!user.isAnonymous);

      final User authCurrentUser = auth.currentUser!;
      assert(user.uid == authCurrentUser.uid);

      logger.d('signInWithGoogle succeeded: $user');
      var locale = await Devicelocale.currentAsLocale;
      String localeStr = locale?.languageCode ?? localeName;
      currentUser = AnyChatUser(
          authResult.user!.uid,
          user.displayName ?? "",
          user.email ?? "",
          user.photoURL ?? "",
          UserData.themeToString(
              Theme.of(Utilities().globalKey.currentContext!)),
          localeStr,
          true,
          []);
      currentUser.addUserToFirestore();

      return currentUser;
    } else {
      throw Error();
    }
  }

  static Future<void> signOut() async {
    try {
      await CacheManager().clearUserData();
      await RemoteNotificationObserver().cancelSubscriptions();

      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      // await _facebookAuth.logOut();
      // currently apple signin method uses firebase auth, so no need to sign out
    } on Error catch (e) {
      logger.e("Error", error: e, stackTrace: e.stackTrace);
      // logger.e(e.toString(),
      // time: DateTime.now(), error: e, stackTrace: e.stackTrace);
    }
  }

  static Future<AnyChatUser?> signInEmail(
      String? email, String? password, bool isSignUp) async {
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    try {
      UserCredential userCredential = isSignUp
          ? await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email.trim(), password: password)
          : await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email.trim(), password: password);
      var result = userCredential.user!;
      // FirebaseAuth.instance
      //     .s(email: result.email!, actionCodeSettings: acs);
      // Utilities().showToast("Please verify your email.");
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(result.uid)
          .get();
      if (snapshot.exists) {
        currentUser = AnyChatUser.fromSnapshot(snapshot);

        linkedAccountPhotoUrl = result.photoURL;
        return currentUser;
      } else {
        String? displayName = result.displayName;
        if (result.displayName == null) {
          displayName = result.email;
        }
        var locale = await Devicelocale.currentAsLocale;
        String localeStr = locale?.languageCode ?? localeName;
        currentUser = AnyChatUser(
            result.uid,
            displayName ?? "",
            result.email ?? "",
            result.photoURL ?? "",
            UserData.themeToString(
                Theme.of(Utilities().globalKey.currentContext!)),
            localeStr,
            true,
            []);

        currentUser.addUserToFirestore();
        return currentUser;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Utilities().showToast(
            localizationOf(Utilities().globalKey.currentContext!)
                .pleaseChooseStrongerPassword);
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        Utilities().showToast(
            localizationOf(Utilities().globalKey.currentContext!)
                .pleaseLoginInstead);
        throw Exception('The account already exists for that email.');
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  static Future<AnyChatUser?> signInFacebook() async {
    if (kIsWeb) {
      // initialiaze the facebook javascript SDK
      FacebookAuth.instance.webAndDesktopInitialize(
        appId: "463424718375996",
        cookie: true,
        xfbml: true,
        version: "v9.0",
      );
    }
    final LoginResult result = await FacebookAuth.instance.login();

    bool isLogged = result.status == LoginStatus.success;
    if (isLogged) {
      // Create a credential from the access token
      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.token);
      // Once signed in, get the UserCredential
      UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User user = userCred.user!;
      var snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        currentUser = AnyChatUser.fromSnapshot(snapshot);

        linkedAccountPhotoUrl = user.photoURL;
        return currentUser;
      } else {
        final userData = await FacebookAuth.instance.getUserData();
        final picture = userData['picture'] as Map<String, dynamic>;
        final pictureData = picture['data'] as Map<String, dynamic>;
        final url = pictureData['url'] as String;
        var locale = await Devicelocale.currentAsLocale;
        String localeStr = locale?.languageCode ?? localeName;
        currentUser = AnyChatUser(
            user.uid,
            user.displayName ?? "",
            user.email ?? "",
            url,
            UserData.themeToString(
                Theme.of(Utilities().globalKey.currentContext!)),
            localeStr,
            true,
            []);

        currentUser.addUserToFirestore();
        return currentUser;
      }
    }
    return null;
  }

  static Widget flutterSocialButton(BuildContext context, ButtonType buttonType,
      {bool Function()? canContinue}) {
    return FlutterSocialButton(
      onTap: () async {
        if (canContinue != null && !canContinue()) return;
        try {
          var user = await AnyChatAuth.socialSignIn(buttonType);
          if (user != null) {
            Utilities().initConversationScreen(user);
          } else {
            await showAlertDialogFailedSocialLogin(
                context.mounted
                    ? context
                    : Utilities().globalKey.currentContext!,
                buttonType);
          }
        } catch (e) {
          await showAlertDialogFailedSocialLogin(
              context.mounted ? context : Utilities().globalKey.currentContext!,
              buttonType);
        }
      },
      mini: true,
      buttonType: buttonType, // Button type for different type buttons
    );
  }

  // static SocialIcon facebookIcon(BuildContext context) {
  //   return SocialIcon(
  //     key: const Key("facebookIcon"),
  //     iconSrc: "assets/icons/facebook.svg",
  //     press: () async {
  //       if (ModalRoute.of(context)!.settings.name == "/register" &&
  //           !RegisterScreen.isUserAgreeToTerms()) return;
  //       try {
  //         var user = await AnyChatAuth.signInFacebook();
  //         if (user != null) {
  //           Utilities().initConversationScreen(user);
  //         }
  //       } catch (e) {
  //       }
  //     },
  //   );
  // }

  static Future<void> showAlertDialogFailedSocialLogin(
      BuildContext context, ButtonType buttonType) async {
    String errorMessage = switch (buttonType) {
      ButtonType.google => ModalRoute.of(context)!.settings.name == "/login"
          ? localizationOf(context).errorLoggingInGoogle
          : localizationOf(context).unableRegisterGoogle,
      ButtonType.apple => ModalRoute.of(context)!.settings.name == "/login"
          ? localizationOf(context).errorLoggingInApple
          : localizationOf(context).unableRegisterApple,
      ButtonType.facebook => ModalRoute.of(context)!.settings.name == "/login"
          ? localizationOf(context).errorLoggingInFacebook
          : localizationOf(context).unableRegisterFacebook,
      ButtonType.twitter => ModalRoute.of(context)!.settings.name == "/login"
          ? localizationOf(context).errorLoggingInTwitter
          : localizationOf(context).unableRegisterTwitter,

      // TODO(TD-001): Add a supported-provider error message for LinkedIn.
      ButtonType.linkedin => throw UnimplementedError(),
      // TODO(TD-001): Add a supported-provider error message for WhatsApp.
      ButtonType.whatsapp => throw UnimplementedError(),
      // TODO(TD-001): Add a supported-provider error message for GitHub.
      ButtonType.github => throw UnimplementedError(),
      // TODO(TD-001): Add a supported-provider error message for Yahoo.
      ButtonType.yahoo => throw UnimplementedError(),
      // TODO(TD-001): Add a supported-provider error message for phone auth.
      ButtonType.phone => throw UnimplementedError(),
      // TODO(TD-001): Add a supported-provider error message for email auth.
      ButtonType.email => throw UnimplementedError(),
    };
    return await Utilities()
        .showAlertDialog(context, localizationOf(context).error, errorMessage);
  }

  // static SocialIcon googleIcon(BuildContext context) {
  //   //   return SocialIcon(
  //       iconSrc: "assets/icons/google-plus.svg",
  //       press: () async {
  //         if (ModalRoute.of(context)!.settings.name == "/register" &&
  //             !RegisterScreen.isUserAgreeToTerms()) return;
  //         try {
  //           var user = await AnyChatAuth.signInGoogle();
  //           if (user != null) {
  //             Utilities().initConversationScreen(user);
  //           }
  //         } catch (e) {
  //           Utilities().showAlertDialog(
  //               context.mounted
  //                   ? context
  //                   : Utilities().globalKey.currentContext!,
  //               AppLocalizations.of(context.mounted
  //                       ? context
  //                       : Utilities().globalKey.currentContext!)!
  //                   .error,
  //               ModalRoute.of(context.mounted
  //                               ? context
  //                               : Utilities().globalKey.currentContext!)!
  //                           .settings
  //                           .name ==
  //                       "/login"
  //                   ? AppLocalizations.of(context.mounted
  //                           ? context
  //                           : Utilities().globalKey.currentContext!)!
  //                       .errorLoggingInGoogle
  //                   : AppLocalizations.of(context.mounted
  //                           ? context
  //                           : Utilities().globalKey.currentContext!)!
  //                       .unableRegisterGoogle);
  //         }
  //       });
  // }
  //
  // static SocialIcon appleIcon(BuildContext context) {
  //   return SocialIcon(
  //       iconSrc: "assets/icons/apple.svg",
  //       press: () async {
  //         if (ModalRoute.of(context.mounted
  //                         ? context
  //                         : Utilities().globalKey.currentContext!)!
  //                     .settings
  //                     .name ==
  //                 "/register" &&
  //             !RegisterScreen.isUserAgreeToTerms()) return;
  //         try {
  //           var user = await AnyChatAuth.signInApple();
  //           if (user != null) {
  //             Utilities().initConversationScreen(user);
  //           }
  //         } catch (e) {
  //           Utilities().showAlertDialog(
  //               context.mounted
  //                   ? context
  //                   : Utilities().globalKey.currentContext!,
  //               AppLocalizations.of(context.mounted
  //                       ? context
  //                       : Utilities().globalKey.currentContext!)!
  //                   .error,
  //               ModalRoute.of(context.mounted
  //                               ? context
  //                               : Utilities().globalKey.currentContext!)!
  //                           .settings
  //                           .name ==
  //                       "/login"
  //                   ? AppLocalizations.of(context.mounted
  //                           ? context
  //                           : Utilities().globalKey.currentContext!)!
  //                       .errorLoggingInApple
  //                   : AppLocalizations.of(context.mounted
  //                           ? context
  //                           : Utilities().globalKey.currentContext!)!
  //                       .unableRegisterApple);
  //         }
  //       });
  // }
  //
  // static SocialIcon twitterIcon(BuildContext context) {
  //   return SocialIcon(
  //     iconSrc: "assets/icons/twitter.svg",
  //     press: () async {
  //       if (ModalRoute.of(context)!.settings.name == "/register" &&
  //           !RegisterScreen.isUserAgreeToTerms()) return;
  //       try {
  //         var user = await AnyChatAuth.signInTwitter();
  //         if (user != null) {
  //           Utilities().initConversationScreen(user);
  //         }
  //       } catch (e) {
  //         Utilities().showAlertDialog(
  //             context.mounted ? context : Utilities().globalKey.currentContext!,
  //             AppLocalizations.of(context.mounted
  //                     ? context
  //                     : Utilities().globalKey.currentContext!)!
  //                 .error,
  //             ModalRoute.of(context.mounted
  //                             ? context
  //                             : Utilities().globalKey.currentContext!)!
  //                         .settings
  //                         .name ==
  //                     "/login"
  //                 ? AppLocalizations.of(context.mounted
  //                         ? context
  //                         : Utilities().globalKey.currentContext!)!
  //                     .errorLoggingInTwitter
  //                 : AppLocalizations.of(context.mounted
  //                         ? context
  //                         : Utilities().globalKey.currentContext!)!
  //                     .unableRegisterTwitter);
  //       }
  //     },
  //   );
  // }

  static Future<AnyChatUser?> signInTwitter() async {
    // final twitterLogin = TwitterLogin(
    //   // Consumer API keys
    //   apiKey: 'DsqHohkyPJCjhdDByCLwZZYGH',
    //   // Consumer API Secret keys
    //   apiSecretKey: 'NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii',
    //   // Registered Callback URLs in TwitterApp
    //   // Android is a deeplink
    //   // iOS is a URLScheme
    //   redirectURI: 'twittersdk://',
    //   // Forces the user to enter their credentials
    //   // to ensure the correct users account is authorized.
    // );
    // // If you want to implement Twitter account switching, set [force_login] to true
    // // login(forceLogin: true);
    // final authResult = await twitterLogin.login();
    // switch (authResult.status) {
    //   case TwitterLoginStatus.loggedIn:
    //     // success
    //     logger.d('====== Login success ======');
    //     // Create a credential from the access token
    //     final AuthCredential twitterAuthCredential =
    //         TwitterAuthProvider.credential(
    //             accessToken: authResult.authToken!,
    //             secret: authResult.authTokenSecret!);

    //     final userCred = await FirebaseAuth.instance
    //         .signInWithCredential(twitterAuthCredential);
    //     final user = userCred.user!;

    //     var snapshot = await FirebaseFirestore.instance
    //         .collection("users")
    //         .doc(user.uid)
    //         .get();
    //     if (snapshot.exists) {
    //       currentUser = AnyChatUser.fromSnapshot(snapshot);
    //       linkedAccountPhotoUrl = user.photoURL;
    //       return currentUser;
    //     } else {
    //       currentUser = AnyChatUser(user.uid, user.displayName, user.email,
    //           user.photoURL, AnyChatLocale.currentLocale!.substring(0, 2), []);
    //       currentUser!.addUserToFirestore();
    //       return currentUser;
    //     }
    //   case TwitterLoginStatus.cancelledByUser:
    //     // cancel
    //     logger.d('====== Login cancel ======');
    //     break;
    //   case TwitterLoginStatus.error:
    //   default:
    //     // error
    //     logger.d('====== Login error ======');
    //     break;
    // }
    return null;

    // // Create a TwitterLogin instance
    // final TwitterLogin twitterLogin = new TwitterLogin(
    //   consumerKey: 'DsqHohkyPJCjhdDByCLwZZYGH',
    //   consumerSecret: 'NgxbrcVEheDa5OTee6tKS3t4gsnCceVj2awrlURxjyah9Lolii',
    // );
    //
    // final TwitterLoginResult loginResult = await twitterLogin.authorize();
    //
    // // Get the Logged In session
    // final TwitterSession twitterSession = loginResult.session;
    //
    // // Create a credential from the access token
    // final AuthCredential twitterAuthCredential = TwitterAuthProvider.credential(
    //     accessToken: twitterSession.token, secret: twitterSession.secret);
    //
    // final userCred =
    //     await FirebaseAuth.instance.signInWithCredential(twitterAuthCredential);
    // final user = userCred.user;
    //
    // var snapshot = await FirebaseFirestore.instance
    //     .collection("users")
    //     .doc(user.uid)
    //     .get();
    // if (snapshot.exists) {
    //   currentUser = AnyChatUser.fromSnapshot(snapshot);
    //   linkedAccountPhotoUrl = user.photoURL;
    //   return currentUser;
    // } else {
    //   currentUser = new AnyChatUser(user.uid, user.displayName, user.email,
    //       user.photoURL, AnyChatLocale.currentLocale.substring(0, 2));
    //   currentUser.addUserToFirestore();
    //   return currentUser;
    // }
  }

  static Future<AnyChatUser?> socialSignIn(ButtonType buttonType) async {
    switch (buttonType) {
      case ButtonType.google:
        return await AnyChatAuth.signInGoogle();
      case ButtonType.apple:
        return await AnyChatAuth.signInApple();
      case ButtonType.facebook:
        return await AnyChatAuth.signInFacebook();
      case ButtonType.twitter:
        return await AnyChatAuth.signInTwitter();
      default:
        return null;
    }
  }
}
