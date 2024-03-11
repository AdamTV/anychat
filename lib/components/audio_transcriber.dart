import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as g_speech_gen;
import 'package:google_speech/endless_streaming_service.dart';
import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../main.dart';

const int kAudioSampleRate = 16000;
const int kAudioNumChannels = 1;

// const int tSampleRate = 44000;

class AudioTranscriber {
  bool recognizing = false;
  bool recognizeFinished = false;
  StreamSubscription<List<int>>? _audioStreamSubscription;
  static BehaviorSubject<List<int>> _audioStream = BehaviorSubject<List<int>>();
  static String? isoCode;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _mRecordingDataSubscription;
  late StreamController<Food> recordingDataController;

  Future<Stream<g_speech_gen.StreamingRecognizeResponse>> getResponseStream(
      String? isoCode) async {
    // stopRecording();
    await _recorder.openRecorder();
    // Stream to be consumed by speech recognizer
    _audioStream = BehaviorSubject<List<int>>();

    // Create recording stream
    recordingDataController = StreamController<Food>();
    _mRecordingDataSubscription =
        recordingDataController.stream.listen((buffer) {
      if (buffer is FoodData) {
        _audioStream.add(buffer.data!);
      }
    }, onDone: () {
      recordingDataController.close();
    });

    // should set state of caller context?
    recognizing = true;

    AudioTranscriber.isoCode = isoCode;
    await Permission.microphone.request();

    await _recorder
        .startRecorder(
          toStream: recordingDataController.sink,
          codec: Codec.pcm16,
          numChannels: kAudioNumChannels,
          // sampleRate: tSampleRate,
          sampleRate: kAudioSampleRate,
        )
        .onError((error, stackTrace) => logger.e(
            "Error Starting Recorder for Audio Transcriber",
            error,
            stackTrace));

    final serviceAccount = ServiceAccount.fromString((await rootBundle
        .loadString('assets/anychat-c414a-c304e57544ef.json')));
    final speechToText = EndlessStreamingService.viaServiceAccount(
      serviceAccount,
    );
    final config = _getConfig();
    final responseStream = speechToText.endlessStream;
    speechToText.endlessStreamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        _audioStream,
        restartTime: const Duration(seconds: 60),
        transitionBufferTime: const Duration(seconds: 2));
    //
    // _mRecordingDataSubscription =
    //     recordingDataController.stream.listen((buffer) {
    //   if (buffer is FoodData) {
    //     _audioStream.add(buffer.data as List<int>);
    //   }
    // });
    //
    // _recorder.audioStream.listen((event) {
    //   _audioStream.add(event);
    // });
    //
    // await _recorder.openAudioSession();

    return responseStream;
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: isoCode!);

  // Future<Stream<List<int>>> _getAudioStream() async {
  //   const AUDIO_FORMAT = google_speech..ENCODING_PCM_16BIT;
  //   final stream = await MicStream.microphone(
  //       audioSource: AudioSource.DEFAULT,
  //       sampleRate: 16000,
  //       channelConfig: ChannelConfig.CHANNEL_IN_MONO,
  //       audioFormat: AUDIO_FORMAT);
  //   return stream;
  // }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    await _audioStreamSubscription?.cancel();
    await _audioStream.close();
    await _recorder.stopRecorder();
    await _mRecordingDataSubscription?.cancel();
    _recorder.closeRecorder();
  }
}
