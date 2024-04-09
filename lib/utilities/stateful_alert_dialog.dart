import 'package:anychat/components/combined_locale_info.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/live_translator_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatefulAlertDialog extends StatefulWidget {
  const StatefulAlertDialog({super.key});
  @override
  State<StatefulWidget> createState() => _StatefulAlertDialogState();
}

class _StatefulAlertDialogState extends State<StatefulAlertDialog> {
  String? dropdownValueTranscribe = getEndonymByLocaleCode(
      LiveTranslatorScreen.isoCodeTranscribedWords ??
          AnyChatAuth.currentUser.language);
  String? dropdownValueTranslate = getEndonymByLocaleCode(
      LiveTranslatorScreen.isoCodeTranslatedWords ??
          AnyChatAuth.currentUser.language);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(localizationOf(context).selectLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButton<String>(
            value: dropdownValueTranscribe,
            icon: const Icon(Icons.transcribe),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) {
              setState(() {
                dropdownValueTranscribe = newValue;
                LiveTranslatorScreen.isoCodeTranscribedWords =
                    getLocaleCodeByEndonym(newValue ?? 'en');
              });
            },
            items: getLanguageDropdownMenuItems(context),
          ),
          DropdownButton<String>(
            value: dropdownValueTranslate,
            icon: const Icon(Icons.translate),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) {
              setState(() {
                dropdownValueTranslate = newValue;
                LiveTranslatorScreen.isoCodeTranslatedWords =
                    getLocaleCodeByEndonym(newValue ?? 'en');
              });
            },
            items: getLanguageDropdownMenuItems(context),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            NavigationService().goBack();
          },
          child: Text(localizationOf(context).close),
        ),
      ],
    );
  }
}
