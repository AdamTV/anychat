import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sound/flutter_sound.dart' as fs;
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as g_speech_gen;
import 'package:google_speech/endless_streaming_service.dart';
import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../main.dart';
import '../services/speech_credentials.dart';

const int kAudioSampleRate = 16000;
const int kAudioNumChannels = 1;

class AudioTranscriber {
  bool recognizing = false;
  bool recognizeFinished = false;
  StreamSubscription<List<int>>? _audioStreamSubscription;
  static BehaviorSubject<List<int>> _audioStream = BehaviorSubject<List<int>>();
  static String? isoCode;

  // The recorder is only initialized for non-web platforms
  final fs.FlutterSoundRecorder? _recorder =
      kIsWeb ? null : fs.FlutterSoundRecorder();

  StreamSubscription<fs.Food>? _mRecordingDataSubscription;
  late StreamController<fs.Food> recordingDataController;

  Future<Stream<g_speech_gen.StreamingRecognizeResponse>> getResponseStream(
      String? isoCode) async {
    final recorder = _recorder;
    if (recorder != null) {
      await recorder.openRecorder();
    }

    _audioStream = BehaviorSubject<List<int>>();
    recordingDataController = StreamController<fs.Food>();

    if (recorder != null) {
      _mRecordingDataSubscription =
          recordingDataController.stream.listen((buffer) {
        if (buffer is fs.FoodData) {
          final data = buffer.data;
          if (data != null) {
            _audioStream.add(data);
          }
        }
      }, onDone: () {
        recordingDataController.close();
      });

      await Permission.microphone.request();

      await recorder
          .startRecorder(
            toStream: recordingDataController.sink,
            codec: fs.Codec.pcm16,
            numChannels: kAudioNumChannels,
            sampleRate: kAudioSampleRate,
          )
          .onError((error, stackTrace) => logger.e(
              "Error Starting Recorder for Audio Transcriber",
              error: error,
              stackTrace: stackTrace));
    }

    AudioTranscriber.isoCode = isoCode;
    return startResponseStream(_audioStream, isoCode);
  }

  /// Starts the shared speech pipeline for native and web audio streams.
  static Stream<g_speech_gen.StreamingRecognizeResponse> startResponseStream(
      Stream<List<int>> audioStream, String? languageCode) {
    final speechToText = EndlessStreamingService.viaThirdPartyAuthenticator(
      ThirdPartyAuthenticator(
        obtainCredentialsFromThirdParty: fetchSpeechCredentials,
      ),
    );
    final config = RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.basic,
        enableAutomaticPunctuation: true,
        sampleRateHertz: kAudioSampleRate,
        languageCode: languageCode!);
    final responseStream = speechToText.endlessStream;
    speechToText.endlessStreamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        audioStream,
        restartTime: const Duration(seconds: 60),
        transitionBufferTime: const Duration(seconds: 2));

    return responseStream;
  }

  Future<void> stopRecording() async {
    final recorder = _recorder;
    if (recorder != null) {
      await recorder.stopRecorder();
      await _audioStreamSubscription?.cancel();
      await _audioStream.close();
      await recorder.stopRecorder();
      await _mRecordingDataSubscription?.cancel();
      recorder.closeRecorder();
    } else {
      await _audioStream.close();
    }
  }
}
