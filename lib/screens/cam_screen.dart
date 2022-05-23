import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CamScreen extends StatefulWidget {
  CamScreen({Key? key}) : super(key: key);

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
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
          return Center(
            child: Text('권한이 있습니다.'),
          );
        },
      ),
    );
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

    return true; // 권한이 있는 상태
  }
}
