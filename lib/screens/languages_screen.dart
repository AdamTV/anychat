import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/services/cache_manager.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../components/combined_locale_info.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  int languageIndex = 0;
  String userLanguage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getUserLanguage();
    languageIndex = 0;
    for (var value in endonymRetrievalMap.keys) {
      if (value == userLanguage) {
        break;
      }
      languageIndex++;
    }
    return Scaffold(
      appBar: AppBar(
          leading: Builder(builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                NavigationService().pushNamedAndRemoveUntil('/settings',
                    predicate: (Route<dynamic> route) =>
                        route.settings.name == '/conversations');
              },
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            );
          }),
          title: Text(localizationOf(context).languages)),
      body: SettingsList(
        sections: [
          SettingsSection(tiles: getLanguageTiles()),
        ],
      ),
    );
  }

  Widget trailingWidget(int index) {
    return (languageIndex == index)
        ? const Icon(Icons.check)
        : const Icon(null);
  }

  Future<void> changeLanguage(int index) async {
    await AnyChatUser.updateLanguage(endonymRetrievalMap.keys.elementAt(index));
    setState(() {
      languageIndex = index;
      NavigationService().pushNamedAndRemoveUntil('/settings',
          predicate: (Route<dynamic> route) =>
              route.settings.name == '/conversations');
    });
  }

  List<SettingsTile> getLanguageTiles() {
    List<SettingsTile> tiles = [];
    for (var element in endonymRetrievalMap.values) {
      List<String> localizedLanguages = [];
      for (var element in endonymRetrievalMap.values) {
        localizedLanguages.add(element(localizationOf(context)));
      }
      tiles.add(SettingsTile(
          title: Text(element(localizationOf(context))),
          trailing: trailingWidget(
              localizedLanguages.indexOf(element(localizationOf(context)))),
          onPressed: (BuildContext context) async {
            await changeLanguage(
                localizedLanguages.indexOf(element(localizationOf(context))));
          }));
    }
    return tiles;
  }

  Future<void> getUserLanguage() async {
    var user =
        await CacheManager().getUserDataWithCache(AnyChatAuth.currentUser.id);
    setState(() {
      userLanguage = user.locale.languageCode;
    });
  }
}
