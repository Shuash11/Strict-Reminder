import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/reminder_model.dart';
import '../models/reminder_log.dart';
import 'database_service.dart';

/// Stub alarm service — on a real device this would use `flutter_alarm` / `android_alarm_manager`.
///
/// Currently logs the schedule action. The full alarm scheduling requires a
/// platform-specific implementation (AlarmManager on Android, UNNotificationRequest on iOS).
class AlarmService {
  static final Map<String, Timer> _timers = {};

  /// Schedule an alarm for the given reminder.
  /// In production, this would use `AlarmManager.setExactAndAllowWhileIdle()`
  /// with STREAM_ALARM channel.
  static Future<void> schedule(ReminderModel reminder) async {
    debugPrint('[AlarmService] Scheduled alarm for "${reminder.title}" at '
        '${reminder.time.hour.toString().padLeft(2, '0')}:'
        '${reminder.time.minute.toString().padLeft(2, '0')}');

    // Cancel any existing timer for this reminder
    cancel(reminder.id);

    // Calculate milliseconds until next occurrence
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    Duration delay;
    if (scheduledTime.isAfter(now)) {
      delay = scheduledTime.difference(now);
    } else {
      // Time already passed today — schedule for tomorrow
      delay = scheduledTime.add(const Duration(days: 1)).difference(now);
    }

    debugPrint('[AlarmService] "${reminder.title}" fires in ${delay.inMinutes} minutes');

    // For debug/demo, we set a timer. On real Android, use AlarmManager.
    _timers[reminder.id] = Timer(delay, () {
      _onAlarmFired(reminder);
    });
  }

  static Future<void> scheduleNextOccurrence(ReminderModel reminder) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    Duration delay;
    if (scheduledTime.isAfter(now)) {
      delay = scheduledTime.difference(now);
    } else {
      delay = scheduledTime.add(const Duration(days: 1)).difference(now);
    }

    cancel(reminder.id);
    _timers[reminder.id] = Timer(delay, () {
      _onAlarmFired(reminder);
    });
  }

  static void scheduleOnce(ReminderModel reminder, DateTime fireAt) {
    final now = DateTime.now();
    if (fireAt.isBefore(now)) return;
    final delay = fireAt.difference(now);
    cancel(reminder.id);
    _timers[reminder.id] = Timer(delay, () {
      _onAlarmFired(reminder);
    });
  }

  /// Cancel a scheduled alarm.
  static Future<void> cancel(String reminderId) async {
    _timers[reminderId]?.cancel();
    _timers.remove(reminderId);
    debugPrint('[AlarmService] Cancelled alarm for reminder $reminderId');
  }

  /// Cancel all scheduled alarms.
  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    debugPrint('[AlarmService] Cancelled all alarms');
  }

  /// Called when an alarm fires.
  static void _onAlarmFired(ReminderModel reminder) async {
    try {
      debugPrint('[AlarmService] 🔔 Alarm FIRED for "${reminder.title}"');

      final now = DateTime.now();

      // Create and insert a pending response
      final pending = PendingResponse(
        reminderId: reminder.id,
        reminderTitle: reminder.title,
        category: reminder.category,
        confirmQuestion: reminder.confirmQuestion,
        firedAt: now,
        snoozeCount: 0,
      );
      await DatabaseService.insertPendingResponse(pending);

      // Create a log entry
      final log = ReminderLog(
        reminderId: reminder.id,
        reminderTitle: reminder.title,
        category: reminder.category,
        firedAt: now,
      );
      await DatabaseService.insertLog(log);

      // Reschedule for daily/specificDays reminders
      if (reminder.repeat == ReminderRepeatMode.daily) {
        schedule(reminder);
      } else if (reminder.repeat == ReminderRepeatMode.specificDays && reminder.days.isNotEmpty) {
        schedule(reminder);
      }

      debugPrint('[AlarmService] Pending response inserted. Navigate to AlarmScreen.');
    } catch (e, st) {
      debugPrint('[AlarmService] Error in _onAlarmFired: $e\n$st');
    }
  }

  /// Reschedule after snooze.
  static Future<void> scheduleSnooze(String reminderId, int snoozeMinutes) async {
    final reminder = await DatabaseService.getReminderById(reminderId);
    if (reminder == null) return;

    debugPrint('[AlarmService] Snoozing "${reminder.title}" for $snoozeMinutes minutes');
    cancel(reminderId);
    _timers[reminderId] = Timer(Duration(minutes: snoozeMinutes), () {
      _onAlarmFired(reminder);
    });
  }

  /// Schedule fallback alarm (after ignored follow-up sheet).
  static Future<void> scheduleFallback(String reminderId) async {
    await scheduleSnooze(reminderId, 30);
    debugPrint('[AlarmService] Fallback alarm scheduled in 30 minutes for $reminderId');
  }

  /// Schedule watchdog alarm (for app-exit scenario).
  static Future<void> scheduleWatchdog(String reminderId, int snoozeMinutes) async {
    debugPrint('[AlarmService] Watchdog scheduled for $reminderId every $snoozeMinutes min');
    // In production: use AlarmManager repeating alarm.
    // For now, just log it.
  }

  /// Cancel watchdog.
  static Future<void> cancelWatchdog(String reminderId) async {
    debugPrint('[AlarmService] Watchdog cancelled for $reminderId');
    // In production, cancel the repeating alarm.
  }
}
