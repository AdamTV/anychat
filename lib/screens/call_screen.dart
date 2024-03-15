import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:anychat/components/anychat_auth.dart';
import 'package:anychat/components/anychat_user.dart';
import 'package:anychat/components/utilities.dart';
import 'package:anychat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = 'bf047e02fb8844a3b123b81f29f091b1';
String channelId = 'test';
const token =
    '007eJxTYODfM/WJygW/muU8Rc8uz0yNPxlxRKvrlbZrSFBsYG7knukKDElpBibmqQZGaUkWFiYmicZJhkbGSRaGaUaWaQaWhkmGYis+pDYEMjK4x95nZGSAQBCfhaEktbiEgQEATzofZg==';
final uid = AnyChatAuth.currentUser!.hashCode;

/// MultiChannel Example
class CallScreen extends StatefulWidget {
  /// Construct the [CallScreen]
  const CallScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final RtcEngine _engine;

  bool isJoined = false,
      switchCamera = true,
      switchRender = true,
      openCamera = true,
      muteCamera = false,
      muteAllRemoteVideo = false;
  Set<int> remoteUid = {};
  final ChannelProfileType _channelProfileType =
      ChannelProfileType.channelProfileLiveBroadcasting;
  late final RtcEngineEventHandler _rtcEngineEventHandler;

  String text = "";

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    _engine.unregisterEventHandler(_rtcEngineEventHandler);
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> _initEngine() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
    ));
    await [Permission.microphone, Permission.camera].request();
    AnyChatUser.addMessageToConversation(
        "${AnyChatAuth.currentUser!.displayName} ${AppLocalizations.of(Utilities.globalKey.currentContext!)!.isCallingYouOnAnyChat}");
    channelId = AnyChatAuth.currentConversation!.id;

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
    await _joinChannel();
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

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    setState(() {
      openCamera = true;
      muteCamera = false;
      muteAllRemoteVideo = false;
    });
    navigateBack();
  }

  navigateBack() {
    Navigator.pop(context);
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

  _muteLocalVideoStream() async {
    await _engine.muteLocalVideoStream(!muteCamera);
    setState(() {
      muteCamera = !muteCamera;
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
          RawMaterialButton(
            onPressed: _muteLocalVideoStream,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muteCamera
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).primaryColorLight,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muteCamera ? Icons.mic_off : Icons.mic,
              color: muteCamera
                  ? Theme.of(context).primaryColorLight
                  : Theme.of(context).colorScheme.secondary,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () async => _leaveChannel(),
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
            onPressed: _switchCamera,
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
            Column(
              children: _remoteVideo(),
            ),
            _translatedText(),
            _toolbar(),
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                height: 150,
                child: Center(
                    child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: AnyChatAuth.currentUser!.hashCode),
                    useFlutterTexture: true,
                  ),
                  onAgoraVideoViewCreated: (viewId) {
                    _engine.startPreview();
                  },
                )
                    // : const CircularProgressIndicator()),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _remoteVideo() {
    if (remoteUid.isNotEmpty) {
      return List.of(remoteUid.map(
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
      ));
    } else {
      // List<Widget> waitWidgets = List<Center>.from([
        // Center(
            // heightFactor: 25,
            // child: Text(
              // AppLocalizations.of(context)!.pleaseWaitForOthersToJoin,
              // textAlign: TextAlign.center,
            // )),
        // const Center(
          // child: CircularProgressIndicator(),
        // )
      // ]);

      // return waitWidgets;
      return [];
    }
  }

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
  // @override
  // Widget build(BuildContext context) {
  //   return ExampleActionsWidget(
  //     displayContentBuilder: (context, isLayoutHorizontal) {
  //       return Stack(
  //         children: [
  //           AgoraVideoView(
  //             controller: VideoViewController(
  //               rtcEngine: _engine,
  //               canvas: const VideoCanvas(uid: 0),
  //               useFlutterTexture: _isUseFlutterTexture,
  //               useAndroidSurfaceView: _isUseAndroidSurfaceView,
  //             ),
  //             onAgoraVideoViewCreated: (viewId) {
  //               _engine.startPreview();
  //             },
  //           ),
  //           Align(
  //             alignment: Alignment.topLeft,
  //             child: SingleChildScrollView(
  //               scrollDirection: Axis.horizontal,
  //               child: Row(
  //                 children: List.of(remoteUid.map(
  //                   (e) => SizedBox(
  //                     width: 120,
  //                     height: 120,
  //                     child: AgoraVideoView(
  //                       controller: VideoViewController.remote(
  //                         rtcEngine: _engine,
  //                         canvas: VideoCanvas(uid: e),
  //                         connection:
  //                             RtcConnection(channelId: _controller.text),
  //                         useFlutterTexture: _isUseFlutterTexture,
  //                         useAndroidSurfaceView: _isUseAndroidSurfaceView,
  //                       ),
  //                     ),
  //                   ),
  //                 )),
  //               ),
  //             ),
  //           )
  //         ],
  //       );
  //     },
  //     actionsBuilder: (context, isLayoutHorizontal) {
  //       final channelProfileType = [
  //         ChannelProfileType.channelProfileLiveBroadcasting,
  //         ChannelProfileType.channelProfileCommunication,
  //       ];
  //       final items = channelProfileType
  //           .map((e) => DropdownMenuItem(
  //                 child: Text(
  //                   e.toString().split('.')[1],
  //                 ),
  //                 value: e,
  //               ))
  //           .toList();

  //       return Column(
  //         mainAxisAlignment: MainAxisAlignment.start,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           TextField(
  //             controller: _controller,
  //             decoration: const InputDecoration(hintText: 'Channel ID'),
  //           ),
  //           if (!kIsWeb &&
  //               (defaultTargetPlatform == TargetPlatform.android ||
  //                   defaultTargetPlatform == TargetPlatform.iOS))
  //             Row(
  //               mainAxisSize: MainAxisSize.min,
  //               mainAxisAlignment: MainAxisAlignment.start,
  //               children: [
  //                 Column(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       const Text('Rendered by Flutter texture: '),
  //                       Switch(
  //                         value: _isUseFlutterTexture,
  //                         onChanged: isJoined
  //                             ? null
  //                             : (changed) {
  //                                 setState(() {
  //                                   _isUseFlutterTexture = changed;
  //                                 });
  //                               },
  //                       )
  //                     ]),
  //               ],
  //             ),
  //           const SizedBox(
  //             height: 20,
  //           ),
  //           const Text('Channel Profile: '),
  //           DropdownButton<ChannelProfileType>(
  //             items: items,
  //             value: _channelProfileType,
  //             onChanged: isJoined
  //                 ? null
  //                 : (v) {
  //                     setState(() {
  //                       _channelProfileType = v!;
  //                     });
  //                   },
  //           ),
  //           const SizedBox(
  //             height: 20,
  //           ),
  //           BasicVideoConfigurationWidget(
  //             rtcEngine: _engine,
  //             title: 'Video Encoder Configuration',
  //             setConfigButtonText: const Text(
  //               'setVideoEncoderConfiguration',
  //               style: TextStyle(fontSize: 10),
  //             ),
  //             onConfigChanged: (width, height, frameRate, bitrate) {
  //               _engine.setVideoEncoderConfiguration(VideoEncoderConfiguration(
  //                 dimensions: VideoDimensions(width: width, height: height),
  //                 frameRate: frameRate,
  //                 bitrate: bitrate,
  //               ));
  //             },
  //           ),
  //           const SizedBox(
  //             height: 20,
  //           ),
  //           Row(
  //             children: [
  //               Expanded(
  //                 flex: 1,
  //                 child: ElevatedButton(
  //                   onPressed: isJoined ? _leaveChannel : _joinChannel,
  //                   child: Text('${isJoined ? 'Leave' : 'Join'} channel'),
  //                 ),
  //               )
  //             ],
  //           ),
  //           if (!kIsWeb &&
  //               (defaultTargetPlatform == TargetPlatform.android ||
  //                   defaultTargetPlatform == TargetPlatform.iOS)) ...[
  //             const SizedBox(
  //               height: 20,
  //             ),
  //             ElevatedButton(
  //               onPressed: _switchCamera,
  //               child: Text('Camera ${switchCamera ? 'front' : 'rear'}'),
  //             ),
  //           ],
  //           if (kIsWeb) ...[
  //             const SizedBox(
  //               height: 20,
  //             ),
  //             ElevatedButton(
  //               onPressed: _muteLocalVideoStream,
  //               child: Text('Camera ${muteCamera ? 'muted' : 'unmute'}'),
  //             ),
  //             ElevatedButton(
  //               onPressed: _muteAllRemoteVideoStreams,
  //               child: Text(
  //                   'All Remote Camera ${muteAllRemoteVideo ? 'muted' : 'unmute'}'),
  //             ),
  //             ElevatedButton(
  //               onPressed: _openCamera,
  //               child: Text('Camera ${openCamera ? 'on' : 'off'}'),
  //             ),
  //           ],
  //         ],
  //       );
  //     },
  //   );
  //   // if (!_isInit) return Container();
  // }
}
