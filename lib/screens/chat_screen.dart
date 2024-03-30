import 'dart:async';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/conversation.dart';
import 'package:anychat/components/conversation_info.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/search_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/combined_locale_info.dart';

// import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
  const ChatWindow({super.key});

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
        .where('participants', arrayContains: AnyChatAuth.currentUser.id)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}

class _ChatWindowState extends State<ChatWindow> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final List<MessageWidget> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  StreamSubscription<QuerySnapshot>? _chatMessageSubscription;

  List<AnyChatMessage> _chatMessages = <AnyChatMessage>[];

  @override
  void initState() {
    super.initState();
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

      AnyChatAuth.currentUser.conversations =
          await ConversationInfo.getAllConversationInfo(
              AnyChatAuth.currentUser.id);
      var info = AnyChatAuth.currentUser.conversations.firstWhere(
          (element) => element.id == AnyChatAuth.currentConversation!.id);
      // divide all chat messages into language for translation -> translate
      Map<String?, List<String?>> map = {};
      for (var message in _chatMessages) {
        final language = message.senderId == AnyChatAuth.currentUser.id
            ? info.outgoingLanguage
            : info.incomingLanguage;
        if (!map.containsKey(language)) {
          map.putIfAbsent(language, () => <String?>[]);
        }
        map[language]!.insert(0, message.text);
      }
      logger.d("chatMessage size: ${_chatMessages.length}");
      Map<String?, List<String>> translatedMap =
          await Utilities().getBatchGoogleTranslation(map);
      for (int i = 0; i < _chatMessages.length; i++) {
        if (!participants
            .any((element) => element.id == _chatMessages[i].senderId)) {
          participants.add(
              await AnyChatUser.getUserById(_chatMessages[i].senderId).onError(
                  (dynamic error, stackTrace) =>
                      AnyChatUser.deletedUser(_chatMessages[i].senderId)));
        }
        AnyChatUser sender = AnyChatUser.deletedUser(_chatMessages[i].senderId);
        try {
          sender = participants
              .firstWhere((element) => element.id == _chatMessages[i].senderId);
        } on Error catch (e) {
          // logger.e("Error",
          //     time: DateTime.now(), error: e, stackTrace: e.stackTrace);
          logger.e("Error", e, e.stackTrace);
          sender = AnyChatUser.deletedUser(_chatMessages[i].senderId);
        }
        final language = _chatMessages[i].senderId == AnyChatAuth.currentUser.id
            ? info.outgoingLanguage
            : info.incomingLanguage;
        if (translatedMap[language]!.isEmpty) break;
        var text = RichText(
          text: TextSpan(
            // Note: Styles for TextSpans must be explicitly defined.
            // Child text spans will inherit styles from parent
            style: Theme.of(
                    mounted ? context : Utilities().globalKey.currentContext!)
                .textTheme
                .bodyLarge
                ?.copyWith(
                    color: Theme.of(Utilities().globalKey.currentContext!)
                        .colorScheme
                        .onPrimaryContainer),
            children: <InlineSpan>[
              TextSpan(
                  text:
                      "${localizationOf(Utilities().globalKey.currentContext).typed}: ",
                  style: Theme.of(Utilities().globalKey.currentContext!)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                          color: Theme.of(Utilities().globalKey.currentContext!)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.bold)),
              TextSpan(text: "${_chatMessages[i].text}\n"),
              WidgetSpan(
                child: Divider(
                  indent: MediaQuery.of(mounted
                              ? context
                              : Utilities().globalKey.currentContext!)
                          .size
                          .width *
                      0.01,
                  endIndent: MediaQuery.of(mounted
                              ? context
                              : Utilities().globalKey.currentContext!)
                          .size
                          .width *
                      0.01,
                  color: Theme.of(mounted
                          ? context
                          : Utilities().globalKey.currentContext!)
                      .primaryColor,
                ),
              ),
              TextSpan(
                  text:
                      "\n${localizationOf(context).translation}: ",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: translatedMap[language]!.removeLast()),
            ],
          ),
        );
        final chatMessage = MessageWidget(
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
        .any((element) => element.sender?.id == _chatMessages.last.id)) {
      final message = _chatMessages.last;
      AnyChatUser sender = AnyChatUser.deletedUser(message.senderId);
      try {
        sender = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance
            .collection("users")
            .doc(_chatMessages.last.senderId)
            .get());
      } catch (e) {
        sender = AnyChatUser.deletedUser(message.senderId);
      }

      if (AnyChatAuth.currentUser.conversations.isEmpty) {
        AnyChatAuth.currentUser.conversations =
            await ConversationInfo.getAllConversationInfo(
                AnyChatAuth.currentUser.id);
      }

      logger
          .d("currentConvversation.id: ${AnyChatAuth.currentConversation!.id}");
      var info = AnyChatAuth.currentUser.conversations.firstWhere(
          (element) => element.id == AnyChatAuth.currentConversation!.id);
      final language = _chatMessages.last.senderId == AnyChatAuth.currentUser.id
          ? info.outgoingLanguage
          : info.incomingLanguage;
      var text = RichText(
        text: TextSpan(
          // Note: Styles for TextSpans must be explicitly defined.
          // Child text spans will inherit styles from parent
          style: mounted
              ? Theme.of(context).textTheme.bodyLarge
              : Theme.of(Utilities().globalKey.currentContext!)
                  .textTheme
                  .bodyLarge,
          children: <TextSpan>[
            TextSpan(
                text:
                    "${localizationOf(context).typed}: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: "${message.text}\n\n"),
            TextSpan(
                text:
                    "${localizationOf(context).translation}: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: await Utilities()
                    .getGoogleTranslation(language, message.text)),
          ],
        ),
      );
      final chatMessage = MessageWidget(
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
                    hintText: localizationOf(context).send_a_messgae),
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
                        child: Text(localizationOf(context).send),
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
        tooltip: localizationOf(context).language,
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) => _buildPopupDialog(context));
        }));
    widgets.add(IconButton(
      icon: const Icon(Icons.video_call_rounded),
      tooltip: localizationOf(context).call,
      onPressed: () async {
        await AnyChatUser.addMessageToConversation(
            "${AnyChatAuth.currentUser.displayName} ${localizationOf(context)
                    .isCallingYouOnAnyChat}");
        await NavigationService().pushNamed("/call");
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
          title: Text(Utilities()
              .getChatterDisplayNameString(AnyChatAuth.currentChatters)),
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
                localizationOf(context).title,
                style: TextStyle(color: Theme.of(context).primaryColorLight),
              ),
            ),
            ListTile(
                title: Text(localizationOf(context).addSomeoneToConversation),
                onTap: () {
                  NavigationService().push(MaterialPageRoute(
                    builder: (_) => const SearchChatterScreen(true, false),
                  ));
                }),
            ListTile(
                title: Text(localizationOf(context).leaveConversation),
                onTap: () {
                  AnyChatUser.deleteConversation(
                      context, AnyChatAuth.currentConversation!.id);
                }),
            ListTile(
                title: Text(localizationOf(context).backToConversations),
                onTap: () {
                  NavigationService().pushNamedAndRemoveUntil("/conversations",
                      predicate: (Route<dynamic> route) => route.isFirst);
                }),
            ListTile(
                title: Text(localizationOf(context).logout),
                onTap: () async {
                  await AnyChatAuth.signOut();
                  Navigator.pushNamed(
                      mounted ? context : Utilities().globalKey.currentContext!,
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
    for (MessageWidget message in _messages) {
      message.animationController!.dispose();
    }
    super.dispose();
  }

  _buildPopupDialog(BuildContext context) {
    var info = AnyChatAuth.currentUser.conversations.firstWhere(
        (element) => element.id == AnyChatAuth.currentConversation!.id);

    String? incomingDropdownValue =
        getEndonymByLocaleCode(info.incomingLanguage!, localizationOf(context));
    String? outgoingDropdownValue =
        getEndonymByLocaleCode(info.outgoingLanguage!, localizationOf(context));
    logger.d(incomingDropdownValue);
    return AlertDialog(
      title: Text(localizationOf(context).selectLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(localizationOf(context).incomingMessages),
          DropdownButton<String>(
            value: incomingDropdownValue,
            icon: const Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) async {
              var isoCode = getLocaleCodeByEndonym(newValue!, localizationOf(context));
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                var user = FirebaseFirestore.instance
                    .collection('users')
                    .doc(AnyChatAuth.currentUser.id);
                var userConversationInfo = user
                    .collection('conversations')
                    .doc(AnyChatAuth.currentConversation!.id);
                return transaction
                    .get(user)
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) async {
                  transaction.update(userConversationInfo, {
                    'incomingLanguage': isoCode,
                  });
                });
              });
              setState(() {
                info.incomingLanguage = isoCode;
                    incomingDropdownValue = newValue;
              });
              Navigator.pushNamed(
                  mounted ? context : Utilities().globalKey.currentContext!,
                  "/chat");
            },
            items: getLanguageDropdownMenuItems(context)

            // AnyChatLocale.isoMap.keys
            //     .map<DropdownMenuItem<String>>((String value) {
            //   return DropdownMenuItem<String>(
            //     value: value,
            //     child: Text(value),
            //   );
            // }).toList(),
          ),
          const Divider(height: 25),
          Text(localizationOf(context).outgoingMessages),
          DropdownButton<String>(
            value: outgoingDropdownValue,
            icon: const Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) async {
              var isoCode = getLocaleCodeByEndonym(newValue!, localizationOf(context));
              await FirebaseFirestore.instance
                  .runTransaction((Transaction transaction) {
                var user = FirebaseFirestore.instance
                    .collection('users')
                    .doc(AnyChatAuth.currentUser.id);
                var userConversationInfo = user
                    .collection('conversations')
                    .doc(AnyChatAuth.currentConversation!.id);
                return transaction
                    .get(user)
                    .then(
                        (DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
                    .then((AnyChatUser fresh) async {

                  transaction.update(userConversationInfo, {

                    'outgoingLanguage': isoCode
                  });
                });
              });
              setState(() {
                info.outgoingLanguage = isoCode;
                outgoingDropdownValue = newValue;
              });
              Navigator.pushNamed(
                  mounted ? context : Utilities().globalKey.currentContext!,
                  "/chat");
            },
            items: getLanguageDropdownMenuItems(context)
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String? id;
  final AnyChatUser? sender;
  final RichText? text;
  final AnimationController? animationController;

  const MessageWidget(
      {super.key, this.text, this.animationController, this.sender, this.id});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
      CurvedAnimation(parent: animationController!, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Align(
        alignment: sender?.id == AnyChatAuth.currentUser.id
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
              color: sender!.id == AnyChatAuth.currentUser.id
                  ? Theme.of(context).brightness == Brightness.dark
                  ? kDarkTheme.colorScheme.primaryContainer
                  : kLightTheme.colorScheme.primaryContainer
                  : Theme.of(context).brightness == Brightness.dark
                  ? kDarkTheme.colorScheme.secondaryContainer
                  : kLightTheme.colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.all(8.0),
          child: IntrinsicWidth(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    child: AnyChatUser.getAvatar(sender!)),
                    // sender!.photoUrl != ''
                    //     ? CircleAvatar(
                    //   backgroundImage: NetworkImage(sender!.photoUrl),
                    //   backgroundColor: Colors.transparent,
                    // )
                    //     : CircleAvatar(
                    //   child: Text(sender!.displayName.characters.first),
                    // )),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sender!.displayName,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Container(
                        margin: const EdgeInsets.only(top: 5.0),
                        padding: const EdgeInsets.only(right: 16.0),
                        child: text,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// TODO: FIX ANIMATION CONTROLLER FOR MESSAGE WIDGET
// class MessageWidget extends StatefulWidget {
//
//   final AnyChatUser? sender;
//   final RichText? text;
//   final AnimationController? animationController;
//
//   const MessageWidget({super.key, required RichText this.text, required AnimationController this.animationController, required AnyChatUser this.sender});
//
//   @override
//   State<MessageWidget> createState() => _MessageWidget();
// }
//
// class _MessageWidget extends State<MessageWidget> with SingleTickerProviderStateMixin {
//
//   late Duration duration;
//   late AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this, // the SingleTickerProviderStateMixin
//       duration: Duration(milliseconds: 250),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SizeTransition(
//       sizeFactor:
//           CurvedAnimation(parent: _controller!, curve: Curves.easeOut),
//       axisAlignment: 0.0,
//       child: Align(
//         alignment: super.widget.sender?.id == AnyChatAuth.currentUser.id
//             ? Alignment.centerRight
//             : Alignment.centerLeft,
//         child: Container(
//           decoration: BoxDecoration(
//               color: super.widget.sender!.id == AnyChatAuth.currentUser.id
//                   ? Theme.of(context).brightness == Brightness.dark
//                       ? kDarkTheme.colorScheme.primaryContainer
//                       : kLightTheme.colorScheme.primaryContainer
//                   : Theme.of(context).brightness == Brightness.dark
//                       ? kDarkTheme.colorScheme.secondaryContainer
//                       : kLightTheme.colorScheme.secondaryContainer,
//               borderRadius: const BorderRadius.all(Radius.circular(20))),
//           padding: const EdgeInsets.all(8.0),
//           margin: const EdgeInsets.all(8.0),
//           child: IntrinsicWidth(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                     margin: const EdgeInsets.only(right: 16.0),
//                     child: AnyChatUser.getAvatar(super.widget.sender!)),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(super.widget.sender!.displayName,
//                           style: Theme.of(context).textTheme.headlineSmall),
//                       Container(
//                         margin: const EdgeInsets.only(top: 5.0),
//                         padding: const EdgeInsets.only(right: 16.0),
//                         child: super.widget.text,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
