// import 'package:anychat/components/anychat_auth.dart';
// import 'package:anychat/components/anychat_user.dart';
// import 'package:anychat/components/rounded_input_field.dart';
// import 'package:anychat/components/utilities.dart';
// import 'package:anychat/screens/blocked_users_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// class BlockChatterSearchScreen extends StatefulWidget {
//   const BlockChatterSearchScreen({super.key});
//
//   @override
//   State<BlockChatterSearchScreen> createState() =>
//       _BlockChatterSearchScreenState();
// }
//
// class _BlockChatterSearchScreenState extends State<BlockChatterSearchScreen> {
//   String? searchValue;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text(AppLocalizations.of(context)!.blockAccount),
//         ),
//         body: Center(
//             child: Container(
//                 constraints: const BoxConstraints(maxWidth: 1280),
//                 child: Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: <Widget>[
//                       TextField(
//                           decoration: InputDecoration.collapsed(
//                               hintText:
//                                   "${AppLocalizations.of(context)!.findSomeoneByName} ${AppLocalizations.of(context)!.or} ${AppLocalizations.of(context)!.email}"),
//                           onChanged: (value) {
//                             searchValue = value;
//                           }),
//                       ElevatedButton(
//                           child: Text(AppLocalizations.of(context)!.search),
//                           onPressed: () {
//                             Navigator.push(context, MaterialPageRoute(
//                                 builder: (BuildContext context) {
//                               return SearchResults(searchValue: searchValue);
//                             }));
//                           }),
//                     ],
//                   ),
//                 ))));
//   }
// }
//
// class SearchResults extends StatefulWidget {
//   final String? searchValue;
//
//   const SearchResults({super.key, this.searchValue});
//
//   @override
//   State<SearchResults> createState() => _SearchResultsState();
// }
//
// class _SearchResultsState extends State<SearchResults> {
//   List<AnyChatUser> users = [];
//
//   _SearchResultsState();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text(AppLocalizations.of(context)!.blockAccount),
//         ),
//         body: Container(
//             constraints: const BoxConstraints(maxWidth: 1280),
//             child: users.isEmpty
//                 ? ListTile(
//                     title: RichText(
//                         textAlign: TextAlign.center,
//                         text: TextSpan(
//                             text: AppLocalizations.of(context)!.noResultsFound,
//                             style: const TextStyle(color: Colors.grey))))
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(8.0),
//                     itemCount: users.length,
//                     itemBuilder: (BuildContext ctx, int index) {
//                       return ListTile(
//                           onTap: () async {
//                             await AnyChatAuth.currentUser
//                                 .blockAccount(users[index].id);
//                             Navigator.push(
//                                 mounted
//                                     ? context
//                                     : Utilities().globalKey.currentContext!,
//                                 MaterialPageRoute(builder: (BuildContext ctx) {
//                               return const BlockedUsersScreen();
//                             }));
//                           },
//                           leading: users[index].photoUrl == ''
//                               ? CircleAvatar(
//                                   child: Text(
//                                       users[index].displayName.substring(0, 1)))
//                               : CircleAvatar(
//                                   backgroundColor:
//                                       Theme.of(context).primaryColor,
//                                   backgroundImage:
//                                       NetworkImage(users[index].photoUrl)),
//                           title: RichText(
//                               text: TextSpan(
//                                   text: users[index].displayName,
//                                   style: const TextStyle(color: Colors.grey))));
//                     })));
//   }
//
//   void loadSearchResults(String? searchValue) async {
//     users.clear();
//     users.addAll(await AnyChatUser.findUsersByEmail(searchValue));
//     users.addAll(await AnyChatUser.findUsersByDisplayName(searchValue));
//     setState(() {});
//   }
// }
