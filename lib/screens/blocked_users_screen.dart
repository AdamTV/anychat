import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/components/combined_locale_info.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/screens/search_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
          leading: Builder(builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                NavigationService().pop();
              },
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            );
          }),
          title: Text(localizationOf(context).blockAccount)),
      body: SettingsList(
        sections: [
          SettingsSection(tiles: tiles),
        ],
      ),
    );
  }

  List<SettingsTile> tiles = [];
  Future<void> getBlockedAccountNames() async {
    final blockedIds = AnyChatAuth.currentUser.blockedAccounts;
    final blockedUsers = await AnyChatUser.getUsersByIds(blockedIds);
    final usersById = {for (final user in blockedUsers) user.id: user};
    for (final id in blockedIds) {
      usersById.putIfAbsent(id, () => AnyChatUser.deletedUser(id));
    }
    if (!mounted) {
      return;
    }

    setState(() {
      tiles
        ..clear()
        ..add(SettingsTile(
          title: Text(localizationOf(Utilities().globalKey.currentContext!)
              .blockAccount),
          leading: const Icon(Icons.add),
          onPressed: (ctx) {
            NavigationService().pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
              return const SearchChatterScreen(false, true);
            }));
          },
        ));
      for (final id in blockedIds) {
        final user = usersById[id]!;
        tiles.add(SettingsTile(
            title: Text(user.displayName),
            onPressed: (BuildContext context) async {
              await AnyChatAuth.currentUser.unblockAccount(user.id);
              await getBlockedAccountNames();
            }));
      }
    });
  }
}
