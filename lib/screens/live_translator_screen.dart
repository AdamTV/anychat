import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/audio_transcriber.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../components/combined_locale_info.dart';

class LiveTranslatorScreen extends StatefulWidget {
  const LiveTranslatorScreen({super.key});

  @override
  State<LiveTranslatorScreen> createState() => _LiveTranslatorScreenState();
}

class _LiveTranslatorScreenState extends State<LiveTranslatorScreen> {
  String? isoCode = AnyChatAuth.currentUser.language;
  String? dropdownValue =
  getEndonymByLocaleCode(AnyChatAuth.currentUser.language);
  bool recognizing = false;
  bool recognizeFinished = false;

  String? text;

  AudioTranscriber audioTranscriber = AudioTranscriber();

  @override
  void initState() {
    super.initState();
    longRunningRecognize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          //leading: Icon(Icons.restaurant),
          title: Text(localizationOf(context).title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: localizationOf(context).language,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => _buildPopupDialog(context),
                );
              },
            ),
            // IconButton(
            //     icon: const Icon(Icons.delete),
            //     tooltip: localizationOf(context).delete,
            //     onPressed: () {
            //       setState(() {
            //         text = "";
            //       });
            //     })
          ],
          bottom: PreferredSize(
            preferredSize: const Size(320, 48),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                child: IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: localizationOf(context).clear,
                    onPressed: () {
                      setState(() {
                        text = "";
                      });
                    })),
          ),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Text(
                  localizationOf(context).title,
                  style: TextStyle(color: Theme.of(context).primaryColorLight),
                ),
              ),
              ListTile(
                  title: Text(localizationOf(context).back),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text(localizationOf(context).logout),
                  onTap: () async {
                    await AnyChatAuth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamed(context, "/welcome");
                    }
                  }),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Text(text ?? "", style: const TextStyle(fontSize: 32)),
        ),
        floatingActionButton: ElevatedButton(
            onPressed: recognizing ? stopRecording : longRunningRecognize,
            child: recognizing
                ? Text(localizationOf(context).stopStreaming)
                : Text(localizationOf(context).startStreaming)));
  }

  void stopRecording() async {
    await audioTranscriber.stopRecording();
    setState(() {
      recognizing = false;
    });
    showAudioRecordingToast();
  }

  Widget _buildPopupDialog(BuildContext context) {
    return AlertDialog(
      title: Text(localizationOf(context).selectLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButton<String>(
            value: dropdownValue,
            icon: const Icon(Icons.language),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) {
              setState(() {
                dropdownValue = newValue;
              });
              // isoCode = endonymRetrievalMap.isoMap[newValue!];
              logger.d(isoCode);
              longRunningRecognize();
              Navigator.pop(context);
            },
            items: getLanguageDropdownMenuItems(context),



            // endonymRetrievalMap.values.
            //     .map<DropdownMenuItem<String>>((String value) {
            //   return DropdownMenuItem<String>(
            //     value: value,
            //     child: Text(value),
            //   );
          ),
          // ElevatedButton(
          //     child: Text(localizationOf(context).saveCaps),
          //     onPressed: () {
          //       NavigationService().goBack();
          //     }),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            NavigationService().goBack();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
          ),
          child: Text(localizationOf(context).close),
        ),
      ],
    );
  }

  void longRunningRecognize() async {
    String responseText = "";

    var responseStream = await audioTranscriber.getResponseStream(isoCode);

    if (!recognizing) showAudioRecordingToast();

    setState(() {
      recognizeFinished = false;
      recognizing = true;
    });

    responseStream.listen((data) async {
      final currentText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');
      // ignore: sdk_version_since
      var newData = data.results.firstOrNull;
      var isData = newData != null;
      final newText = await Utilities()
          .getGoogleTranslation(AnyChatAuth.currentUser.language, currentText);
      if (mounted) {
        if (isData && newData.isFinal) {
          responseText += '\n$newText';
          setState(() {
            text = responseText;
            recognizeFinished = true;
          });
        } else {
          setState(() {
            text = '$responseText\n$newText';
            recognizeFinished = true;
          });
        }
      }
    }, onError: (e) async {
      logger.d(e);
      await audioTranscriber.stopRecording();
      if (mounted && recognizing) {
        longRunningRecognize();
      }
    }, onDone: () {
      if (mounted) {
        setState(() {
          recognizing = false;
        });
      }
    });
    // var responseStream = await audioTranscriber.getResponseStream(isoCode);

    // responseStream.listen((data) async {
    //   if (data.results.isEmpty) return;
    //   String transcribedText =
    //       data.results.map((e) => e.alternatives.first.transcript).last;
    //   if (lastMessage.compareTo(transcribedText) != 0 &&
    //       transcribedText.isNotEmpty) {
    //     lastMessage = transcribedText;
    //     var newText = await Utilities().getGoogleTranslation(
    //         AnyChatAuth.currentUser!.language, lastMessage);
    //     setState(() {
    //       text += "$newText ";
    //     });
    //   }
    // }, onError: (e) async {
    //   logger.d(e);
    //   await audioTranscriber.stopRecording();
    //   if (mounted) {
    //     streamingRecognize();
    //   }
    // });
    // }
  }

  void showAudioRecordingToast() {
    Utilities().showToast((recognizing
        ? localizationOf(context).listeningToMicrophoneLiveAudio
        : localizationOf(context)
            .noLongerListeningToMicrophoneLiveAudio));
  }


}
