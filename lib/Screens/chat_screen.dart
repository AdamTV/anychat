import 'dart:async';

import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Screens/add_chatter_screen.dart';
import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Screens/call_screen.dart';
import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Screens/welcome_screen.dart';
import 'package:anychat/components/conversation_info.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/utilities.dart';
import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Components/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'conversations_screen.dart';
import 'chat_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AnyChat",
      theme: kDefaultTheme,
      darkTheme: kDarkTheme,
      home: ChatWindow(),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String id;
  final AnyChatUser sender;
  final String text;
  final AnimationController animationController;

  ChatMessage({this.text, this.animationController, this.sender, this.id});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: sender.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(sender.photoUrl),
                        backgroundColor: Colors.transparent,
                      )
                    : CircleAvatar(
                        child: Text(sender.displayName.substring(0, 1)),
                      )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sender.displayName,
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

  static List<AnyChatUser> currentChatters = <AnyChatUser>[];

  @override
  _ChatWindowState createState() => _ChatWindowState();

  static Stream<QuerySnapshot> loadAllChatMessages() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(currentConversation.id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Stream<QuerySnapshot> loadAllConversations() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}

class _ChatWindowState extends State<ChatWindow> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  StreamSubscription<QuerySnapshot> _chatMessageSubscription;

  List<AnyChatMessage> _chatMessages = <AnyChatMessage>[];

  _ChatWindowState() {

    _chatMessages.clear();
    _messages.clear();
    _chatMessageSubscription =
        ChatWindow.loadAllChatMessages().listen(_updateChatWindow);
  }

  List<AnyChatMessage> getChatMessagesFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).toList();
  }

  List<Timestamp> loadedMessages = <Timestamp>[];

  Future<void> _updateChatWindow(QuerySnapshot snapshot) async {
    _chatMessages = getChatMessagesFromQuery(snapshot);
    if (_messages.isEmpty) {
      for (int i = 0; i < _chatMessages.length; i++) {
        final sender = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection("users")
            .doc(_chatMessages[i].senderId)
            .get());
        if (AnyChatAuth.currentUser.conversations == null) {
          AnyChatAuth.currentUser.conversations =
              await ConversationInfo.getAllConversationInfo(
                  AnyChatAuth.currentUser.id);
        }
        var info = AnyChatAuth.currentUser.conversations.firstWhere(
            (element) => element.id == ChatWindow.currentConversation.id);
        final language = _chatMessages[i].senderId == AnyChatAuth.currentUser.id
            ? info.outgoingLanguage
            : info.incomingLanguage;
        final chatMessage = ChatMessage(
          text: "${_chatMessages[i].text}\n\n"
              "${await Utilities.getGoogleTranslation(language, _chatMessages[i].text)}",
          animationController: AnimationController(
            duration: const Duration(milliseconds: 0),
            vsync: this,
          ),
          sender: sender,
        );
        _messages.insert(0, chatMessage);
        chatMessage.animationController.forward();
      }
      setState(() {
        _isLoading = false;
      });
    } else if (!_messages
        .any((element) => element.id == _chatMessages.last.id)) {
      final message = _chatMessages.last;
      final sender = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
          .collection("users")
          .doc(_chatMessages.last.senderId)
          .get());
      var info = AnyChatAuth.currentUser.conversations.firstWhere(
          (element) => element.id == ChatWindow.currentConversation.id);
      final language = _chatMessages.last.senderId == AnyChatAuth.currentUser.id
          ? info.outgoingLanguage
          : info.incomingLanguage;
      final chatMessage = ChatMessage(
        text: "${message.text}\n\n"
            "${await Utilities.getGoogleTranslation(language, message.text)}",
        animationController: AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: this,
        ),
        sender: sender,
      );
      setState(() {
        _messages.insert(0, chatMessage);
        chatMessage.animationController.forward();
      });
    }
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
                    ? CupertinoButton(
                        child: Text('Send'),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
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

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    await AnyChatUser.addMessageToConversation(text);
    _focusNode.requestFocus();
  }

  bool _isLoading = true;

  String displayName;

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    widgets.add(IconButton(
        icon: const Icon(Icons.language),
        tooltip: 'Language',
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) => _buildPopupDialog(context));
        }));
    widgets.add(IconButton(
      icon: const Icon(Icons.call),
      tooltip: 'Call',
      onPressed: () async {
        await Utilities.handleCameraAndMic(Permission.camera);
        await Utilities.handleCameraAndMic(Permission.microphone);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CallScreen(channelName: ChatWindow.currentConversation.id),
            ));
      },
    ));
    return Scaffold(
      appBar: AppBar(
          title: Text(
              "Chat with ${Utilities.getChatterDisplayNameString(ChatWindow.currentChatters)}"),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: widgets),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(
                'AnyChat',
                style: TextStyle(color: Theme.of(context).primaryColorLight),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
                title: Text('Add Someone to Conversation'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddChatterScreen()));
                }),
            ListTile(
                title: Text('Leave Conversation'),
                onTap: () {
                  AnyChatUser.deleteConversation(
                      context, ChatWindow.currentConversation.id);
                }),
            ListTile(
                title: Text('Back'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ConversationsScreen()));
                }),
            ListTile(
                title: Text('Logout'),
                onTap: () async {
                  await AnyChatAuth.signOut();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()));
                }),
          ],
        ),
      ),
      body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _isLoading
                ? [
                    Center(
                      child: CircularProgressIndicator(
                          valueColor: ColorTween(
                                  begin: Theme.of(context).accentColor,
                                  end: Theme.of(context).accentColor)
                              .animate(AnimationController(vsync: this)),
                          backgroundColor: Theme.of(context).primaryColor),
                    )
                  ]
                : [
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
                      decoration:
                          BoxDecoration(color: Theme.of(context).cardColor),
                      child: _buildTextComposer(),
                    ),
                  ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]),
                  ),
                )
              : null),
    );
  }

  @override
  void dispose() {
    _chatMessageSubscription?.cancel();
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    super.dispose();
  }

  _buildPopupDialog(BuildContext context) {
    var info = AnyChatAuth.currentUser.conversations.firstWhere(
        (element) => element.id == ChatWindow.currentConversation.id);
    String incomingDropdownValue =
        Utilities.getLanguageFromIsoCode(info.incomingLanguage);
    String outgoingDropdownValue =
        Utilities.getLanguageFromIsoCode(info.outgoingLanguage);
    print(incomingDropdownValue);
    return new AlertDialog(
      title: const Text('Select Language'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Incoming Messages'),
          DropdownButton<String>(
            value: incomingDropdownValue,
            icon: Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).primaryColor),
            onChanged: (String newValue) async {
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                var user = FirebaseFirestore.instance
                    .collection('users')
                    .doc(AnyChatAuth.currentUser.id);
                var userConversationInfo = user
                    .collection('conversations')
                    .doc(ChatWindow.currentConversation.id);
                return transaction
                    .get(user)
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) async {
                  transaction.update(userConversationInfo, {
                    'incomingLanguage': isoMap[newValue],
                  });
                });
              });
              setState(() {
                info.incomingLanguage = isoMap[newValue];
                incomingDropdownValue = newValue;
              });
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ChatScreen()));
            },
            items: isoMap.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Divider(height: 25),
          Text('Outgoing Messges'),
          DropdownButton<String>(
            value: outgoingDropdownValue,
            icon: Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).primaryColor),
            onChanged: (String newValue) async {
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                var user = FirebaseFirestore.instance
                    .collection('users')
                    .doc(AnyChatAuth.currentUser.id);
                var userConversationInfo = user
                    .collection('conversations')
                    .doc(ChatWindow.currentConversation.id);
                return transaction
                    .get(user)
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) async {
                  transaction.update(userConversationInfo, {
                    'outgoingLanguage': isoMap[newValue],
                  });
                });
              });
              setState(() {
                info.outgoingLanguage = isoMap[newValue];
                outgoingDropdownValue = newValue;
              });
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ChatScreen()));
            },
            items: isoMap.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
