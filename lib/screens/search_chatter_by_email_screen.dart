import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchChatterByEmailScreen extends StatefulWidget {
  static bool addToConvo = false;

  static String? searchValue;

  // Null safety
  static String? getSearchValue() {
    searchValue ??= '';
    return searchValue;
  }

  const SearchChatterByEmailScreen({Key? key}) : super(key: key);

  @override
  SearchChatterByEmailScreenState createState() =>
      SearchChatterByEmailScreenState();
}

class SearchChatterByEmailScreenState
    extends State<SearchChatterByEmailScreen> {
  var stream = FirebaseFirestore.instance
      .collection('users')
      .where(
        'email',
        isNull: false,
        isEqualTo: SearchChatterByEmailScreen.getSearchValue(),
      )
      .snapshots();

  var stream2 = FirebaseFirestore.instance
      .collection('users')
      .where(
        'displayName',
        isEqualTo: SearchChatterByEmailScreen.getSearchValue(),
      )
      .snapshots();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.search),
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
                          style: TextStyle(
                              color: Theme.of(context).primaryColorLight),
                        ),
                      ),
                      ListTile(
                          title: Text(AppLocalizations.of(context)!
                              .backToConversations),
                          onTap: () {
                            Navigator.pushNamed(context, "/conversations");
                          }),
                      ListTile(
                          title: Text(AppLocalizations.of(context)!.logout),
                          onTap: () async {
                            await AnyChatAuth.signOut();
                            if (context.mounted) {
                              Navigator.pushNamed(context, "/welcome");
                            }
                          }),
                    ],
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()));
          }
          List<QueryDocumentSnapshot<Object?>> users = snapshot.data!.docs;
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
                        style: TextStyle(
                            color: Theme.of(context).primaryColorLight),
                      ),
                    ),
                    ListTile(
                        title: Text(
                            AppLocalizations.of(context)!.backToConversations),
                        onTap: () {
                          Navigator.pushNamed(context, "/conversations");
                        }),
                    ListTile(
                        title: Text(AppLocalizations.of(context)!.logout),
                        onTap: () async {
                          await AnyChatAuth.signOut();
                          if (context.mounted) {
                            Navigator.pushNamed(context, "/welcome");
                          }
                        }),
                  ],
                ),
              ),
              body: Container(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: snapshot.data!.docs.isEmpty
                      ? ListTile(
                          title: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                  text: AppLocalizations.of(context)!
                                      .noResultsFound,
                                  style: const TextStyle(color: Colors.grey))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: users.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                                onTap: () async {
                                  if (AnyChatAuth.currentConversation == null) {
                                    var convo =
                                        await (AnyChatUser.createConversation(
                                            users[index].id));
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
                                        AnyChatUser.fromSnapshot(
                                            users[index]))) {
                                      AnyChatAuth.currentChatters.add(
                                          AnyChatUser.fromSnapshot(
                                              users[index]));
                                    }
                                  }
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                        context, "/chat");
                                  }
                                },
                                leading: AnyChatUser.fromSnapshot(users[index]).photoUrl == null
                                    ? CircleAvatar(
                                        child: Text(
                                            AnyChatUser.fromSnapshot(users[index])
                                                .displayName!
                                                .substring(0, 1)))
                                    : CircleAvatar(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        backgroundImage: NetworkImage(
                                            AnyChatUser.fromSnapshot(users[index])
                                                .photoUrl!)),
                                title: RichText(
                                    text: TextSpan(
                                        text: AnyChatUser.fromSnapshot(users[index])
                                            .displayName,
                                        style: const TextStyle(color: Colors.grey))));
                          },
                        )));
        });
  }
}
