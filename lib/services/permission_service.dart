import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions needed for the app.
  /// Returns true if all permissions were granted.
  static Future<bool> requestAll() async {
    final permissions = await [
      Permission.scheduleExactAlarm,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
      Permission.systemAlertWindow,
    ].request();

    final allGranted = permissions.values.every((status) => status.isGranted);
    debugPrint('[PermissionService] All permissions granted: $allGranted');
    return allGranted;
  }

  /// Check the status of a specific permission.
  static Future<PermissionStatus> check(Permission permission) async {
    return permission.status;
  }

  /// Open app settings if a permission is permanently denied.
  static Future<bool> openSettings() async {
    return openAppSettings();
  }

  // Convenience checks

  static Future<bool> hasExactAlarm() async {
    return (await Permission.scheduleExactAlarm.status).isGranted;
  }

  static Future<bool> hasNotification() async {
    return (await Permission.notification.status).isGranted;
  }

  static Future<bool> hasBatteryOptimization() async {
    return (await Permission.ignoreBatteryOptimizations.status).isGranted;
  }

  static Future<bool> hasSystemAlertWindow() async {
    return (await Permission.systemAlertWindow.status).isGranted;
  }

  /// Request a specific permission and return its status.
  static Future<PermissionStatus> request(Permission permission) async {
    return permission.request();
  }
}
