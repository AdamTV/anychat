import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/database/conversation.dart';
import 'package:anychat/components/notification_observer.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/database/conversation_info.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/widgets/anychat_drawer.dart';
import 'package:anychat/widgets/chat_screen_utility_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../components/combined_locale_info.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Slidable> conversationWidgets = [];
  bool _isLoadedConversations = false;

  @override
  initState() {
    super.initState();
    readConversations();
    _handleRefresh();
    // RemoteNotificationObserver().initConversationSubscriptions(_updateConversations);
  }

  void createConversations() {
    if (RemoteNotificationObserver().conversationWidgets.isEmpty) return;
    var mostRecentState = RemoteNotificationObserver().conversationWidgets.last;
    setState((){
      insertSorted(
        mostRecentState);
      _isLoadedConversations = true;
      });
    }

  Future<void> readConversations() async {
    await RemoteNotificationObserver().initChatSubscriptions();
  }

  Future<void> updateConversations(QuerySnapshot snapshot) async {
    if (conversationWidgets.isEmpty) {
      await RemoteNotificationObserver().loadConversations();
      return;
    }
    final conversations =
        RemoteNotificationObserver().getConversationsFromQuery(snapshot);
    if (conversations.isEmpty) {
      return;
    }
    final conversation = conversations.last;
    final currentUserId = AnyChatAuth.currentUser.id;
    if (!conversation.participants.contains(currentUserId)) {
      logger.d('conversation participants do not contain $currentUserId');
      return;
    }
    final chatterIds = conversation.participants
        .where((id) => id != currentUserId)
        .toSet();
    final loadedUsers = await AnyChatUser.getUsersByIds(chatterIds);
    final usersById = {for (final user in loadedUsers) user.id: user};
    for (final id in chatterIds) {
      usersById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
    }
    final chatters = chatterIds.map((id) => usersById[id]!).toList();
    final firstChatter = chatterIds.isEmpty
        ? AnyChatAuth.currentUser
        : usersById[chatterIds.first]!;

    if (AnyChatAuth.currentConversation == null) {
      await RemoteNotificationObserver().initConversationInfo();
    }
    if (!AnyChatAuth.currentUser.conversations
        .any((element) => element.id == conversation.id)) {
      AnyChatAuth.currentUser.conversations.add(ConversationInfo(
        conversation.id,
        AnyChatAuth.currentUser.language,
        firstChatter.language,
      ));
    }

    if (chatters.isNotEmpty && conversation.timestamp != null) {
      final state = RemoteNotificationObserver().conversationWidgets.last;
      setState(() {
        insertSorted(state);
        _isLoadedConversations = true;
      });
    }
    if (!conversationWidgets
        .any((element) => element.key == Key(conversation.id))) {
      RemoteNotificationObserver().addChatMessageSubscription(conversation.id);

      logger.d('added conversation widget');
      logger.d(conversationWidgets);
    }
  }

  void deleteConversations() {}

  @override
  Widget build(BuildContext context) {
    // Subscribe to the observer so this screen rebuilds on its updates.
    context.watch<RemoteNotificationObserver>();
    createConversations();
    logger.d(
        'in build -> conversationWidgets.length: ${conversationWidgets.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text(localizationOf(context).title),
        actions: <Widget>[
          if (conversationWidgets.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: localizationOf(context).createConversation,
              onPressed: () {
                AnyChatAuth.currentConversation = null;
                NavigationService().pushNamed("/searchChatter");
              },
            ),
        ],
      ),
      drawer: AnyChatDrawer(entries: [
        AnyChatDrawerEntry(
          title: localizationOf(context).liveTranslator,
          onTap: () async {
            if (await Utilities().handlePermission(Permission.microphone)) {
              NavigationService().pushNamed("/liveTranslator");
            }
          },
        ),
        AnyChatDrawerEntry(
          title: localizationOf(context).settings,
          onTap: () {
            NavigationService().pushNamed("/settings");
          },
        ),
        AnyChatDrawerEntry(
          title: localizationOf(context).logout,
          onTap: () async {
            await NavigationService().pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const WelcomeScreen()),
                (p0) => p0.isFirst);
            await AnyChatAuth.signOut();
          },
        ),
      ]),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          children: [
            Align(
                alignment: conversationWidgets.isEmpty
                    ? Alignment.center
                    : Alignment.topCenter,
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: _isLoadedConversations
                        ? conversationWidgets.isEmpty
                            ? refreshableEmptyConversationWidget() // see definition below
                            : ListView.separated(
                                separatorBuilder: (context, index) => Divider(
                                  indent:
                                      MediaQuery.of(context).size.width * 0.25,
                                  endIndent:
                                      MediaQuery.of(context).size.width * 0.25,
                                  color: Theme.of(context).dividerColor,
                                ),
                                itemCount: conversationWidgets.length,
                                itemBuilder: (_, int index) =>
                                    conversationWidgets[index],
                              )
                        : Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    AnyChatAuth.currentUser.conversations =
        await ConversationInfo.getAllConversationInfo(
            AnyChatAuth.currentUser.id);
    final loadedConversations = await Conversation.getConversationsByIds(
      AnyChatAuth.currentUser.conversations.map((info) => info.id),
    );
    final userIds = loadedConversations
        .expand((conversation) => conversation.participants)
        .toSet();
    final loadedUsers = await AnyChatUser.getUsersByIds(userIds);
    final usersById = {for (final user in loadedUsers) user.id: user};
    for (final id in userIds) {
      usersById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
    }

    final refreshedWidgets = <AnyChatConversationWidget>[];
    for (final conversation in loadedConversations) {
      final chatters = conversation.participants
          .map((id) => usersById[id]!)
          .toList();
      final message =
          await Conversation.getLatestMessageByConversationId(conversation.id);
      if (message == null) {
        continue;
      }
      refreshedWidgets
          .add(AnyChatConversationWidget(chatters, conversation, message));
    }

    if (!mounted || refreshedWidgets.isEmpty) {
      return;
    }
    setState(() {
      for (final widget in refreshedWidgets) {
        insertSorted(widget);
      }
    });
  }

// If the conversation list is empty, still allow pull-to-refresh:
  Widget refreshableEmptyConversationWidget() => RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                child: Text(localizationOf(context).startConversation),
                onPressed: () {
                  AnyChatAuth.currentConversation = null;
                  NavigationService().pushNamed("/searchChatter");
                },
              ),
            ],
          ),
        ),
      );

  Map<String, Timestamp?> convoTimes = {};
  void insertSorted(AnyChatConversationWidget state) {
    convoTimes.putIfAbsent(state.conversation.id.toString(), () => state.message.timestamp);
    final sortedTimes = convoTimes.keys.toList(growable: false)
      ..sort((k1, k2) => convoTimes[k2]!.compareTo(convoTimes[k1]!));
    logger.d(sortedTimes);
    var index = sortedTimes.indexOf(state.conversation.id);
    conversationWidgets.removeWhere((element) => element.key == state.getSlidable().key);
    if (!state.conversation.participants.any((element) =>
        AnyChatAuth.currentUser.blockedAccounts.contains(element))) {
        _isLoadedConversations = true;
        conversationWidgets.insert(index, state.getSlidable());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
