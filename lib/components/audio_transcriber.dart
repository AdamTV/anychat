import 'dart:async';

import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_locale.dart';
import 'package:anychat/components/utilities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_speech/config/recognition_config.dart';
import 'package:google_speech/config/recognition_config_v1.dart';
import 'package:google_speech/config/streaming_recognition_config.dart';
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart' as v1Speech;
import 'package:google_speech/speech_client_authenticator.dart';
import 'package:google_speech/speech_to_text.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sound_stream/sound_stream.dart';

class AudioTranscriber {
  static final RecorderStream _recorder = RecorderStream();
  static StreamSubscription<List<int>> _audioStreamSubscription;
  static BehaviorSubject<List<int>> _audioStream;
  static String isoCode;

  static Future<Stream<v1Speech.StreamingRecognizeResponse>> getResponseStream(String isoCode) async {
    AudioTranscriber.isoCode = isoCode;

    _recorder.initialize();

    _audioStream = BehaviorSubject<List<int>>();
    _audioStreamSubscription = _recorder.audioStream.listen((event) {
      _audioStream.add(event);
    });

    await _recorder.start();

    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/anychat-c414a-7669166c30f5.json'))}');
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();

     return speechToText.streamingRecognize(
// <<<<<<< Updated upstream
    StreamingRecognitionConfig(config: config, interimResults: false),
    _audioStream);
  }

  static RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: isoCode);

  // Future<Stream<List<int>>> _getAudioStream() async {
  //   const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
  //   final stream = await MicStream.microphone(
  //       audioSource: AudioSource.DEFAULT,
  //       sampleRate: 16000,
  //       channelConfig: ChannelConfig.CHANNEL_IN_MONO,
  //       audioFormat: AUDIO_FORMAT);
  //   return stream;
  // }

  static Future<void> stopRecording() async {
    await _recorder.stop();
    await _audioStreamSubscription?.cancel();
    await _audioStream?.close();
  }
}