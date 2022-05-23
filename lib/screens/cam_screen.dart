import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/const/agora.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class CamScreen extends StatefulWidget {
  CamScreen({Key? key}) : super(key: key);

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  RtcEngine? engine; // null 이 될 수 있게,  controller처럼 사용할 수 있다
  int? uid;
  int? otherUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live'),
      ),
      body: FutureBuilder(
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (!snapshot.hasData) {
            // init()을 처음 실행하는 경우에만 에러는 없는데 데이터도 없는 경우!!
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    renderMainView(),
                    Align(
                      child: Container(
                        height: 160,
                        width: 120,
                        color: Colors.grey,
                        child: renderSubView(),
                      ),
                      alignment: Alignment.topLeft,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                    onPressed: () async {
                      if (engine != null) {
                        await engine!.leaveChannel();
                      }

                      Navigator.of(context).pop();
                    },
                    child: Text('채널 나가기')),
              )
            ],
          );
        },
      ),
    );
  }

  Widget renderSubView() {
    if (otherUid == null) {
      return Center(
        child: Text('채널에 유저가 없습니다.'),
      );
    } else {
      return RtcRemoteView.SurfaceView(
        uid: otherUid!,
        channelId: CHANNEL_NAME,
      );
    }
  }

  Widget renderMainView() {
    if (uid == null) {
      // 아무 방에도 들어가있지 않을때
      return Center(
        child: Text('채널에 참여해주세요'),
      );
    } else {
      return RtcLocalView.SurfaceView();
    }
  }

  Future<bool> init() async {
    final resp = await [Permission.camera, Permission.microphone].request();

    // 권한을 잘 받았는지 확인 해보자(map이라고 생각하면 됨)
    final cameraPermission = resp[Permission.camera]; // camera에 대한 권한
    final micPermission = resp[Permission.microphone]; // 마이크에 대한 권한

    if (cameraPermission != PermissionStatus.granted ||
        micPermission != PermissionStatus.granted) {
      // 둘 중에 하나라도 권한이 없다면
      throw '카메라 또는 마이크 권한이 없습니다.';
    }

    if (engine == null) {
      RtcEngineContext context = RtcEngineContext(APP_ID);

      engine = await RtcEngine.createWithContext(context);

      engine!.setEventHandler(
        RtcEngineEventHandler(
          joinChannelSuccess: (String channel, int uid, int elapsed) {
            print('채널에 입장했습니다. uid : $uid');
            setState(() {
              this.uid = uid;
            });
          },
          leaveChannel: (state) {
            print('채널 퇴장');
            setState(() {
              uid = null;
            });
          },
          userJoined: (int uid, int elapsed) {
            print('상대가 채널에 입장했습니다. uid : $uid');
            setState(() {
              otherUid = uid;
            });
          },
          userOffline: (int uid, UserOfflineReason reason) {
            print('상대가 채널에서 나갔습니다. uid : $uid');
            setState(() {
              otherUid = null;
            });
          },
        ),
      );

      // 비디오 활성화
      await engine!.enableVideo();

      //채널에 들어가기
      await engine!.joinChannel(
        TEMP_TOKEN,
        CHANNEL_NAME,
        null,
        0,
      );
      // optionalUid는 중복되지 않은 고유의 id값을 넣어야하는데
      // 0을 넣어주면 아고라에서 알아서 고유값 설정해줌
    }

    return true; // 권한이 있는 상태
  }
}
