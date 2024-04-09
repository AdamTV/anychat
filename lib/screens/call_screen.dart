import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:anychat/database/anychat_auth.dart';
import 'package:anychat/database/anychat_message.dart';
import 'package:anychat/database/anychat_user.dart';
import 'package:anychat/components/audio_transcriber.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:anychat/services/http_service.dart';
import 'package:anychat/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

String? appId = '72559be0b8944a8fb70a772d196078ce';
String channelId = AnyChatAuth.currentConversation!.id;
final uid = AnyChatAuth.currentUser.id.hashCode;
String token = '';

class CallScreen extends StatefulWidget {
  /// Construct the [CallScreen]
  const CallScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final RtcEngine _engine;

  bool isJoined = false, switchCamera = true, muted = false;

  Set<int> remoteUid = {};
  final ChannelProfileType _channelProfileType =
      ChannelProfileType.channelProfileLiveBroadcasting;
  late final RtcEngineEventHandler _rtcEngineEventHandler;
  StreamSubscription<QuerySnapshot>? _transcribedChatMessageSubscription;

  _CallScreenState();

  String text = "";

  get shape => null;

  @override
  void initState() {
    super.initState();
    _requestPermissionIfNeed();
    _initEngine();
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _transcribedChatMessageSubscription =
        loadAllTranscribedMessages().listen(_updateCallScreen);
    }

  @override
  void dispose() {
    _transcribedChatMessageSubscription?.cancel();
    AnyChatUser.clearTranscribedMessages();
    _dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  Future<void> _dispose() async {
    _engine.unregisterEventHandler(_rtcEngineEventHandler);
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> _initEngine() async {
    logger.d('Entering method: _initEngine())');
    _engine = createAgoraRtcEngine();
    token = await agoraAuth();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
    ));

    _rtcEngineEventHandler = RtcEngineEventHandler(
      onError: (ErrorCodeType err, String msg) {
        logger.e('[onError] err: $err, msg: $msg');
      },
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        logger.d(
            '[onJoinChannelSuccess] connection: ${connection.toJson()} elapsed: $elapsed');
        setState(() {
          isJoined = true;
        });
      },
      onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
        logger.d(
            '[onUserJoined] connection: ${connection.toJson()} remoteUid: $rUid elapsed: $elapsed');
        setState(() {
          remoteUid.add(rUid);
        });
      },
      onUserOffline:
          (RtcConnection connection, int rUid, UserOfflineReasonType reason) {
        logger.d(
            '[onUserOffline] connection: ${connection.toJson()}  rUid: $rUid reason: $reason');
        setState(() {
          remoteUid.removeWhere((element) => element == rUid);
        });
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        logger.d(
            '[onLeaveChannel] connection: ${connection.toJson()} stats: ${stats.toJson()}');
        setState(() {
          isJoined = false;

          remoteUid.clear();
        });
      },
      onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid,
          RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
        logger.d(
            '[onRemoteVideoStateChanged] connection: ${connection.toJson()} remoteUid: $remoteUid state: $state reason: $reason elapsed: $elapsed');
      },
    );

    _engine.registerEventHandler(_rtcEngineEventHandler);

    await _engine.enableVideo();
    await _engine.startPreview();
    logger.d('trying to join Channel');
    _joinChannel();
    streamingRecognize();
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: _channelProfileType,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _requestPermissionIfNeed() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
  }

  Future<void> _leaveChannel() async {
    await audioTranscriber.stopRecording();
    AnyChatUser.clearTranscribedMessages();

    await _engine.leaveChannel();
    setState(() {
      muted = false;
    });
    NavigationService().goBack();
  }

  Future<void> _switchCamera() async {
    await _engine.switchCamera();
    setState(() {
      switchCamera = !switchCamera;
    });
  }

  // _openCamera() async {
  //   await _engine.enableLocalVideo(!openCamera);
  //   setState(() {
  //     openCamera = !openCamera;
  //   });
  // }

  _muteLocalAudioStream() async {
    await _engine.muteLocalAudioStream(!muted);
    setState(() {
      muted = !muted;
    });
  }

  // _muteAllRemoteVideoStreams() async {
  //   await _engine.muteAllRemoteVideoStreams(!muteAllRemoteVideo);
  //   setState(() {
  //     muteAllRemoteVideo = !muteAllRemoteVideo;
  //   });
  // }

  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(
            onPressed: _muteLocalAudioStream,
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (muted) {
                    return Theme.of(context).colorScheme.secondary;
                  } else {
                    return Theme.of(context).primaryColorLight;
                  }
                }),
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (muted) {
                    return Theme.of(context).primaryColorLight;
                  } else {
                    return Theme.of(context).colorScheme.secondary;
                  }
                }),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                    const CircleBorder())),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted
                  ? Theme.of(context).primaryColorLight
                  : Theme.of(context).colorScheme.secondary,
              size: 20.0,
            ),
          ),
          TextButton(
            onPressed: () async => _leaveChannel(),
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.redAccent),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                    const CircleBorder())),
            child: Icon(Icons.call_end,
                color: Theme.of(context).primaryColorLight, size: 40),
          ),
          TextButton(
            onPressed: _switchCamera,
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                    const CircleBorder())),
            child: Icon(Icons.sync,
                color: Theme.of(context).colorScheme.secondary, size: 20),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
            useFlutterTexture: true,
          ),
          onAgoraVideoViewCreated: (viewId) {
            _engine.startPreview();
          },
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.of(remoteUid.map(
                (e) => SizedBox(
                  width: 120,
                  height: 120,
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: e),
                      connection: RtcConnection(channelId: channelId),
                      useFlutterTexture: true,
                    ),
                  ),
                ),
              )),
            ),
          ),
        ),
        _translatedText(),
        _toolbar(),
      ],
    );
  }

  // List<Widget> _remoteVideo() {
  //   if (remoteUid.isNotEmpty) {
  //     return List.of(remoteUid.map(
  //       (e) => SizedBox(
  //         width: 120,
  //         height: 120,
  //         child: AgoraVideoView(
  //           controller: VideoViewController.remote(
  //             rtcEngine: _engine,
  //             canvas: VideoCanvas(uid: e),
  //             connection: RtcConnection(channelId: channelId),
  //             useFlutterTexture: true,
  //           ),
  //         ),
  //       ),
  //     ));
  //   } else {
  //     List<Widget> waitWidgets = List<Center>.from([
  //       Center(
  //           heightFactor: 25,
  //           child: Text(
  //             localizationOf(context).pleaseWaitForOthersToJoin,
  //             textAlign: TextAlign.center,
  //           )),
  //       const Center(
  //         child: CircularProgressIndicator(),
  //       )
  //     ]);

  //     return waitWidgets;
  //   }
  // }

  Container _translatedText() {
    var biDirectionalText = Utilities().biDirectionalText(
      context,
      text,
      style: const TextStyle(
        color: Colors.black, // Text color
        fontSize: 32.0, // Adjust font size as needed
        decoration: TextDecoration.none, // Ensure no text decoration is applied
      ),
    );
    return text.isNotEmpty
        ? Container(
            margin: biDirectionalText.textDirection == TextDirection.ltr
                ? const EdgeInsets.only(bottom: 15, left: 15)
                : const EdgeInsets.only(bottom: 15, right: 15),
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white, // Background color
              border: Border.all(color: Colors.white), // Border color
              borderRadius:
                  BorderRadius.circular(10.0), // Adjust border radius as needed
            ),
            child: biDirectionalText)
        : Container();
  }

  bool? recognizing, recognizeFinished;
  AudioTranscriber audioTranscriber = AudioTranscriber();

  // late Stream<StreamingRecognizeResponse> responseStream;

  void streamingRecognize() async {
    setState(() {
      recognizing = true;
    });

    String lastMessage = "";

    var responseStream = await audioTranscriber
        .getResponseStream(AnyChatAuth.currentUser.language);

    responseStream.listen((data) async {
      if (data.results.isEmpty || muted) return;
      String transcribedText =
          data.results.map((e) => e.alternatives.first.transcript).last;
      if (lastMessage.compareTo(transcribedText) != 0 &&
          transcribedText.isNotEmpty) {
        lastMessage = transcribedText;
        await AnyChatUser.addTranscribedMessage(lastMessage);
      }
    }, onError: (e) async {
      // await responseStream.drain();
      logger.e("CallScreen.streamingRecognize", e);
      await audioTranscriber.stopRecording();
      if (mounted) {
        streamingRecognize();
      }
    });
  }

  Stream<QuerySnapshot> loadAllTranscribedMessages() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(AnyChatAuth.currentConversation!.id)
        .collection('transcribedMessages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> _updateCallScreen(QuerySnapshot snapshot) async {
    final message = getMessageFromQuery(snapshot);
    if (message == null) return;
    if (message.senderId != AnyChatAuth.currentUser.id) {
      final language = AnyChatAuth.currentUser.language;
      final translatedText =
          await Utilities().getGoogleTranslation(language, message.text);
      setState(() {
        text = translatedText;
      });
    }
  }

  AnyChatMessage? getMessageFromQuery(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.map((DocumentSnapshot doc) {
      return AnyChatMessage.fromSnapshot(doc);
    }).last;
  }
}
