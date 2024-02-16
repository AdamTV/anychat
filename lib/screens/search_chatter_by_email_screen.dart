import 'dart:async';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchChatterByEmailScreen extends StatefulWidget {
  static bool addToConvo = false;

  static String? searchValue;

  const SearchChatterByEmailScreen({Key? key}) : super(key: key);

  @override
  SearchChatterByEmailScreenState createState() =>
      SearchChatterByEmailScreenState(searchValue);
}

class SearchChatterByEmailScreenState
    extends State<SearchChatterByEmailScreen> {
  static String? searchValue;
  static Stream<QuerySnapshot>? searchResults;
  static List<AnyChatUser> users = <AnyChatUser>[];

  SearchChatterByEmailScreenState(String? searchValue) {
    SearchChatterByEmailScreenState.searchValue = searchValue;
    loadSearchResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SearchChatterByEmailScreen.addToConvo
            ? AppLocalizations.of(context)!.addSomeoneToConversation
            : AppLocalizations.of(context)!.startConversation),
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
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                AppLocalizations.of(context)!.title,
                style: TextStyle(color: Theme.of(context).primaryColorLight),
              ),
            ),
            ListTile(
                title: Text(AppLocalizations.of(context)!.backToConversations),
                onTap: () {
                  Navigator.pushNamed(context, "/conversations");
                }),
            ListTile(
                title: Text(AppLocalizations.of(context)!.logout),
                onTap: () async {
                  await AnyChatAuth.signOut();
                  Navigator.pushNamed(context, "/welcome");
                }),
          ],
        ),
      ),
      body: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: SearchChatterByEmailScreenState.users.isEmpty
              ? ListTile(
                  title: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          text: AppLocalizations.of(context)!.noResultsFound,
                          style: const TextStyle(color: Colors.grey))))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: SearchChatterByEmailScreenState.users.length,
                  itemBuilder: (BuildContext buildCtx, int index) {
                    return ListTile(
                        onTap: () async {
                          if (AnyChatAuth.currentConversation == null) {
                            var convo = await (AnyChatUser.createConversation(
                                SearchChatterByEmailScreenState
                                    .users[index].id));
                            AnyChatAuth.currentConversation = convo;
                            List<AnyChatUser> temp = <AnyChatUser>[];
                            for (var id in convo!.participants) {
                              if (id != AnyChatAuth.currentUser!.id) {
                                temp.add(AnyChatUser.fromSnapshot(
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(id)
                                        .get()));
                              }
                            }
                            AnyChatAuth.currentChatters = temp;
                          } else {
                            if (await AnyChatUser.addUserToConversation(
                                SearchChatterByEmailScreenState.users[index])) {
                              AnyChatAuth.currentChatters.add(
                                  SearchChatterByEmailScreenState.users[index]);
                            }
                          }
                          Navigator.pushReplacementNamed(context, "/chat");
                        },
                        leading: SearchChatterByEmailScreenState.users[index].photoUrl ==
                                null
                            ? CircleAvatar(
                                child: Text(SearchChatterByEmailScreenState
                                    .users[index].displayName!
                                    .substring(0, 1)))
                            : CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage: NetworkImage(
                                    SearchChatterByEmailScreenState
                                        .users[index].photoUrl!)),
                        title: RichText(
                            text: TextSpan(
                                text: SearchChatterByEmailScreenState
                                    .users[index].displayName,
                                style: const TextStyle(color: Colors.grey))));
                  },
                )),
    );
  }

  void loadSearchResults() async {
    users.clear();
    users.addAll(await AnyChatUser.findUsersByEmail(searchValue));
    users.addAll(await AnyChatUser.findUsersByDisplayName(searchValue));
    setState(() {});
  }
}
