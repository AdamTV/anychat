import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:settings_ui/settings_ui.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({Key? key}) : super(key: key);

  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  final List languages = Set.from(AnyChatLocale.isoMap.keys).toList();
  int languageIndex = 0;

  @override
  void initState() {
    super.initState();
    for (var value in AnyChatLocale.isoMap.values) {
      if (value == AnyChatAuth.currentUser!.language) {
        break;
      }
      languageIndex++;
    }
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
              title: Text(AppLocalizations.of(context)!.languages)),
          body: SettingsList(
            sections: [
              SettingsSection(tiles: getLanguageTiles()),
            ],
          ),
        ));
  }

  Widget trailingWidget(int index) {
    return (languageIndex == index)
        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
        : const Icon(null);
  }

  Future<void> changeLanguage(int index) async {
    setState(() {
      languageIndex = index;
    });
    await AnyChatUser.updateLanguage(AnyChatLocale.isoMap[languages[index]]);
  }

  List<SettingsTile> getLanguageTiles() {
    List<SettingsTile> tiles = [];
    for (var element in AnyChatLocale.isoMap.keys) {
      tiles.add(SettingsTile(
          title: Text(element),
          trailing: trailingWidget(languages.indexOf(element)),
          onPressed: (BuildContext context) {
            changeLanguage(languages.indexOf(element));
          }));
    }
    return tiles;
  }
}
