import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/rounded_button.dart';
import 'package:anychat/components/rounded_input_field.dart';
import 'package:anychat/screens/search_chatter_by_email_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddChatterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String email;
    return Scaffold(
        appBar: AppBar(
          //leading: Icon(Icons.restaurant),
          title: Text(
            AppLocalizations.of(context).title,
          ),
          // bottom: PreferredSize(
          //   preferredSize: Size(320, 48),
          //   child: Padding(
          //     padding: EdgeInsets.fromLTRB(6, 0, 6, 4),
          //     child: FilterBar(
          //       filter: _filter,
          //       onPressed: _onFilterBarPressed,
          //     ),
          //   ),
          // ),
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
                child: Text(
                  AppLocalizations.of(context).title,
                  style: TextStyle(color: Theme.of(context).primaryColorLight),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                  title: Text(AppLocalizations.of(context).conversations),
                  onTap: () {
                    Navigator.pushNamed(context, "/conversations");
                    //_handleSignOut();
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context).logout),
                  onTap: () async {
                    await AnyChatAuth.signOut();
                    Navigator.pushNamed(context, "/welcome");
                    //_handleSignOut();
                  }),
            ],
          ),
        ),
        body: Center(
            child: Container(
                constraints: BoxConstraints(maxWidth: 1280),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      RoundedInputField(
                          hintText:
                              AppLocalizations.of(context).findSomeoneByEmail,
                          onChanged: (value) {
                            email = value;
                          }),
                      RoundedButton(
                          text: AppLocalizations.of(context).search,
                          press: () {
                            SearchChatterByEmailScreen.email = email;
                            Navigator.pushNamed(
                                context, "/searchChatterByEmail");
                          }),
                      Divider(height: 100),
                      Text(AppLocalizations.of(context)
                          .seeWhoIsAlreadyOnAnyChat),
                      RoundedButton(
                          text: AppLocalizations.of(context).contacts,
                          press: () {
                            Navigator.pushNamed(context, "/contacts");
                          }),
                    ],
                  ),
                ))));
  }
}
