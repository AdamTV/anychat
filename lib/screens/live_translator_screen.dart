import 'dart:async';

import 'package:anychat/Screens/welcome_screen.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/config/recognition_config.dart';
import 'package:google_speech/config/recognition_config_v1.dart';
import 'package:google_speech/config/streaming_recognition_config.dart';
import 'package:google_speech/speech_client_authenticator.dart';
import 'package:google_speech/speech_to_text.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../components/constants.dart';

class LiveTranslatorScreen extends StatefulWidget {
  @override
  _LiveTranslatorScreenState createState() => _LiveTranslatorScreenState();
}

class _LiveTranslatorScreenState extends State<LiveTranslatorScreen> {
  String isoCode = AnyChatAuth.currentUser.language;
  String dropdownValue = Utilities.getLanguageFromIsoCode(AnyChatAuth.currentUser.language);
  bool recognizing;
  SpeechToText speechToText;
  String text = "";

  @override
  Widget build(BuildContext context) {
    speechToText?.dispose();
    streamingRecognize();
    return Scaffold(
        appBar: AppBar(
          //leading: Icon(Icons.restaurant),
          title: Text(AppLocalizations.of(context).title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.language),
              tooltip: AppLocalizations.of(context).language,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => _buildPopupDialog(context),
                );
              },
            ),
            IconButton(
                icon: const Icon(Icons.delete),
                tooltip: AppLocalizations.of(context).delete,
                onPressed: () {
                  setState(() {
                    text = "";
                  });
                })
          ],
          // bottom: PreferredSize(
          //   preferredSize: Size(320, 48),
          //   child: Padding(
          //       padding: EdgeInsets.fromLTRB(6, 0, 6, 4),
          //       child: IconButton(
          //           icon: const Icon(Icons.clear),
          //           tooltip: 'Clear',
          //           onPressed: () {
          //             setState(() {
          //               text = "";
          //             });
          //           })),
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
                  title: Text(AppLocalizations.of(context).back),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text(AppLocalizations.of(context).logout),
                  onTap: () async {
                    await AnyChatAuth.signOut();
                    Navigator.pushNamed(
                        context, "/welcome");
                  }),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Text(text, style: TextStyle(fontSize: 32)),
        )
        // Expanded(
        //   flex: 1,
        //   child: SingleChildScrollView(
        //     scrollDirection: Axis.vertical,
        //     child:
        //     Padding(
        //       padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
        //       child: Wrap(
        //         children: <Widget>[
        //
        //           SingleChildScrollView(
        //             child: Text(text, style: TextStyle(fontSize: 32)),
        //           )
        //
        //         ],
        //       ),
        //     ),
        //   )
        // )
        );
  }

  Widget _buildPopupDialog(BuildContext context) {
    return new AlertDialog(
      title: Text(AppLocalizations.of(context).selectLanguage),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButton<String>(
            value: dropdownValue,
            icon: Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Theme.of(context).primaryColor),
            onChanged: (String newValue) {
              setState(() {
                dropdownValue = newValue;
              });
              isoCode = AnyChatLocale.isoMap[newValue];
              print(isoCode);
              Navigator.pop(context);
            },
            items: AnyChatLocale.isoMap.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          // RoundedInputField(icon: Icons.language,onChanged:(value) {language = value;}),
          // RoundedButton(
          //     text: "SAVE",
          //     press: () {
          //       Navigator.of(context).pop();
          //     }),
        ],
      ),
      // actions: <Widget>[
      //   new FlatButton(
      //     onPressed: () {
      //       Navigator.of(context).pop();
      //     },
      //     textColor: Theme.of(context).primaryColor,
      //     child: const Text('Close'),
      //   ),
      // ],
    );
  }

  void streamingRecognize() async {
    // setState(() {
    //   recognizing = true;
    // });
    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/anychat-c414a-7669166c30f5.json'))}');
    speechToText = SpeechToText.viaServiceAccount(serviceAccount);

    final config = _getConfig();

    final responseStream = speechToText.streamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        await _getAudioStream());
    String lastMessage = "";
    responseStream.listen((data) async {
      String transcribedText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');
      if (lastMessage.compareTo(transcribedText) != 0 &&
          transcribedText.isNotEmpty) {
        lastMessage = transcribedText;
        // AnyChatUser.addTranscribedMessage(lastMessage);
        var newText = await Utilities.getGoogleTranslation(
            AnyChatAuth.currentUser.language, lastMessage);
        setState(() {
          text += newText + " ";
        });
      }
    }, onDone: () {
      // setState(() {
      //   recognizing = false;
      // });
    });
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: isoCode);

  Future<Stream<List<int>>> _getAudioStream() async {
    const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    final stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 16000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AUDIO_FORMAT);
    return stream;
  }

  // @override
  // void initState() {
  // }

  @override
  void dispose() {
    speechToText.dispose();
    super.dispose();
  }
}
