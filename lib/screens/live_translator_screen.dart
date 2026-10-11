import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/components/audio_transcriber.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/screens/welcome_screen.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:anychat/utilities/stateful_alert_dialog.dart';
import 'package:anychat/widgets/anychat_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../components/combined_locale_info.dart';

class LiveTranslatorScreen extends StatefulWidget {
  static String? isoCodeTranscribedWords = AnyChatAuth.currentUser.language;
  static String? isoCodeTranslatedWords = AnyChatAuth.currentUser.language;

  const LiveTranslatorScreen({super.key});

  @override
  State<LiveTranslatorScreen> createState() => _LiveTranslatorScreenState();
}

class _LiveTranslatorScreenState extends State<LiveTranslatorScreen> {
  bool recognizing = false;
  bool recognizeFinished = false;

  String? text;

  AudioTranscriber audioTranscriber = AudioTranscriber();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((d) async {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => _buildPopupDialog(context),
      );
      longRunningRecognize();
      showAudioRecordingToast();
    });
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
                SchedulerBinding.instance.addPostFrameCallback((d) async {
                  await showDialog<void>(
                    context: context,
                    builder: (BuildContext context) =>
                        _buildPopupDialog(context),
                  );
                  longRunningRecognize();
                  showAudioRecordingToast();
                });
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
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        text = "";
                      });
                    },
                    child: Text(localizationOf(context).clear),
                  ))),
        ),
        drawer: AnyChatDrawer(entries: [
          AnyChatDrawerEntry(
            title: localizationOf(context).backToConversations,
            onTap: () async {
              await stopRecording();
              NavigationService()
                  .popUntil((p0) => p0.settings.name == '/conversations');
              NavigationService().pop();
            },
          ),
          AnyChatDrawerEntry(
            title: localizationOf(context).logout,
            onTap: () async {
              await AnyChatAuth.signOut();

              await NavigationService().pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const WelcomeScreen()),
                  (p0) => p0.isFirst);
              await AnyChatAuth.signOut();
            },
          ),
        ]),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Text(text ?? "", style: const TextStyle(fontSize: 32)),
        ),
        floatingActionButton: ElevatedButton(
            onPressed: () async => {
                  recognizing
                      ? await stopRecording()
                      : await longRunningRecognize(),
                },
            child: recognizing
                ? Text(localizationOf(context).stopStreaming)
                : Text(localizationOf(context).startStreaming)));
  }

  Future<void> stopRecording() async {
    await audioTranscriber.stopRecording();
    setState(() {
      recognizing = false;
    });
    // showAudioRecordingToast();
  }

  Widget _buildPopupDialog(BuildContext context) {
    return const StatefulAlertDialog();
    // return AlertDialog(
    //   title: Text(localizationOf(context).selectLanguage),
    //   content: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: <Widget>[
    //       DropdownButton<String>(
    //         value: dropdownValueTranscribe,
    //         icon: const Icon(Icons.transcribe),
    //         iconSize: 24,
    //         elevation: 16,
    //         onChanged: (String? newValue) {
    //           setState(() {
    //             dropdownValueTranscribe = newValue;
    //             isoCodeTranscribedWords =
    //                 getLocaleCodeByEndonym(newValue ?? 'en');
    //           });
    //           // isoCode = endonymRetrievalMap.isoMap[newValue!];
    //           logger.d(isoCodeTranscribedWords);
    //           // NavigationService().pop();
    //         },
    //         items: getLanguageDropdownMenuItems(context),
    //
    //         // endonymRetrievalMap.values.
    //         //     .map<DropdownMenuItem<String>>((String value) {
    //         //   return DropdownMenuItem<String>(
    //         //     value: value,
    //         //     child: Text(value),
    //         //   );
    //       ),
    //       DropdownButton<String>(
    //         value: dropdownValueTranslate,
    //         icon: const Icon(Icons.translate),
    //         iconSize: 24,
    //         elevation: 16,
    //         onChanged: (String? newValue) {
    //           setState(() {
    //             dropdownValueTranslate = newValue;
    //             isoCodeTranscribedWords =
    //                 getLocaleCodeByEndonym(newValue ?? 'en');
    //           });
    //           // isoCode = endonymRetrievalMap.isoMap[newValue!];
    //           logger.d(isoCodeTranscribedWords);
    //           // NavigationService().pop();
    //         },
    //         items: getLanguageDropdownMenuItems(context),
    //
    //         // endonymRetrievalMap.values.
    //         //     .map<DropdownMenuItem<String>>((String value) {
    //         //   return DropdownMenuItem<String>(
    //         //     value: value,
    //         //     child: Text(value),
    //         //   );
    //       ),
    //       // ElevatedButton(
    //       //     child: Text(localizationOf(context).saveCaps),
    //       //     onPressed: () {
    //       //       NavigationService().pop();
    //       //     }),
    //     ],
    //   ),
    //   actions: <Widget>[
    //     TextButton(
    //       onPressed: () {
    //         NavigationService().pop();
    //       },
    //       child: Text(localizationOf(context).close),
    //     ),
    //   ],
    // );
  }

  Future<void> longRunningRecognize() async {
    String responseText = "";

    var responseStream = await audioTranscriber
        .getResponseStream(LiveTranslatorScreen.isoCodeTranscribedWords);

    // if (!recognizing) showAudioRecordingToast();

    setState(() {
      recognizeFinished = false;
      recognizing = true;
    });

    responseStream.listen((data) async {
      if (!recognizing) return;
      final currentText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');
      // ignore: sdk_version_since
      var newData = data.results.firstOrNull;
      var isData = newData != null;
      if (!isData) return;
      final newText = await Utilities().getGoogleTranslation(
          LiveTranslatorScreen.isoCodeTranslatedWords, currentText);
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
    }, onError: (Object e) async {
      logger.d(e);
      await audioTranscriber.stopRecording();
      if (mounted && recognizing) {
        await longRunningRecognize();
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
    Utilities().showToast('Speak into the microphone to translate your words.');
    // Utilities().showToast((recognizing
    //     ? localizationOf(context).listeningToMicrophoneLiveAudio
    //     : localizationOf(context).noLongerListeningToMicrophoneLiveAudio));
  }
}
