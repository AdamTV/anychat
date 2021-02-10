// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
// import 'package:oauth1/oauth1.dart';
//
// /// Twitter Login Screen.
// /// See [Log in with Twitter](https://developer.twitter.com/en/docs/basics/authentication/guides/log-in-with-twitter).
// class TwitterLoginScreen extends StatefulWidget {
//   final twitterPlatform = Platform(
//     'https://api.twitter.com/oauth/request_token', // temporary credentials request
//     'https://api.twitter.com/oauth/authorize', // resource owner authorization
//     'https://api.twitter.com/oauth/access_token', // token credentials request
//     SignatureMethods.hmacSha1, // signature method
//   );
//
//   final ClientCredentials clientCredentials;
//   final String oauthCallbackHandler;
//
//   TwitterLoginScreen({
//     @required final String consumerKey,
//     @required final String consumerSecret,
//     @required this.oauthCallbackHandler,
//   }) : clientCredentials = ClientCredentials(consumerKey, consumerSecret);
//
//   @override
//   _TwitterLoginScreenState createState() => _TwitterLoginScreenState();
// }
//
// class _TwitterLoginScreenState extends State<TwitterLoginScreen> {
//   final flutterWebviewPlugin = FlutterWebviewPlugin();
//
//   Authorization _oauth;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize Twitter OAuth
//     _oauth = Authorization(widget.clientCredentials, widget.twitterPlatform);
//
//     flutterWebviewPlugin.onUrlChanged.listen((url) {
//       // Look for Step 2 callback so that we can move to Step 3.
//       if (url.startsWith(widget.oauthCallbackHandler)) {
//         final queryParameters = Uri.parse(url).queryParameters;
//         final oauthToken = queryParameters['oauth_token'];
//         final oauthVerifier = queryParameters['oauth_verifier'];
//         if (null != oauthToken && null != oauthVerifier) {
//           _twitterLogInFinish(oauthToken, oauthVerifier);
//         }
//       }
//     });
//
//     _twitterLogInStart();
//   }
//
//   @override
//   void dispose() {
//     flutterWebviewPlugin.dispose();
//     super.dispose();
//   }
//
//   Future<void> _twitterLogInStart() async {
//     assert(null != _oauth);
//     // Step 1 - Request Token
//     final requestTokenResponse =
//     await _oauth.requestTemporaryCredentials(widget.oauthCallbackHandler);
//     // Step 2 - Redirect to Authorization Page
//     final authorizationPage = _oauth.getResourceOwnerAuthorizationURI(
//         requestTokenResponse.credentials.token);
//     flutterWebviewPlugin.launch(authorizationPage);
//   }
//
//   Future<void> _twitterLogInFinish(
//       String oauthToken, String oauthVerifier) async {
//     // Step 3 - Request Access Token
//     final tokenCredentialsResponse = await _oauth.requestTokenCredentials(
//         Credentials(oauthToken, ''), oauthVerifier);
//
//     final result = TwitterAuthProvider.credential(
//       accessToken: tokenCredentialsResponse.credentials.token,
//       secret: tokenCredentialsResponse.credentials.tokenSecret,
//     );
//
//     Navigator.pop(context, result);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WebviewScaffold(
//       appBar: AppBar(title: Text("Twitter Login")),
//       url: "https://twitter.com",
//     );
//   }
// }