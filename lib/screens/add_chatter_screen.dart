// import 'package:anychat/components/anychat_auth.dart';
// import 'package:anychat/components/rounded_input_field.dart';
// import 'package:anychat/components/utilities.dart';
// import 'package:anychat/screens/search_screen.dart';
// import 'package:anychat/services/navigation_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// class AddChatterScreen extends StatefulWidget {
//   const AddChatterScreen({super.key});
//
//   @override
//   State<AddChatterScreen> createState() => _AddChatterScreenState();
// }
//
// class _AddChatterScreenState extends State<AddChatterScreen> {
//   String? searchValue;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           //leading: Icon(Icons.restaurant),
//           title: Text(SearchChatterByEmailScreen.addToConvo
//               ? AppLocalizations.of(context)!.addSomeoneToConversation
//               : AppLocalizations.of(context)!.startConversation),
//           // bottom: PreferredSize(
//           //   preferredSize: Size(320, 48),
//           //   child: Padding(
//           //     padding: EdgeInsets.fromLTRB(6, 0, 6, 4),
//           //     child: FilterBar(
//           //       filter: _filter,
//           //       onPressed: _onFilterBarPressed,
//           //     ),
//           //   ),
//           // ),
//         ),
//         drawer: Drawer(
//           // Add a ListView to the drawer. This ensures the user can scroll
//           // through the options in the drawer if there isn't enough vertical
//           // space to fit everything.
//           child: ListView(
//             // Important: Remove any padding from the ListView.
//             padding: EdgeInsets.zero,
//             children: <Widget>[
//               DrawerHeader(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor,
//                 ),
//                 child: Text(
//                   AppLocalizations.of(context)!.title,
//                   style: TextStyle(color: Theme.of(context).primaryColorLight),
//                 ),
//               ),
//               ListTile(
//                   title: Text(AppLocalizations.of(context)!.conversations),
//                   onTap: () {
//                     NavigationService().pushNamedAndRemoveUntil(
//                         "/conversations",
//                         predicate: (Route<dynamic> route) => route.isFirst);
//                     //_handleSignOut();
//                   }),
//               ListTile(
//                   title: Text(AppLocalizations.of(context)!.logout),
//                   onTap: () async {
//                     await AnyChatAuth.signOut();
//                     Navigator.pushNamed(
//                         context.mounted
//                             ? context
//                             : Utilities().globalKey.currentContext!,
//                         "/welcome");
//                     //_handleSignOut();
//                   }),
//             ],
//           ),
//         ),
//         body: Center(
//             child: Container(
//                 constraints: const BoxConstraints(maxWidth: 1280),
//                 child: Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: <Widget>[
//                       RoundedInputField(
//                           hintText:
//                               "${AppLocalizations.of(context)!.findSomeoneByName} ${AppLocalizations.of(context)!.or} ${AppLocalizations.of(context)!.email}",
//                           onChanged: (value) {
//                             searchValue = value;
//                           }),
//                       ElevatedButton(
//                           child: Text(AppLocalizations.of(context)!.search),
//                           onPressed: () {
//                             // SearchChatterByEmailScreen.email = email;
//                             SearchChatterByEmailScreen.searchValue =
//                                 searchValue;
//                             Navigator.pushNamed(
//                                 context, "/searchChatter");
//                           }),
//                       const Divider(height: 100),
//                       Text(AppLocalizations.of(context)!
//                           .seeWhoIsAlreadyOnAnyChat),
//                       ElevatedButton(
//                           child: Text(AppLocalizations.of(context)!.contacts),
//                           onPressed: () {
//                             Navigator.pushNamed(context, "/contacts");
//                           }),
//                     ],
//                   ),
//                 ))));
//   }
// }
