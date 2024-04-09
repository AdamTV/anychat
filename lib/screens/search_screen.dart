import 'dart:async';

import 'package:anychat/components/combined_locale_info.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';

class SearchChatterScreen extends StatefulWidget {
  final bool addToConvo;
  final bool blockUser;

  const SearchChatterScreen(this.addToConvo, this.blockUser, {super.key});

  @override
  SearchChatterScreenState createState() => SearchChatterScreenState();
}

class SearchChatterScreenState extends State<SearchChatterScreen> {
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _searchSubscription;
  List<AnyChatUser> _users = [];
  Timer? _debounce;

  bool get addToConvo => super.widget.addToConvo;
  bool get blockUser => super.widget.blockUser;

  _onSearchChanged() {
    Timer(const Duration(milliseconds: 250), (){
    _searchSubscription?.cancel();
        // if (_debounce?.isActive ?? false) _debounce?.cancel();
        // _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchSubscription = searchUsersDynamically(_searchController.text)
        ?.listen((QuerySnapshot snapshot) {
      final List<AnyChatUser> newUsers =
      snapshot.docs.map((doc) => AnyChatUser.fromSnapshot(doc)).toList();
      setState(() {
        _users = newUsers;
      });
      // });
    });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? searchUsersDynamically(
      String searchText) {
    if (searchText.isEmpty) return null;
    final usersRef = FirebaseFirestore.instance.collection('users');
    String searchUpperBound = searchText.substring(0, searchText.length - 1) +
        String.fromCharCode(searchText.codeUnitAt(searchText.length - 1) + 1);

    // Convert Future<QuerySnapshot> to Stream<QuerySnapshot>
    Stream<QuerySnapshot<Map<String, dynamic>>> displayNameStream = usersRef
        .where('displayName', isGreaterThanOrEqualTo: searchText)
        .where('displayName', isLessThan: searchUpperBound)
        .snapshots();

    Stream<QuerySnapshot<Map<String, dynamic>>> emailStream = usersRef
        .where('email', isGreaterThanOrEqualTo: searchText)
        .where('email', isLessThan: searchUpperBound)
        .snapshots();

    // Use StreamGroup to merge the streams
    StreamGroup<QuerySnapshot<Map<String, dynamic>>> streamGroup =
        StreamGroup<QuerySnapshot<Map<String, dynamic>>>();
    streamGroup.add(displayNameStream);
    streamGroup.add(emailStream);

    // Merge and convert back to a single stream
    return streamGroup.stream.map((querySnapshot) {
      // Here, you can handle the merged data. For now, it just forwards each QuerySnapshot
      return querySnapshot;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.only(
              right: 20,
              left: MediaQuery.of(context).orientation == Orientation.landscape
                  ? 20
                  : 0),
          // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            NavigationService().goBack();
          },
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        actions: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            width: MediaQuery.of(context).size.width * 0.95,
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(left: 20, bottom: 5),
                labelText: localizationOf(context).search,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Flex(
        direction: Axis.horizontal,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                const double containerRadius = kIsWeb ? 45 : 55.0;
                const double avatarRadius = containerRadius / 2;
                final user = _users[index];
                return ListTile(
                  title: Text(user.displayName),
                  leading: SizedBox(
                    height: avatarRadius,
                    width: avatarRadius,
                    child: AnyChatUser.getAvatar(user),
                  ),
                  onTap: () async {
                    if (blockUser) {
                      await AnyChatAuth.currentUser.blockAccount(user.id);
                      NavigationService().pushReplacementNamed("/blockedUsers");
                    } else if (addToConvo) {
                      await AnyChatUser.addUserToConversation(user);
                    } else {
                      await AnyChatUser.createConversation(user);
                    }
                    NavigationService().pushReplacementNamed("/chat");
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
