import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/utilities.dart';
import 'file:///C:/Users/adams/source/repos/flutter/anychat/lib/Components/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/config/recognition_config.dart';
import 'package:google_speech/config/recognition_config_v1.dart';
import 'package:google_speech/config/streaming_recognition_config.dart';
import 'package:google_speech/speech_client_authenticator.dart';
import 'package:google_speech/speech_to_text.dart';
import 'package:mic_stream/mic_stream.dart';

import 'chat_screen.dart';

class CallScreen extends StatefulWidget {
  final String channelName;

  const CallScreen({Key key, this.channelName}) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine _engine;
  String text = "";
  StreamSubscription<QuerySnapshot> _transcribedChatMessageSubscription;

  get defaultTargetPlatform => null;

  _CallScreenState() {
    _transcribedChatMessageSubscription =
        loadAllTranscribedMessages().listen(_updateCallScreen);
  }

  @override
  void dispose() {
    _transcribedChatMessageSubscription?.cancel();
    speechToText.dispose();
    // clear transcribedMessages
    AnyChatUser.clearTranscribedMessages();
    // print(_infoStrings);
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
  }

  Future<void> initialize() async {
    if (agoraAppId.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    // await _engine.enableWebSdkInteroperability(true);
    streamingRecognize();
    await _engine.joinChannel(null, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(agoraAppId);
    await _engine.enableVideo();
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'onError: $code';
          _infoStrings.add(info);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'onJoinChannel: $channel, uid: $uid';
          _infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          _infoStrings.add(info);
          _users.add(uid);
        });
      },
      userOffline: (uid, reason) {
        setState(() {
          final info = 'userOffline: $uid , reason: $reason';
          _infoStrings.add(info);
          _users.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideoFrame: $uid';
          _infoStrings.add(info);
        });
      },
    ));
  }

  Widget _translatedText() {
    return Wrap(
      children: <Widget>[
        Text(text,
            style: TextStyle(
                backgroundColor: Theme.of(context).primaryColorLight,
                fontSize: 32))
      ],
    );
  }

  SpeechToText speechToText;
  bool recognizing, recognizeFinished;

  void streamingRecognize() async {
    setState(() {
      recognizing = true;
    });
    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/anychat-c414a-7669166c30f5.json'))}');
    speechToText = SpeechToText.viaServiceAccount(serviceAccount);

    final config = _getConfig();

    final responseStream = speechToText.streamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        await _getAudioStream());
    String lastMessage = "";
    responseStream.listen((data) {
      String transcribedText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');
      if (lastMessage.compareTo(transcribedText) != 0 &&
          transcribedText.isNotEmpty) {
        lastMessage = transcribedText;
        AnyChatUser.addTranscribedMessage(lastMessage);
      }
      // setState(() {
      //   text =
      //       data.results.map((e) => e.alternatives.first.transcript).join('\n');
      //   recognizeFinished = true;
      // });
    }, onDone: () {
      setState(() {
        recognizing = false;
      });
    });
  }

  Future<Stream<List<int>>> _getAudioStream() async {
    const AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    final stream = await MicStream.microphone(
        audioSource: AudioSource.DEFAULT,
        sampleRate: 16000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AUDIO_FORMAT);
    return stream;
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: AnyChatAuth.currentUser.language);

  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted
                  ? Theme.of(context).primaryColorLight
                  : Theme.of(context).accentColor,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted
                ? Theme.of(context).accentColor
                : Theme.of(context).primaryColorLight,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () async => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Theme.of(context).primaryColorLight,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Theme.of(context).accentColor,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Theme.of(context).primaryColorLight,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AnyChat'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _viewRows(),
            _translatedText(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<Widget> list = [];
    // if (defaultTargetPlatform == TargetPlatform.iOS) {
    //   list.add(RtcLocalView.SurfaceView());
    //   _users.forEach(
    //       (int uid) => {list.add(RtcRemoteView.SurfaceView(uid: uid))});
    // }
    // if(defaultTargetPlatform == TargetPlatform.android){
    // list.add(TextField());
    list.add(RtcLocalView.SurfaceView());
    _users.forEach((int uid) =>
        // {list.add(_translatedText()), list.add(RtcRemoteView.SurfaceView(uid: uid))});
        {list.add(RtcRemoteView.SurfaceView(uid: uid))});
    // }
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    var getRenderViews = _getRenderViews();
    final views = getRenderViews;
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  Future<void> _onCallEnd(BuildContext context) async {
    if (await Ads.interstitial.isLoaded){
      Ads.interstitial.show();
    }else{
      print('Interstitial ad is still laoding...');
    }
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  Stream<QuerySnapshot> loadAllTranscribedMessages() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(ChatWindow.currentConversation.id)
        .collection('transcribedMessages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> _updateCallScreen(QuerySnapshot snapshot) async {
    final message = getMessageFromQuery(snapshot);
    final sender = AnyChatUser.fromSnapshot(await FirebaseFirestore.instance.collection("users").doc(message.senderId).get());

    final language = AnyChatAuth.currentUser.language;
    if (message.senderId != AnyChatAuth.currentUser.id) {
      final translatedText =
          await Utilities.getGoogleTranslation(language, message.text);
      setState(() {
        text = translatedText;
      });
    }
  }

  AnyChatMessage getMessageFromQuery(QuerySnapshot snapshot) {
    return snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).last;
  }
}
