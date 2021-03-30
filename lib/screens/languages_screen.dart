import 'package:anychat/Screens/settings_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../components/constants.dart';

class LanguagesScreen extends StatefulWidget {
  @override
  _LanguagesScreenState createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  final List languages = Set.from(isoMap.keys).toList();
  int languageIndex = 0;

  @override
  void initState() {
    super.initState();
    for (var value in isoMap.values) {
      if (value == AnyChatAuth.currentUser.language) {
        break;
      }
      languageIndex++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
              leading: Builder(builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return SettingsScreen();
                    }));
                  },
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                );
              }),
              title: Text('Languages')),
          body: SettingsList(
            sections: [
              SettingsSection(tiles: getLanguageTiles()),
            ],
          ),
        ),
        onWillPop: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
              return SettingsScreen();
            }))
    );
  }

  Widget trailingWidget(int index) {
    return (languageIndex == index)
        ? Icon(Icons.check, color: Theme.of(context).primaryColor)
        : Icon(null);
  }

  Future<void> changeLanguage(int index) async {
    setState(() {
      languageIndex = index;
    });
    await AnyChatUser.updateLanguage(isoMap[languages[index]]);
  }

  List<SettingsTile> getLanguageTiles() {
    List<SettingsTile> tiles = [];
    isoMap.keys.forEach((element) {
      tiles.add(SettingsTile(
          title: element,
          trailing: trailingWidget(languages.indexOf(element)),
          onPressed: (BuildContext context) {
            changeLanguage(languages.indexOf(element));
          }));
    });
    return tiles;
  }
}
