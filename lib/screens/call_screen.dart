import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:agora_rtc_engine/rtc_channel.dart';
// import 'package:agora_rtc_engine/rtc_engine.dart';
// import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
// import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
// import 'package:anychat/components/ads.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_message.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/audio_transcriber.dart';
import 'package:anychat/components/constants.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

// import 'package:flutter/cupertino.dart';
// class CallScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }

const appId = "<-- Insert App Id -->";
const token = "<-- Insert Token -->";
const channel = "AnyChatAuth.currentConversation!.id";

class CallScreen extends StatefulWidget {
  // static late String channelName;

  const CallScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CallScreenState();

  static Future<void> requestPermissionAndNavigate() async {
    if (await Utilities.handlePermission(Permission.camera) &&
        await Utilities.handlePermission(Permission.microphone)) {
      AnyChatUser.addMessageToConversation(
          "${AnyChatAuth.currentUser!.displayName!} ${AppLocalizations.of(Utilities.globalKey.currentContext!)!.isCallingYouOnAnyChat}");
      // CallScreen.channelName = AnyChatAuth.currentConversation!.id;
      Navigator.pushNamed(Utilities.globalKey.currentContext!, "/call");
    }
  }
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  // static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;

  // RtcChannel _channel;
  String text = "";
  StreamSubscription<QuerySnapshot>? _transcribedChatMessageSubscription;

  get defaultTargetPlatform => null;

  _CallScreenState() {
    _transcribedChatMessageSubscription =
        loadAllTranscribedMessages().listen(_updateCallScreen);
  }

  @override
  void dispose() {
    _transcribedChatMessageSubscription?.cancel();
    // clear transcribedMessages
    AnyChatUser.clearTranscribedMessages();
    // logger.d(_infoStrings);
    // clear users
    remoteUid.clear();
    // destroy sdk
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
  }

  Future<void> initialize() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    if (agoraAppId.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    //await _initAgoraRtcEngine();
    // _addAgoraEventHandlers();
    // await _engine.enableWebSdkInteroperability(true);
    // _channel = await RtcChannel.create(CallScreen.channelName);
    setState(() {});
    // _addListener(_channel!);
    // await _channel!.setClientRole(ClientRole.Broadcaster);
    // await _channel!.publish();
    // await _channel!.joinChannel(null, null, 0, ChannelMediaOptions());
    streamingRecognize();
    // await _engine.joinChannel(null, CallScreen.channelName, null, 0);
  }

  // /// Create agora sdk instance and initialize
  // Future<void> _initAgoraRtcEngine() async {
  //   _engine = await RtcEngine.createWithConfig(RtcEngineConfig(agoraAppId));
  //   await _engine.enableVideo();
  //   await _engine.startPreview();
  //   await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
  //   await _engine.setClientRole(ClientRole.Broadcaster);
  // }

  /// Add agora event handlers
  // void _addAgoraEventHandlers() {
  //   _engine.setEventHandler(RtcEngineEventHandler(
  //     error: (code) {
  //       setState(() {
  //         final info = 'onError: $code';
  //         _infoStrings.add(info);
  //       });
  //     },
  //     joinChannelSuccess: (channel, uid, elapsed) {
  //       setState(() {
  //         final info = 'onJoinChannel: $channel, uid: $uid';
  //         _infoStrings.add(info);
  //       });
  //     },
  //     leaveChannel: (stats) {
  //       setState(() {
  //         _infoStrings.add('onLeaveChannel');
  //         remoteUid.clear();
  //       });
  //     },
  //     userJoined: (uid, elapsed) {
  //       setState(() {
  //         final info = 'userJoined: $uid';
  //         _infoStrings.add(info);
  //         remoteUid.add(uid);
  //       });
  //     },
  //     userOffline: (uid, reason) {
  //       setState(() {
  //         final info = 'userOffline: $uid , reason: $reason';
  //         _infoStrings.add(info);
  //         remoteUid.remove(uid);
  //       });
  //     },
  //     firstRemoteVideoFrame: (uid, width, height, elapsed) {
  //       setState(() {
  //         final info = 'firstRemoteVideoFrame: $uid';
  //         _infoStrings.add(info);
  //       });
  //     },
  //   ));
  // }

  Container _translatedText() {
    return text.isNotEmpty
        ? Container(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.only(top: 24, right: 24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20))),
              child: Text(text,
                  style: const TextStyle(
                      backgroundColor: Colors.white,
                      color: Colors.black54,
                      fontSize: 32)),
            ))
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
        .getResponseStream(AnyChatAuth.currentUser!.language);

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
      logger.d(e);
      await audioTranscriber.stopRecording();
      if (mounted) {
        streamingRecognize();
      }
    });

    // setState(() {
    //   recognizing = true;
    // });
    // final serviceAccount = ServiceAccount.fromString(
    //     '${(await rootBundle.loadString('assets/anychat-c414a-7669166c30f5.json'))}');
    // speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    //
    // final config = _getConfig();
    //
    // responseStream = speechToText.streamingRecognize(
    //     StreamingRecognitionConfig(config: config, interimResults: true),
    //     await _getAudioStream());
    // String lastMessage = "";
    // responseStream.listen((data) {
    //   String transcribedText =
    //       data.results.map((e) => e.alternatives.first.transcript).join('\n');
    //   if (lastMessage.compareTo(transcribedText) != 0 &&
    //       transcribedText.isNotEmpty) {
    //     lastMessage = transcribedText;
    //     AnyChatUser.addTranscribedMessage(lastMessage);
    //     // setState(() {
    //     //   text =
    //     //       data.results.map((e) => e.alternatives.first.transcript).join('\n');
    //     //   recognizeFinished = true;
    //     // });
    //   }
    // }, onDone: () {
    //   if (mounted) {
    //     setState(() {
    //       recognizing = false;
    //     });
    //   }
    // }, onError: (e) {
    //   responseStream.drain();
    //   speechToText?.dispose();
    //   streamingRecognize();
    // });
  }

  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muted
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).primaryColorLight,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted
                  ? Theme.of(context).primaryColorLight
                  : Theme.of(context).colorScheme.secondary,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () async => _onCallEnd(),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              Icons.call_end,
              color: Theme.of(context).primaryColorLight,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Theme.of(context).primaryColorLight,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.switch_camera,
              color: Theme.of(context).colorScheme.secondary,
              size: 20.0,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.title,
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            _remoteVideo(),
            _translatedText(),
            _toolbar(),
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                height: 150,
                child: Center(
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function to get list of native views
  // List<Widget> _getRenderViews() {
  //   return List.of(remoteUid.map(
  //     (e) => Container(
  //       width: 120,
  //       height: 120,
  //       child: RtcRemoteView.SurfaceView(
  //         uid: e,
  //         channelId: CallScreen.channelName,
  //       ),
  //     ),
  //   ));
  // }

  /// Video view wrapper
  // Widget _videoView(view) {
  //   return Expanded(child: Container(child: view));
  // }

  /// Video view row wrapper
  // Widget _expandedVideoRow(List<Widget> views) {
  //   final wrappedViews = views.map<Widget>(_videoView).toList();
  //   return Expanded(
  //     child: Row(
  //       children: wrappedViews,
  //     ),
  //   );
  // }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  /// Video layout wrapper
  // Widget _viewRows() {
  //   return Column(
  //     children: [
  //       Expanded(
  //         child: Stack(
  //           children: [
  //             SingleChildScrollView(
  //                 scrollDirection: Axis.horizontal,
  //                 child: Row(
  //                   children: List.of(remoteUid.map(
  //                     (e) => SizedBox(
  //                       width: MediaQuery.of(context).size.width,
  //                       height: MediaQuery.of(context).size.height,
  //                       child: Center(
  //                         child: _localUserJoined
  //                             ? AgoraVideoView(
  //                           controller: VideoViewController.remote(
  //                             rtcEngine: _engine,
  //                             canvas: const VideoCanvas(uid: 0),
  //                             connection: const RtcConnection(channelId: channel),
  //                           ),
  //                         )
  //                             : const CircularProgressIndicator(),
  //                       ),
  //                     ),
  //                   )),
  //                 )),
  //             Container(
  //               padding: const EdgeInsets.only(top: 12, left: 12),
  //               width: 120,
  //               height: 120,
  //               child: Align(
  //                   alignment: Alignment.topLeft,
  //                   child: RtcLocalView.SurfaceView(
  //                     channelId: _channel?.channelId,
  //                   )),
  //             )
  //           ],
  //         ),
  //       )
  //     ],
  //   );

  // var getRenderViews = _getRenderViews();
  // final views = getRenderViews;
  // switch (views.length) {
  //   case 1:
  //     return Container(
  //         child: Column(
  //       children: <Widget>[_videoView(views[0])],
  //     ));
  //   case 2:
  //     return Container(
  //         child: Column(
  //       children: <Widget>[
  //         _expandedVideoRow([views[0]]),
  //         _expandedVideoRow([views[1]])
  //       ],
  //     ));
  //   case 3:
  //     return Container(
  //         child: Column(
  //       children: <Widget>[
  //         _expandedVideoRow(views.sublist(0, 2)),
  //         _expandedVideoRow(views.sublist(2, 3))
  //       ],
  //     ));
  //   case 4:
  //     return Container(
  //         child: Column(
  //       children: <Widget>[
  //         _expandedVideoRow(views.sublist(0, 2)),
  //         _expandedVideoRow(views.sublist(2, 4))
  //       ],
  //     ));
  //   default:
  // }
  // return Container();
  // }

  Future<void> _onCallEnd() async {
    muted = true;
    await audioTranscriber.stopRecording();
    dispose();
    AnyChatUser.clearTranscribedMessages();
    // if (await Ads.interstitial.isLoaded ?? false) {
    //   Ads.interstitial.show();
    // } else {
    //   logger.d('Interstitial ad is still laoding...');
    // }
    Navigator.pushNamed(
        mounted ? context : Utilities.globalKey.currentContext!,
        '/chat');
  }

  Future<void> _onToggleMute() async {
    setState(() {
      muted = !muted;
    });
    await _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
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
    if (message.senderId != AnyChatAuth.currentUser!.id) {
      final language = AnyChatAuth.currentUser!.language;
      final translatedText =
          await Utilities.getGoogleTranslation(language, message.text);
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

  List<int> remoteUid = [];

  // // _addListener(RtcChannel channel) {
  // //   // String channelId = channel.channelId;
  // //   channel.setEventHandler(
  // //       RtcChannelEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
  // //     log('joinChannelSuccess $channel $uid $elapsed');
  // //     // if (channelId == _channelId0) {
  // //     //   setState(() {
  // //     //     isJoined0 = true;
  // //     //   });
  // //     // } else if (channelId == _channelId1) {
  // //     //   setState(() {
  // //     //     isJoined1 = true;
  // //     //   });
  // //     // }
  // //   }, userJoined: (uid, elapsed) {
  // //     log('userJoined ${channel.channelId} $uid $elapsed');
  // //   }, userOffline: (uid, reason) {
  // //     log('userOffline ${channel.channelId} $uid $reason');
  // //   }, leaveChannel: (stats) {
  // //     log('leaveChannel ${channel.channelId} ${stats.toJson()}');
  // //     // if (channelId == _channelId0) {
  // //     //   this.setState(() {
  // //     //     isJoined0 = false;
  // //     //     remoteUid0.clear();
  // //     //   });
  // //     // } else if (channelId == _channelId1) {
  // //     //   this.setState(() {
  // //     //     isJoined1 = false;
  // //     //     remoteUid1.clear();
  // //     //   });
  // //     // }
  // //   }, remoteVideoStateChanged: (uid, state, reason, elapsed) {
  // //     log('remoteVideoStateChanged $uid $state $reason $elapsed');
  // //     if (state == VideoRemoteState.Starting) {
  // //       setState(() {
  // //         remoteUid.add(uid);
  // //       });
  // //     } else if (state == VideoRemoteState.Stopped) {
  // //       setState(() {
  // //         remoteUid.removeWhere((element) => element == uid);
  // //       });
  // //     }
  // //   }));
  // }
}
