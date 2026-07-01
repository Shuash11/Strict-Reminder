import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize the notification plugin. Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    } catch (e) {
      debugPrint('[NotificationService] Initialization failed: $e');
      return;
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// Handle notification tap or action.
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] Action: ${response.actionId}, payload: ${response.payload}');
    if (response.payload == null) return;
    final payload = response.payload!;

    switch (response.actionId) {
      case 'yes_action':
        debugPrint('[NotificationService] ✅ Yes action for reminder $payload');
        break;
      case 'no_action':
        debugPrint('[NotificationService] ⏰ No action for reminder $payload');
        break;
      default:
        debugPrint('[NotificationService] Notification tapped for reminder $payload');
        break;
    }
  }

  /// Show a simple notification (used for watchdog / persistent).
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool ongoing = false,
    String? actionYesId,
    String? actionYesLabel,
    String? actionNoId,
    String? actionNoLabel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'forreal_alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Critical alarm notifications for ForReal reminders',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: ongoing,
      autoCancel: !ongoing,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      actions: _buildAndroidActions(actionYesId, actionYesLabel, actionNoId, actionNoLabel),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (!_initialized) return;
    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[NotificationService] Failed to show notification: $e');
    }
  }

  static List<AndroidNotificationAction>? _buildAndroidActions(
    String? actionYesId,
    String? actionYesLabel,
    String? actionNoId,
    String? actionNoLabel,
  ) {
    final actions = <AndroidNotificationAction>[];
    if (actionYesId != null && actionYesLabel != null) {
      actions.add(AndroidNotificationAction(actionYesId, actionYesLabel));
    }
    if (actionNoId != null && actionNoLabel != null) {
      actions.add(AndroidNotificationAction(actionNoId, actionNoLabel));
    }
    return actions.isNotEmpty ? actions : null;
  }

  /// Cancel a specific notification by ID.
  static Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[NotificationService] Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications.
  static Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] Failed to cancel all notifications: $e');
    }
  }
}
