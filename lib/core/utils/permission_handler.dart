// lib/features/scan_environment/utils/permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

class ScanPermissionHandler {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }
}
