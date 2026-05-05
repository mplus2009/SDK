import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.storage,
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
      Permission.notification,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = true;
    for (final status in statuses.values) {
      if (!status.isGranted) allGranted = false;
    }
    return allGranted;
  }

  static Future<bool> requestWifiPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
