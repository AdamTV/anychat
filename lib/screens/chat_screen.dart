import 'dart:async';

import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_message.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/database/conversation_info.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/search_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/widgets/anychat_drawer.dart';
import 'package:anychat/widgets/message_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      final userIds = <String>{
        ...convo.participants,
        ..._chatMessages.map((message) => message.senderId),
      };
      final loadedUsers = await AnyChatUser.getUsersByIds(userIds);
      final participantsById = {
        for (final user in loadedUsers) user.id: user,
      };
      for (final id in userIds) {
        participantsById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
      }
      final participants = participantsById.values.toList();
      AnyChatAuth.currentChatters = participants
          .where((user) => user.id != AnyChatAuth.currentUser.id)
          .toList();

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
        final sender = participantsById[_chatMessages[i].senderId]!;
        final language = _chatMessages[i].senderId == AnyChatAuth.currentUser.id
            ? info.outgoingLanguage
            : info.incomingLanguage;
        if (translatedMap[language]!.isEmpty) break;
        var text = RichText(
          text: TextSpan(
            // Note: Styles for TextSpans must be explicitly defined.
            // Child text spans will inherit styles from parent
            style: Theme.of(Utilities().globalKey.currentContext!).textTheme.bodyLarge?.copyWith(
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
                  indent: MediaQuery.of(Utilities().globalKey.currentContext!).size.width * 0.01,
                  endIndent: MediaQuery.of(Utilities().globalKey.currentContext!).size.width * 0.01,
                  color: Theme.of(Utilities().globalKey.currentContext!).primaryColor,
                ),
              ),
              TextSpan(
                  text:
                      "\n${localizationOf(Utilities().globalKey.currentContext!).translation}: ",
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
        chatMessage.animationController.forward();
      }

      setState(() {
        _isLoading = false;
      });
    } else if (!_messages
        .any((element) => element.sender.id == _chatMessages.last.id)) {
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
          style: Theme.of(Utilities().globalKey.currentContext!).textTheme.bodyLarge,
          children: <TextSpan>[
            TextSpan(
                text: "${localizationOf(Utilities().globalKey.currentContext!).typed}: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: "${message.text}\n\n"),
            TextSpan(
                text: "${localizationOf(Utilities().globalKey.currentContext!).translation}: ",
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
        chatMessage.animationController.forward();
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
          showDialog<void>(
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
      drawer: AnyChatDrawer(entries: [
        AnyChatDrawerEntry(
          title: localizationOf(context).addSomeoneToConversation,
          onTap: () {
            NavigationService().push(MaterialPageRoute(
              builder: (_) => const SearchChatterScreen(true, false),
            ));
          },
        ),
        AnyChatDrawerEntry(
          title: localizationOf(context).leaveConversation,
          onTap: () {
            AnyChatUser.deleteConversation(
                context, AnyChatAuth.currentConversation!.id);
          },
        ),
        AnyChatDrawerEntry(
          title: localizationOf(context).backToConversations,
          onTap: () {
            NavigationService()
                .popUntil((p0) => p0.settings.name == "/conversations");
          },
        ),
        AnyChatDrawerEntry(
          title: localizationOf(context).logout,
          onTap: () async {
            await NavigationService().pushNamedAndRemoveUntil('/welcome',
                predicate: (p0) => p0.isFirst);
            await AnyChatAuth.signOut();
          },
        ),
      ]),
      body: container,
    );
  }

  @override
  void dispose() {
    _chatMessageSubscription?.cancel();
    for (MessageWidget message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  Widget _buildPopupDialog(BuildContext context) {
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
          _buildLanguageDropdown(
            dropdownValue: incomingDropdownValue,
            icon: Icons.translate,
            languageField: 'incomingLanguage',
            onSelectionChanged: (isoCode, newValue) => setState(() {
              info.incomingLanguage = isoCode;
              incomingDropdownValue = newValue;
            }),
          ),
          const Divider(height: 25),
          Text(localizationOf(context).outgoingMessages),
          _buildLanguageDropdown(
            dropdownValue: outgoingDropdownValue,
            icon: Icons.keyboard,
            languageField: 'outgoingLanguage',
            onSelectionChanged: (isoCode, newValue) => setState(() {
              info.outgoingLanguage = isoCode;
              outgoingDropdownValue = newValue;
            }),
          ),
        ],
      ),
    );
  }

  /// A dropdown that persists the selected language for [languageField] to
  /// Firestore, then reports the change through [onSelectionChanged].
  Widget _buildLanguageDropdown({
    required String? dropdownValue,
    required IconData icon,
    required String languageField,
    required void Function(String isoCode, String newValue) onSelectionChanged,
  }) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: Icon(icon),
      iconSize: 24,
      elevation: 16,
      onChanged: (String? newValue) async {
        final isoCode =
            getLocaleCodeByEndonym(newValue!, localizationOf(context));
        await FirebaseFirestore.instance
            .runTransaction((Transaction transaction) {
          final user = FirebaseFirestore.instance
              .collection('users')
              .doc(AnyChatAuth.currentUser.id);
          final userConversationInfo = user
              .collection('conversations')
              .doc(AnyChatAuth.currentConversation!.id);
          return transaction
              .get(user)
              .then((DocumentSnapshot doc) => AnyChatUser.fromSnapshot(doc))
              .then((AnyChatUser fresh) async {
            transaction.update(userConversationInfo, {languageField: isoCode});
          });
        });
        onSelectionChanged(isoCode, newValue);
        NavigationService().pushNamed("/chat");
      },
      items: getLanguageDropdownMenuItems(context),
    );
  }
}
