import 'dart:async';

import 'package:anychat/components/composer_guard.dart';
import 'package:anychat/components/message_reconciler.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_message.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/database/conversation_info.dart';
import 'package:anychat/database/sms_conversation.dart';
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
  final _composer = ComposerSendGuard();
  final _reconciler = MessageReconciler();
  List<TranslatedMessage> _visibleMessages = [];
  final Map<String, AnimationController> _animations = {};
  final Map<String, AnyChatUser> _participantsById = {};
  late final String _conversationId;
  late final String _currentUserId;
  ConversationInfo? _conversationInfo;
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  StreamSubscription<QuerySnapshot>? _chatMessageSubscription;

  @override
  void initState() {
    super.initState();
    _conversationId = AnyChatAuth.currentConversation!.id;
    _currentUserId = AnyChatAuth.currentUser.id;
    _chatMessageSubscription ??= ChatWindow.loadAllChatMessages().listen(
      _updateChatWindow,
    );
  }

  List<AnyChatMessage> getChatMessagesFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).toList();
  }

  Future<void> _updateChatWindow(QuerySnapshot snapshot) async {
    try {
      final applied = await _reconciler.reconcile(
        getChatMessagesFromQuery(snapshot),
        _translateMessages,
      );
      if (!mounted || !applied) return;
      final messages = _reconciler.messages.reversed.toList();
      final ids = messages.map((entry) => entry.message.id!).toSet();
      final removed = _animations.keys
          .where((id) => !ids.contains(id))
          .toList();
      for (final id in removed) {
        _animations.remove(id)!.dispose();
      }
      for (final id in ids) {
        _animations.putIfAbsent(id, () {
          final controller = AnimationController(
            duration: Duration(milliseconds: _isLoading ? 0 : 700),
            vsync: this,
          );
          controller.forward();
          return controller;
        });
      }
      setState(() {
        _visibleMessages = messages;
        _isLoading = false;
      });
    } catch (_) {
      // Translation failures must not leak request URLs/keys into the UI or
      // prevent later snapshots from being reconciled.
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChatContext(List<AnyChatMessage> messages) async {
    if (_conversationInfo == null) {
      final conversation = await Conversation.getConversationById(
        _conversationId,
      );
      if (!mounted) return;
      final userIds = {
        ...conversation.participants,
        ...messages.map((message) => message.senderId),
      };
      final users = await AnyChatUser.getUsersByIds(userIds);
      if (!mounted) return;
      _participantsById.addAll({for (final user in users) user.id: user});
      for (final id in userIds) {
        _participantsById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
      }
      AnyChatAuth.currentChatters = conversation.participants
          .where((id) => id != _currentUserId)
          .map((id) => _participantsById[id]!)
          .toList();
      final infos = await ConversationInfo.getAllConversationInfo(
        _currentUserId,
      );
      if (!mounted) return;
      AnyChatAuth.currentUser.conversations = infos;
      _conversationInfo = infos.firstWhere(
        (info) => info.id == _conversationId,
      );
    }
    final missingIds = messages
        .map((message) => message.senderId)
        .where((id) => !_participantsById.containsKey(id))
        .toSet();
    if (missingIds.isEmpty) return;
    final users = await AnyChatUser.getUsersByIds(missingIds);
    if (!mounted) return;
    _participantsById.addAll({for (final user in users) user.id: user});
    for (final id in missingIds) {
      _participantsById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
    }
  }

  Future<Map<String, String>> _translateMessages(
    List<AnyChatMessage> messages,
  ) async {
    await _loadChatContext(messages);
    if (!mounted) return {};
    final info = _conversationInfo!;
    String? languageOf(AnyChatMessage message) =>
        message.senderId == _currentUserId
        ? info.outgoingLanguage
        : info.incomingLanguage;
    final grouped = <String?, List<String?>>{};
    for (final message in messages) {
      grouped.putIfAbsent(languageOf(message), () => []).add(message.text);
    }
    final translated = await Utilities().getBatchGoogleTranslation(grouped);
    final offsets = <String?, int>{};
    return {
      for (final message in messages)
        message.id!:
            translated[languageOf(message)]![offsets.update(
              languageOf(message),
              (value) => value + 1,
              ifAbsent: () => 0,
            )],
    };
  }

  Widget _buildMessage(TranslatedMessage entry) {
    final message = entry.message;
    return MessageWidget(
      key: ValueKey(message.id),
      message: message,
      sender: _participantsById[message.senderId]!,
      animationController: _animations[message.id]!,
      text: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          children: [
            TextSpan(
              text: '${localizationOf(context).typed}: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: '${message.text}\n\n'),
            TextSpan(
              text: '${localizationOf(context).translation}: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: entry.translation),
          ],
        ),
      ),
    );
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
                controller: _composer.controller,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
                decoration: InputDecoration.collapsed(
                  hintText: localizationOf(context).send_a_messgae,
                ),
                focusNode: _focusNode,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? CupertinoButton(
                      onPressed: _isComposing
                          ? () => _handleSubmitted(_composer.controller.text)
                          : null,
                      child: Text(localizationOf(context).send),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isComposing
                          ? () => _handleSubmitted(_composer.controller.text)
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    // The guard ignores a second submit while the first is in flight, clears
    // the composer only after the provider accepts it, and restores the draft
    // on failure so a failed save is never lost as if sent.
    await _composer.send(
      text,
      onError: () {
        if (!mounted) return;
        Utilities().showToast(localizationOf(context).unableToSendMessage);
      },
    );
    if (mounted) _focusNode.requestFocus();
  }

  bool _isLoading = true;

  String? displayName;

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    widgets.add(
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: localizationOf(context).language,
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext context) => _buildPopupDialog(context),
          );
        },
      ),
    );
    // The alpha-text bridge is SMS-only: a call would text the contact
    // "is calling you" and open a call screen nobody can join.
    if (!isSmsConversationId(AnyChatAuth.currentConversation?.id)) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.video_call_rounded),
          tooltip: localizationOf(context).call,
          onPressed: () async {
            await AnyChatUser.addMessageToConversation(
              "${AnyChatAuth.currentUser.displayName} ${localizationOf(context).isCallingYouOnAnyChat}",
            );
            await NavigationService().pushNamed("/call");
          },
        ),
      );
    }
    SizedBox container = SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _isLoading
            ? [
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.secondary,
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ]
            : [
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemBuilder: (_, int index) =>
                        _buildMessage(_visibleMessages[index]),
                    itemCount: _visibleMessages.length,
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
        title: Text(
          Utilities().getChatterDisplayNameString(AnyChatAuth.currentChatters),
        ),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        actions: widgets,
      ),
      drawer: AnyChatDrawer(
        entries: [
          AnyChatDrawerEntry(
            title: localizationOf(context).addSomeoneToConversation,
            onTap: () {
              NavigationService().push(
                MaterialPageRoute(
                  builder: (_) => const SearchChatterScreen(true, false),
                ),
              );
            },
          ),
          AnyChatDrawerEntry(
            title: localizationOf(context).leaveConversation,
            onTap: () {
              AnyChatUser.deleteConversation(
                context,
                AnyChatAuth.currentConversation!.id,
              );
            },
          ),
          AnyChatDrawerEntry(
            title: localizationOf(context).backToConversations,
            onTap: () {
              NavigationService().popUntil(
                (p0) => p0.settings.name == "/conversations",
              );
            },
          ),
          AnyChatDrawerEntry(
            title: localizationOf(context).logout,
            onTap: () async {
              await NavigationService().pushNamedAndRemoveUntil(
                '/welcome',
                predicate: (p0) => p0.isFirst,
              );
              await AnyChatAuth.signOut();
            },
          ),
        ],
      ),
      body: container,
    );
  }

  @override
  void dispose() {
    _chatMessageSubscription?.cancel();
    _reconciler.dispose();
    for (final controller in _animations.values) {
      controller.dispose();
    }
    _animations.clear();
    _composer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildPopupDialog(BuildContext context) {
    var info = AnyChatAuth.currentUser.conversations.firstWhere(
      (element) => element.id == AnyChatAuth.currentConversation!.id,
    );

    String? incomingDropdownValue = getEndonymByLocaleCode(
      info.incomingLanguage!,
      localizationOf(context),
    );
    String? outgoingDropdownValue = getEndonymByLocaleCode(
      info.outgoingLanguage!,
      localizationOf(context),
    );
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
        final isoCode = getLocaleCodeByEndonym(
          newValue!,
          localizationOf(context),
        );
        await FirebaseFirestore.instance.runTransaction((
          Transaction transaction,
        ) {
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
                transaction.update(userConversationInfo, {
                  languageField: isoCode,
                });
              });
        });
        if (!mounted) return;
        onSelectionChanged(isoCode, newValue);
        NavigationService().pushNamed("/chat");
      },
      items: getLanguageDropdownMenuItems(context),
    );
  }
}
