import 'dart:async';
import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pb.dart'
    as g_speech_gen;
import 'package:rxdart/rxdart.dart';

import 'audio_transcriber.dart';

class WebAudioTranscriber {
  bool recognizing = false;
  bool recognizeFinished = false;
  static BehaviorSubject<List<int>> _audioStream = BehaviorSubject<List<int>>();
  static String? isoCode;

  Future<Stream<g_speech_gen.StreamingRecognizeResponse>> getResponseStream(
      String? isoCode) async {
    recognizing = true;
    AudioTranscriber.isoCode = isoCode;

    // Web implementation of audio recording is currently disabled to resolve
    // flutter_sound_web compilation errors.
    _audioStream = BehaviorSubject<List<int>>();

    return AudioTranscriber.startResponseStream(_audioStream, isoCode);
  }

  Future<void> stopRecording() async {
    await _audioStream.close();
  }
}
