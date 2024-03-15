import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/screens/block_chatter_search_screen.dart';
import 'package:anychat/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:settings_ui/settings_ui.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    getBlockedAccountNames();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvoked: ((didPop) => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
              return const SettingsScreen();
            })) as Future<bool>),
        child: Scaffold(
          appBar: AppBar(
              leading: Builder(builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return const SettingsScreen();
                    }));
                  },
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                );
              }),
              title: Text(AppLocalizations.of(context)!.blockAccount)),
          body: SettingsList(
            sections: [
              SettingsSection(tiles: tiles),
            ],
          ),
        ));
  }
  List<SettingsTile> tiles = [];
  Future<void> getBlockedAccountNames() async {
    tiles.clear();
    tiles.add(SettingsTile(
        title: Text(AppLocalizations.of(Utilities.globalKey.currentContext!)!.blockAccount),
        leading: const Icon(Icons.add),
        onPressed: (ctx) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (BuildContext context) {
                return const BlockChatterSearchScreen();
              }));
        }));

    for (int i = 0; i < AnyChatAuth.currentUser!.blockedAccounts.length; i++){
      var user = await AnyChatUser.getUserById(AnyChatAuth.currentUser!.blockedAccounts[i]);
      setState(() {
        tiles.add(SettingsTile(
            title: Text(user.displayName),
            onPressed: (BuildContext context) async {
              await AnyChatAuth.currentUser!.unblockAccount(user.id);
              getBlockedAccountNames();
            }));
      });
    }
  }
}
