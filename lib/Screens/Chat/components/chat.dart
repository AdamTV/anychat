import 'package:anychat/Screens/Conversations/conversations_screen.dart';
import 'package:anychat/Screens/Welcome/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:anychat/constants.dart';

class AnyChatApp extends StatefulWidget{
  static AnyChatUser chatter;
  @override
  State<StatefulWidget> createState() => _AnyChatAppState();
}

class _AnyChatAppState extends State<AnyChatApp>{
  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        title: "AnyChat",
        theme: defaultTargetPlatform == TargetPlatform.iOS // NEW
            ? kIOSTheme // NEW
            : kDefaultTheme,
        home: ChatWindow(),
      );
  }
}

class ChatMessage extends StatelessWidget {
  final AnyChatUser sender;
  final String text;
  final AnimationController animationController;
  ChatMessage({this.text, this.animationController, this.sender});

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
                child: sender.photoUrl != null
                    ? CircleAvatar(
                  backgroundImage:
                  NetworkImage(sender.photoUrl),
                  backgroundColor: Colors.transparent,
                )
                    : CircleAvatar(
                  child: Text(sender.displayName.substring(0,1)),
                )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      sender.displayName,
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
  static Conversation currentConversation;
  @override
  _ChatWindowState createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> with TickerProviderStateMixin {

  final _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  _ChatWindowState(){
    _loadChatMessages();
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
    ChatMessage message = ChatMessage(
      //user: currentUser,
      text: text,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
      sender: AnyChatAuth.currentUser,
    );
    // If conversation does not exist
    if(ChatWindow.currentConversation == null){
      AnyChatUser.createConversation().then((value) => {
      AnyChatUser.addMessageToConversation(AnyChatMessage(AnyChatAuth.currentUser, message.text))
      });
    }else{
      AnyChatUser.addMessageToConversation(AnyChatMessage(AnyChatAuth.currentUser, message.text));
    }
    setState(() {
      _messages.insert(0, message);
    });
    _focusNode.requestFocus();
    message.animationController.forward();
  }

void _loadChatMessages(){
    print('loading chat messages');
    Conversation convo;
    FirebaseFirestore.instance.collection("conversations").doc(ChatWindow.currentConversation.id).get().then((value) =>
    {
      convo = Conversation.fromSnapshot(value),
      convo.messages.reversed.forEach((element) async {
      ChatMessage message = ChatMessage(
        //user: currentUser,
        text: element['text'],
        animationController: AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: this,
        ),
        sender: AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(element['sender']).get()),
      );
      setState(() {
        //print('adding chat message: ' + element);
        _messages.insert(0, message);
      });
      //_focusNode.requestFocus();
      message.animationController.forward();
    })});

    // ChatWindow.currentConversation?.messages?.forEach((element) {
    //   ChatMessage message = ChatMessage(
    //     //user: currentUser,
    //     text: element.text,
    //     animationController: AnimationController(
    //       duration: const Duration(milliseconds: 700),
    //       vsync: this,
    //     ),
    //     sender: element.sender,
    //   );
    //   //setState(() {
    //     //print('adding chat message: ' + element);
    //     _messages.insert(0, message);
    //   //});
    //   //_focusNode.requestFocus();
    //   message.animationController.forward();
    // });
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
          title: Text("Chat with ${AnyChatApp.chatter.displayName}"),
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

  // AnyChatUser parseAnyChatUser(String elementId) {
  //   AnyChatUser user;
  //   FirebaseFirestore.instance.collection("users").doc(elementId).get().then((value) =>
  //   {
  //     user = AnyChatUser.fromSnapshot(value),
  //
  //   });
  //   print('parseAnyChatUser -> displayName: ' + user.displayName);
  //   return user;
  // }
}