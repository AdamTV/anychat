import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:anychat/config/app_config.dart';
import 'package:anychat/utils/platform_infos.dart';
import 'events/audio_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecordingDialog extends StatefulWidget {
  static const String recordingFileType = 'm4a';
  static const String transcriptionFileType = 'txt';

  const RecordingDialog({
    super.key,
  });

  @override
  RecordingDialogState createState() => RecordingDialogState();
}

class RecordingDialogState extends State<RecordingDialog> {
  Timer? _recorderSubscription;
  Duration _duration = Duration.zero;
  String _transcribedWords = '';

  bool error = false;
  String? _recordedPath;
  String? _transcribedPath;
  final _audioRecorder = Record();
  stt.SpeechToText speech = stt.SpeechToText();
  final List<double> amplitudeTimeline = [];

  static const int bitRate = 64000;
  static const int samplingRate = 22050;

  Future<void> startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _recordedPath =
          '${tempDir.path}/recording${DateTime.now().microsecondsSinceEpoch}.${RecordingDialog.recordingFileType}';
      _transcribedPath =
          '${tempDir.path}/recording${DateTime.now().microsecondsSinceEpoch}.${RecordingDialog.transcriptionFileType}';

      final result = await _audioRecorder.hasPermission();
      if (result != true) {
        setState(() => error = true);
        return;
      }
      final bool available = await speech.initialize(onError: _onSpeechError);
      await WakelockPlus.enable();
      if (available) {
        speech.listen(onResult: _onSpeechResult);
      } else {
        Logs().d("The user has denied the use of speech recognition.");
      }
      await _audioRecorder.start(
        path: _recordedPath,
        bitRate: bitRate,
        samplingRate: samplingRate,
      );
      setState(() => _duration = Duration.zero);
      _recorderSubscription?.cancel();
      _recorderSubscription =
          Timer.periodic(const Duration(milliseconds: 100), (_) async {
        final amplitude = await _audioRecorder.getAmplitude();
        var value = 100 + amplitude.current * 2;
        value = value < 1 ? 1 : value;
        amplitudeTimeline.add(value);
        setState(() {
          _duration += const Duration(milliseconds: 100);
        });
      });
    } catch (_) {
      setState(() => error = true);
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    startRecording();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _recorderSubscription?.cancel();
    _audioRecorder.stop();
    super.dispose();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _transcribedWords += result.recognizedWords;
    });
  }

  void _onSpeechError(SpeechRecognitionError errorNotification) {
    Logs().e("Speech Error: $errorNotification");
  }

  void _stopAndSend() async {
    _recorderSubscription?.cancel();
    final File transcriptionFile = File(_transcribedPath!);
    transcriptionFile.writeAsString(_transcribedWords);
    Logs().d(_transcribedWords);
    await speech.stop();
    await _audioRecorder.stop();
    final path = _recordedPath;
    if (path == null) throw ('Recording failed!');
    const waveCount = AudioPlayerWidget.wavesCount;
    final step = amplitudeTimeline.length < waveCount
        ? 1
        : (amplitudeTimeline.length / waveCount).round();
    final waveform = <int>[];
    for (var i = 0; i < amplitudeTimeline.length; i += step) {
      waveform.add((amplitudeTimeline[i] / 100 * 1024).round());
    }
    Logs().d("Transctiption: $_transcribedWords");
    Navigator.of(context, rootNavigator: false).pop<RecordingResult>(
      RecordingResult(
        path: path,
        duration: _duration.inMilliseconds,
        waveform: waveform,
        transctiption: _transcribedWords,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxDecibalWidth = 64.0;
    final time =
        '${_duration.inMinutes.toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final content = error
        ? Text(L10n.of(context)!.oopsSomethingWentWrong)
        : Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.red,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: amplitudeTimeline.reversed
                      .take(26)
                      .toList()
                      .reversed
                      .map(
                        (amplitude) => Container(
                          margin: const EdgeInsets.only(left: 2),
                          width: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius:
                                BorderRadius.circular(AppConfig.borderRadius),
                          ),
                          height: maxDecibalWidth * (amplitude / 100),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(time),
              ),
            ],
          );
    if (PlatformInfos.isCupertinoStyle) {
      return CupertinoAlertDialog(
        content: content,
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
            child: Text(
              L10n.of(context)!.cancel.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(150),
              ),
            ),
          ),
          if (error != true)
            CupertinoDialogAction(
              onPressed: _stopAndSend,
              child: Text(L10n.of(context)!.send.toUpperCase()),
            ),
        ],
      );
    }
    return AlertDialog(
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
          child: Text(
            L10n.of(context)!.cancel.toUpperCase(),
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
            ),
          ),
        ),
        if (error != true)
          TextButton(
            onPressed: _stopAndSend,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(L10n.of(context)!.send.toUpperCase()),
                const SizedBox(width: 4),
                const Icon(Icons.send_outlined, size: 15),
              ],
            ),
          ),
      ],
    );
  }
}

class RecordingResult {
  final String path;
  final int duration;
  final List<int> waveform;
  final String transctiption;

  const RecordingResult({
    required this.path,
    required this.duration,
    required this.waveform,
    required this.transctiption,
  });

  factory RecordingResult.fromJson(Map<String, dynamic> json) =>
      RecordingResult(
        path: json['path'],
        duration: json['duration'],
        waveform: List<int>.from(json['waveform']),
        transctiption: json['transcription'],
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'duration': duration,
        'waveform': waveform,
        'transcription': transctiption,
      };
}
