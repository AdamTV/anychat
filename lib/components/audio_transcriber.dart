import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_speech/config/recognition_config.dart';
import 'package:google_speech/config/recognition_config_v1.dart';
import 'package:google_speech/config/streaming_recognition_config.dart';
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as v1Speech;
import 'package:google_speech/speech_client_authenticator.dart';
import 'package:google_speech/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

const int tSampleRate = 44000;

class AudioTranscriber {
  // static StreamSubscription<List<int>> _audioStreamSubscription;
  static BehaviorSubject<List<int>> _audioStream;
  static String isoCode;
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _mRecorderIsInited = false;
  StreamSubscription _mRecordingDataSubscription;


  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder.openAudioSession();
    // setState(() {
    _mRecorderIsInited = true;
    // });
  }

  Future<Stream<v1Speech.StreamingRecognizeResponse>> getResponseStream(
      String isoCode) async {
    stopRecording();

    await _openRecorder();

    _audioStream = BehaviorSubject<List<int>>();

    AudioTranscriber.isoCode = isoCode;

    // _recorder.initialize();

    _audioStream = BehaviorSubject<List<int>>();
    // _audioStreamSubscription = _recorder.audioStream.listen((event) {
    //   _audioStream.add(event);
    // });

    // await _recorder.start();

    assert(_mRecorderIsInited);
    // var sink = await createFile();
    var recordingDataController = StreamController<Food>();
    _mRecordingDataSubscription =
        recordingDataController.stream.listen((buffer) {
      if (buffer is FoodData) {
        // sink.add(buffer.data!);
        _audioStream.add(buffer.data);
      }
    }, onDone: () {
      recordingDataController.close();
    });
    await _mRecorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: tSampleRate,
    );

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
      sampleRateHertz: tSampleRate,
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

  Future<void> stopRecording() async {
    // await _recorder.stop();
    // await _audioStreamSubscription?.cancel();
    // await _audioStream?.close();
    await _mRecorder.stopRecorder();
    await _mRecordingDataSubscription?.cancel();
  }
}
