import 'dart:async';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/conversation_info.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/search_chatter_by_email_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return const ChatWindow();
  }
}

class ChatWindow extends StatefulWidget {
  const ChatWindow({Key? key}) : super(key: key);

  @override
  State<ChatWindow> createState() => _ChatWindowState();

  static Stream<QuerySnapshot> loadAllChatMessages() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(AnyChatAuth.currentConversation!.id)
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
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  StreamSubscription<QuerySnapshot>? _chatMessageSubscription;

  List<AnyChatMessage> _chatMessages = <AnyChatMessage>[];

  _ChatWindowState() {
    _chatMessageSubscription ??=
        ChatWindow.loadAllChatMessages().listen(_updateChatWindow);
  }

  List<AnyChatMessage> getChatMessagesFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).toList();
  }

  Future<void> _updateChatWindow(QuerySnapshot snapshot) async {
    _chatMessages = getChatMessagesFromQuery(snapshot);
    if (_messages.isEmpty) {
      var convo = await Conversation.getConversationById(
          AnyChatAuth.currentConversation!.id);
      var participants = <AnyChatUser>[];
      for (final element in convo.participants) {
        if (!AnyChatAuth.currentChatters
            .any((chatter) => chatter.id == element)) {
          AnyChatAuth.currentChatters
              .removeWhere((chatter) => chatter.id == element);
        }
        participants.add(await AnyChatUser.getUserById(element));
      }

      AnyChatAuth.currentUser!.conversations =
          await ConversationInfo.getAllConversationInfo(
              AnyChatAuth.currentUser!.id);
      var info = AnyChatAuth.currentUser!.conversations.firstWhere(
          (element) => element.id == AnyChatAuth.currentConversation!.id);
      // divide all chat messages into language for translation -> translate
      Map<String?, List<String?>> map = {};
      for (var message in _chatMessages) {
        final language = message.senderId == AnyChatAuth.currentUser!.id
            ? info.outgoingLanguage
            : info.incomingLanguage;
        if (!map.containsKey(language)) {
          map.putIfAbsent(language, () => <String?>[]);
        }
        map[language]!.insert(0, message.text);
      }
      logger.d("chatMessage size: ${_chatMessages.length}");
      Map<String?, List<String>> translatedMap =
          await Utilities.getBatchGoogleTranslation(map);
      for (int i = 0; i < _chatMessages.length; i++) {
        if (!participants
            .any((element) => element.id == _chatMessages[i].senderId)) {
          participants.add(
              await AnyChatUser.getUserById(_chatMessages[i].senderId).onError(
                  (dynamic error, stackTrace) => AnyChatUser(
                      null,
                      AppLocalizations.of(context)!.accountDeleted,
                      null,
                      null,
                      null, [])));
        }
        AnyChatUser sender = AnyChatUser.deletedUser();
        try {
          sender = participants
              .firstWhere((element) => element.id == _chatMessages[i].senderId);
        } on Error catch (e) {
          // logger.e("Error",
          //     time: DateTime.now(), error: e, stackTrace: e.stackTrace);
          logger.e("Error", e, e.stackTrace);
          sender = AnyChatUser(
              null,
              AppLocalizations.of(
                      mounted ? context : Utilities.globalKey.currentContext!)!
                  .accountDeleted,
              null,
              null,
              null,
              []);
        }
        final language =
            _chatMessages[i].senderId == AnyChatAuth.currentUser!.id
                ? info.outgoingLanguage
                : info.incomingLanguage;
        if (translatedMap[language]!.isEmpty) break;
        var text = RichText(
          text: TextSpan(
            // Note: Styles for TextSpans must be explicitly defined.
            // Child text spans will inherit styles from parent
            style: Theme.of(
                    mounted ? context : Utilities.globalKey.currentContext!)
                .textTheme
                .bodyLarge,
            children: <TextSpan>[
              TextSpan(
                  text:
                      "${mounted ? AppLocalizations.of(context)!.typed : AppLocalizations.of(Utilities.globalKey.currentContext!)!.typed}: ",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "${_chatMessages[i].text}\n\n"),
              TextSpan(
                  text:
                      "${mounted ? AppLocalizations.of(context)!.translation : AppLocalizations.of(Utilities.globalKey.currentContext!)!.translation}: ",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: translatedMap[language]!.removeLast()),
            ],
          ),
        );
        final chatMessage = ChatMessage(
          text: text,
          animationController: AnimationController(
            duration: const Duration(milliseconds: 0),
            vsync: this,
          ),
          sender: sender,
        );
        _messages.insert(0, chatMessage);
        chatMessage.animationController!.forward();
      }

      setState(() {
        _isLoading = false;
      });
    } else if (!_messages
        .any((element) => element.id == _chatMessages.last.id)) {
      final message = _chatMessages.last;
      AnyChatUser sender = AnyChatUser.deletedUser();
      try {
        sender = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection("users")
            .doc(_chatMessages.last.senderId)
            .get());
      } catch (e) {
        sender = AnyChatUser.deletedUser();
      }

      if (AnyChatAuth.currentUser!.conversations.isEmpty) {
        AnyChatAuth.currentUser!.conversations =
            await ConversationInfo.getAllConversationInfo(
                AnyChatAuth.currentUser!.id);
      }

      logger
          .d("currentConvversation.id: ${AnyChatAuth.currentConversation!.id}");
      var info = AnyChatAuth.currentUser!.conversations.firstWhere(
          (element) => element.id == AnyChatAuth.currentConversation!.id);
      final language =
          _chatMessages.last.senderId == AnyChatAuth.currentUser!.id
              ? info.outgoingLanguage
              : info.incomingLanguage;
      var text = RichText(
        text: TextSpan(
          // Note: Styles for TextSpans must be explicitly defined.
          // Child text spans will inherit styles from parent
          style: mounted
              ? Theme.of(context).textTheme.bodyLarge
              : Theme.of(Utilities.globalKey.currentContext!)
                  .textTheme
                  .bodyLarge,
          children: <TextSpan>[
            TextSpan(
                text:
                    "${mounted ? AppLocalizations.of(context)!.typed : AppLocalizations.of(Utilities.globalKey.currentContext!)!.typed}: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: "${message.text}\n\n"),
            TextSpan(
                text:
                    "${mounted ? AppLocalizations.of(context)!.translation : AppLocalizations.of(Utilities.globalKey.currentContext!)!.translation}: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: await Utilities.getGoogleTranslation(
                    language, message.text)),
          ],
        ),
      );
      final chatMessage = ChatMessage(
        text: text,
        animationController: AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: this,
        ),
        sender: sender,
      );
      setState(() {
        _messages.insert(0, chatMessage);
        chatMessage.animationController!.forward();
      });
    }
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
                decoration: InputDecoration.collapsed(
                    hintText: AppLocalizations.of(context)!.send_a_messgae),
                focusNode: _focusNode,
              ),
            ),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? CupertinoButton(
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                        child: Text(AppLocalizations.of(context)!.send),
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

  String? displayName;

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    widgets.add(IconButton(
        icon: const Icon(Icons.settings),
        tooltip: AppLocalizations.of(context)!.language,
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) => _buildPopupDialog(context));
        }));
    widgets.add(IconButton(
      icon: const Icon(Icons.video_call_rounded),
      tooltip: AppLocalizations.of(context)!.call,
      onPressed: () async {
        CallScreen.requestPermissionAndNavigate();
      },
    ));
    SizedBox container = SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _isLoading
            ? [
                Center(
                  child: CircularProgressIndicator(
                      valueColor: ColorTween(
                              begin: Theme.of(context).colorScheme.secondary,
                              end: Theme.of(context).colorScheme.secondary)
                          .animate(AnimationController(vsync: this)),
                      backgroundColor: Theme.of(context).primaryColor),
                )
              ]
            : [
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemBuilder: (_, int index) => _messages[index],
                    itemCount: _messages.length,
                  ),
                ),
                const Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(),
                ),
              ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
          title: Text(Utilities.getChatterDisplayNameString(
              AnyChatAuth.currentChatters)),
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
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                AppLocalizations.of(context)!.title,
                style: TextStyle(color: Theme.of(context).primaryColorLight),
              ),
            ),
            ListTile(
                title: Text(
                    AppLocalizations.of(context)!.addSomeoneToConversation),
                onTap: () {
                  SearchChatterByEmailScreen.addToConvo = true;
                  Navigator.pushNamed(context, "/addChatter");
                }),
            ListTile(
                title: Text(AppLocalizations.of(context)!.leaveConversation),
                onTap: () {
                  AnyChatUser.deleteConversation(
                      context, AnyChatAuth.currentConversation!.id);
                }),
            ListTile(
                title: Text(AppLocalizations.of(context)!.backToConversations),
                onTap: () {
                  Navigator.pushNamed(context, "/conversations");
                }),
            ListTile(
                title: Text(AppLocalizations.of(context)!.logout),
                onTap: () async {
                  await AnyChatAuth.signOut();
                  Navigator.pushNamed(
                      mounted ? context : Utilities.globalKey.currentContext!,
                      "/welcome");
                }),
          ],
        ),
      ),
      body: container,
    );
  }

  @override
  void dispose() {
    _chatMessageSubscription?.cancel();
    for (ChatMessage message in _messages) {
      message.animationController!.dispose();
    }
    super.dispose();
  }

  _buildPopupDialog(BuildContext context) {
    var info = AnyChatAuth.currentUser!.conversations.firstWhere(
        (element) => element.id == AnyChatAuth.currentConversation!.id);
    String? incomingDropdownValue =
        Utilities.getLanguageFromIsoCode(info.incomingLanguage);
    String? outgoingDropdownValue =
        Utilities.getLanguageFromIsoCode(info.outgoingLanguage);
    logger.d(incomingDropdownValue);
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AppLocalizations.of(context)!.incomingMessages),
          DropdownButton<String>(
            value: incomingDropdownValue,
            icon: const Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) async {
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                var user = FirebaseFirestore.instance
                    .collection('users')
                    .doc(AnyChatAuth.currentUser!.id);
                var userConversationInfo = user
                    .collection('conversations')
                    .doc(AnyChatAuth.currentConversation!.id);
                return transaction
                    .get(user)
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) async {
                  transaction.update(userConversationInfo, {
                    'incomingLanguage': AnyChatLocale.isoMap[newValue!],
                  });
                });
              });
              setState(() {
                info.incomingLanguage = AnyChatLocale.isoMap[newValue!];
                incomingDropdownValue = newValue;
              });
              Navigator.pushNamed(
                  mounted ? context : Utilities.globalKey.currentContext!,
                  "/chat");
            },
            items: AnyChatLocale.isoMap.keys
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const Divider(height: 25),
          Text(AppLocalizations.of(context)!.outgoingMessages),
          DropdownButton<String>(
            value: outgoingDropdownValue,
            icon: const Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) async {
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                var user = FirebaseFirestore.instance
                    .collection('users')
                    .doc(AnyChatAuth.currentUser!.id);
                var userConversationInfo = user
                    .collection('conversations')
                    .doc(AnyChatAuth.currentConversation!.id);
                return transaction
                    .get(user)
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) async {
                  transaction.update(userConversationInfo, {
                    'outgoingLanguage': AnyChatLocale.isoMap[newValue!],
                  });
                });
              });
              setState(() {
                info.outgoingLanguage = AnyChatLocale.isoMap[newValue!];
                outgoingDropdownValue = newValue;
              });
              Navigator.pushNamed(
                  mounted ? context : Utilities.globalKey.currentContext!,
                  "/chat");
            },
            items: AnyChatLocale.isoMap.keys
                .map<DropdownMenuItem<String>>((String value) {
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

class ChatMessage extends StatelessWidget {
  final String? id;
  final AnyChatUser? sender;
  final RichText? text;
  final AnimationController? animationController;

  const ChatMessage(
      {Key? key, this.text, this.animationController, this.sender, this.id})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController!, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        decoration: BoxDecoration(
            color: sender!.id == AnyChatAuth.currentUser!.id
                ? Theme.of(context).brightness == Brightness.dark
                    ? kDarkChatBubbleColorRight
                    : kDefaultChatBubbleColorRight
                : Theme.of(context).brightness == Brightness.dark
                    ? kDarkChatBubbleColorLeft
                    : kDefaultChatBubbleColorLeft,
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        margin: EdgeInsets.fromLTRB(
            sender!.id == AnyChatAuth.currentUser!.id
                ? (MediaQuery.of(context).size.width * 0.25)
                : 8,
            8,
            sender!.id == AnyChatAuth.currentUser!.id
                ? 8
                : (MediaQuery.of(context).size.width * 0.25),
            8),
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: sender!.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(sender!.photoUrl!),
                        backgroundColor: Colors.transparent,
                      )
                    : CircleAvatar(
                        child: Text(sender!.displayName!.substring(0, 1)),
                      )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sender!.displayName!,
                      style: Theme.of(context).textTheme.headlineSmall),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: text,
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
