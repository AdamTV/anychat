import 'package:anychat/Screens/Conversations/conversations_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anychat/constants.dart';

// final FirebaseAuth _auth = FirebaseAuth.instance;
// GoogleSignIn _googleSignIn = GoogleSignIn(
//   scopes: <String>[
//     'email',
//     //'https://www.googleapis.com/auth/contacts.readonly',
//   ],
// );

class FriendlyChatApp extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _FriendlyChatAppState();
}

class _FriendlyChatAppState extends State<FriendlyChatApp>{
  static User _user;
  @override
  Widget build(BuildContext context) {
    //if (_user != null) {
      return MaterialApp(
        title: 'AnyChat',
        theme: defaultTargetPlatform == TargetPlatform.iOS // NEW
            ? kIOSTheme // NEW
            : kDefaultTheme,
        home: ChatWindow(),
      );
    // } else {
    //   return Scaffold(
    //       body: ConstrainedBox(
    //         constraints: const BoxConstraints.expand(),
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.spaceAround,
    //           children: <Widget>[
    //             const Text("You are not currently signed in."),
    //             RaisedButton(
    //               child: const Text('Sign in with Google'),
    //               onPressed:() async {
    //                 _ChatScreenState._user = await _ChatScreenState.signInWithGoogle();
    //                 setState(() {
    //                   _user = _ChatScreenState._user;
    //                 });
    //               },
    //             ),
    //             const Text('OR'),
    //             RaisedButton(
    //                 child: const Text('Create an account'),
    //                 onPressed: () async{
    //                   _ChatScreenState._user = await _ChatScreenState.createAccount();
    //                   setState(() {
    //                     _user = _ChatScreenState._user;
    //                   });
    //                 })
    //           ],
    //         ),
    //       ));
    // }
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final AnimationController animationController;

  //final GoogleSignInAccount user;

  ChatMessage({this.text, this.animationController});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: AnyChatAuth.getGoogleSignIn().currentUser.photoUrl != null
                    ? CircleAvatar(
                  backgroundImage:
                  NetworkImage(AnyChatAuth.getGoogleSignIn().currentUser.photoUrl),
                  backgroundColor: Colors.transparent,
                )
                    : CircleAvatar(
                  child: Text('A'),
                )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      AnyChatAuth.getGoogleSignIn().currentUser == null
                          ? 'Anonymous'
                          : AnyChatAuth.getGoogleSignIn().currentUser.displayName,
                      style: Theme.of(context).textTheme.headline4),
                  Container(
                    margin: EdgeInsets.only(top: 5.0),
                    child: Text(text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatWindow extends StatefulWidget {
  @override
  _ChatWindowState createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> with TickerProviderStateMixin {
  //static GoogleSignInAccount currentUser;

  //static User _user;
  final _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    AnyChatAuth.getGoogleSignIn().onCurrentUserChanged.listen((GoogleSignInAccount account) {

      setState(() {

        //currentUser = account;
        //print(currentUser);
      });
    });
    AnyChatAuth.getGoogleSignIn().signInSilently();
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
                decoration:
                InputDecoration.collapsed(hintText: 'Send a message'),
                focusNode: _focusNode,
              ),
            ),
            Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? // MODIFIED
                CupertinoButton(
                  // NEW
                  child: Text('Send'), // NEW
                  onPressed: _isComposing // NEW
                      ? () =>
                      _handleSubmitted(_textController.text) // NEW
                      : null,
                )
                    : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                ))
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    print(AnyChatAuth.getGoogleSignIn().currentUser);

    ChatMessage message = ChatMessage(
      //user: currentUser,
      text: text,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    );
    setState(() {
      _messages.insert(0, message);
    });
    _focusNode.requestFocus();
    message.animationController.forward();
  }

//   static Future<User> signInWithGoogle() async {
//     await Firebase.initializeApp();
//
//     final GoogleSignInAccount googleSignInAccount =
//     await AnyChatAuth.getGoogleSignIn().signIn();
//     final GoogleSignInAuthentication googleSignInAuthentication =
//     await googleSignInAccount.authentication;
//
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleSignInAuthentication.accessToken,
//       idToken: googleSignInAuthentication.idToken,
//     );
//
//     final UserCredential authResult =
//     await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
//
//     // final UserCredential authResult =
//     //     await FirebaseAuth.instance.signInWithCredential(credential);
//     final User user = authResult.user;
//
// //    final User user = null;
//
//     if (_user != null) {
//       assert(!_user.isAnonymous);
//       assert(await _user.getIdToken() != null);
//
//       final User currentUser = AnyChatAuth.getUser();
//       assert(_user.uid == currentUser.uid);
//
//       print('signInWithGoogle succeeded: $_user');
//
//       var anyChatUser = new AnyChatUser(currentUser.displayName,
//           currentUser.email, currentUser.photoURL);
//       anyChatUser.addUserToFirestore();
//
//       return _user;
//     }
//
//     return null;
//   }
//
//   Future<void> signOutGoogle() async {
//     await AnyChatAuth.getGoogleSignIn().signOut();
//     _FriendlyChatAppState._user = null;
//     print("User Signed Out");
//   }

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

  // static Future<void> _handleSignIn() async {
  //   try {
  //     await AnyChatAuth.getGoogleSignIn().signIn();
  //   } catch (error) {
  //     print(error);
  //   }
  // }

  //
  // Future<void> _handleSignOut() async {
  //   await AnyChatAuth.getGoogleSignIn().disconnect();
  //   setState(() {
  //     currentUser = null;
  //   });
  //   //Navigator.pop(context);
  // }

  // Future<void> _signInAnonymously() async {
  //   UserCredential temp;
  //   await FirebaseAuth.instance
  //       .signInAnonymously()
  //       .then((UserCredential userCredential) {
  //     temp = userCredential;
  //   });
  //   setState(() {
  //     _userCredential = temp;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('AnyChat'),
          elevation:
          Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          //actions: <Widget>[
            // _user == null
            //     ? IconButton(
            //         icon: const Icon(Icons.login),
            //         tooltip: 'Login',
            //         onPressed: () {
            //           signInWithGoogle();
            //         },
            //       )
            //     :
            // IconButton(
            //   icon: const Icon(Icons.logout),
            //   tooltip: 'Logout',
            //   onPressed: () {
            //     signOutGoogle();
            //     Navigator.push(context, MaterialPageRoute(builder: (context)=>WelcomeScreen()));
            //   },
            // ),
          //]
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('AnyChat', style:
              // TODO: Color should be platform specific
              TextStyle(color: Colors.white),),
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .primaryColor,
              ),
            ),
            ListTile(
                title: Text('Return to conversations'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ConversationsScreen()));
                  //_handleSignOut();
                }),
            ListTile(
                title: Text('Logout'),
                onTap: () {
                  AnyChatAuth.signOutGoogle();
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => WelcomeScreen()));
                  //_handleSignOut();
                }),
          ],
        ),
      ),
      body: Container(
          child: Column(
            children: [
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (_, int index) => _messages[index],
                  itemCount: _messages.length,
                ),
              ),
              Divider(height: 5.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(), //MODIFIED
              ),
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS // NEW
              ? BoxDecoration(
            // NEW
            border: Border(
              // NEW
              top: BorderSide(color: Colors.grey[200]), // NEW
            ), // NEW
          ) // NEW
              : null),
    );
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    super.dispose();
  }
}