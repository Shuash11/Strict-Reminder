import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/category_config.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';

/// Bottom sheet shown after the user taps "No / Not yet" on the alarm screen.
///
/// Displays a category-specific follow-up question with a time picker and
/// action buttons. Has a 60-second idle timer that auto-closes and triggers
/// a persistent notification + fallback alarm.
class SmartFollowUpSheet extends StatefulWidget {
  final ReminderModel reminder;
  final int snoozeCount;

  const SmartFollowUpSheet({
    super.key,
    required this.reminder,
    required this.snoozeCount,
  });

  /// Shows the sheet and returns `true` if the alarm screen should dismiss
  /// (user picked a new time or chose to snooze), or `null` if the sheet
  /// was closed without a final answer.
  static Future<bool?> show({
    required BuildContext context,
    required ReminderModel reminder,
    required int snoozeCount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SmartFollowUpSheet(
        reminder: reminder,
        snoozeCount: snoozeCount,
      ),
    );
  }

  @override
  State<SmartFollowUpSheet> createState() => _SmartFollowUpSheetState();
}

class _SmartFollowUpSheetState extends State<SmartFollowUpSheet> {
  late TimeOfDay _selectedTime;
  late int _snoozeMinutes;
  late int _escalationThreshold;
  Timer? _idleTimer;
  bool _sheetDismissed = false;

  String get _categoryKey {
    switch (widget.reminder.category) {
      case ReminderCategory.medication:
        return 'medication';
      case ReminderCategory.meal:
        return 'meal';
      case ReminderCategory.hydration:
        return 'hydration';
      case ReminderCategory.exercise:
        return 'exercise';
      case ReminderCategory.sleep:
        return 'sleep';
      case ReminderCategory.selfCare:
        return 'selfCare';
      case ReminderCategory.custom:
        return 'custom';
    }
  }

  bool get _escalationVisible =>
      widget.snoozeCount >= _escalationThreshold;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.reminder.time;
    _snoozeMinutes = 5;
    _escalationThreshold = 3;

    _loadSettings();
    _startIdleTimer();
  }

  Future<void> _loadSettings() async {
    final snooze = await DatabaseService.getSnoozeMinutes();
    final threshold = await DatabaseService.getEscalationThreshold();
    if (mounted) {
      setState(() {
        _snoozeMinutes = snooze;
        _escalationThreshold = threshold;
      });
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 60), () {
      _onIdleTimeout().catchError((Object e, StackTrace st) {
        debugPrint('[SmartFollowUpSheet] Idle timeout error: $e\n$st');
      });
    });
  }

  Future<void> _onIdleTimeout() async {
    if (_sheetDismissed || !mounted) return;
    _sheetDismissed = true;

    final reminder = widget.reminder;
    final pending = await DatabaseService.getPendingResponseByReminderId(
      reminder.id,
    );

    if (pending != null) {
      // Post persistent notification
      final notificationId = reminder.id.hashCode;
      await NotificationService.showNotification(
        id: notificationId,
        title: '${_categoryIcon()} ${reminder.title}',
        body: "Hey! You still haven't set a time for '${reminder.title}'. Tap to fix it now.",
        payload: reminder.id,
        ongoing: true,
        actionYesId: 'yes_action',
        actionYesLabel: 'Yes, I did it',
        actionNoId: 'no_action',
        actionNoLabel: 'Not yet',
      );

      // Schedule fallback alarm in 30 minutes
      await AlarmService.scheduleFallback(reminder.id);

      // Update log entry
      final logs = await DatabaseService.getLogsForReminder(reminder.id);
      if (logs.isNotEmpty) {
        final latestLog = logs.first;
        latestLog.response = LogResponse.ignored;
        latestLog.respondedAt = DateTime.now();
        await DatabaseService.updateLog(latestLog);
      }
    }

    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  String _categoryIcon() {
    switch (widget.reminder.category) {
      case ReminderCategory.medication:
        return '💊';
      case ReminderCategory.meal:
        return '🍽️';
      case ReminderCategory.hydration:
        return '💧';
      case ReminderCategory.exercise:
        return '🏃';
      case ReminderCategory.sleep:
        return '😴';
      case ReminderCategory.selfCare:
        return '🧘';
      case ReminderCategory.custom:
        return '📋';
    }
  }

  Future<void> _pickTime() async {
    _idleTimer?.cancel();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    _startIdleTimer();
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleUpdateTime() async {
    _idleTimer?.cancel();
    _sheetDismissed = true;

    final reminder = widget.reminder;
    final now = DateTime.now();
    final newDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updated = reminder.copyWith(time: _selectedTime);
    await DatabaseService.updateReminder(updated);

    // Cancel old alarm
    await AlarmService.cancel(reminder.id);

    if (updated.isEnabled) {
      if (newDateTime.isBefore(now) || newDateTime.isAtSameMomentAs(now)) {
        // Time already passed today — schedule for next occurrence
        await AlarmService.scheduleNextOccurrence(updated);
      } else {
        await AlarmService.schedule(updated);
      }
    }

    // Delete pending response
    final pending = await DatabaseService.getPendingResponseByReminderId(
      reminder.id,
    );
    if (pending != null) {
      await DatabaseService.deletePendingResponse(pending.id);
    }

    // Update log entry
    final logs = await DatabaseService.getLogsForReminder(reminder.id);
    if (logs.isNotEmpty) {
      final latestLog = logs.first;
      latestLog.response = LogResponse.rescheduled;
      latestLog.respondedAt = DateTime.now();
      latestLog.snoozeCount = widget.snoozeCount;
      await DatabaseService.updateLog(latestLog);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleSnooze() async {
    _idleTimer?.cancel();
    _sheetDismissed = true;

    final reminder = widget.reminder;

    // Schedule snooze
    await AlarmService.scheduleSnooze(reminder.id, _snoozeMinutes);

    // Update pending response snooze count
    final pending = await DatabaseService.getPendingResponseByReminderId(
      reminder.id,
    );
    if (pending != null) {
      await DatabaseService.updatePendingResponseSnoozeCount(
        pending.id,
        pending.snoozeCount + 1,
      );
    }

    // Update log entry
    final logs = await DatabaseService.getLogsForReminder(reminder.id);
    if (logs.isNotEmpty) {
      final latestLog = logs.first;
      latestLog.response = LogResponse.snoozed;
      latestLog.respondedAt = DateTime.now();
      latestLog.snoozeCount = widget.snoozeCount;
      await DatabaseService.updateLog(latestLog);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleDisable() async {
    _idleTimer?.cancel();
    _sheetDismissed = true;

    final reminder = widget.reminder;

    // Disable the reminder
    final updated = reminder.copyWith(isEnabled: false);
    await DatabaseService.updateReminder(updated);
    await AlarmService.cancel(reminder.id);

    // Delete pending response
    final pending = await DatabaseService.getPendingResponseByReminderId(
      reminder.id,
    );
    if (pending != null) {
      await DatabaseService.deletePendingResponse(pending.id);
    }

    // Update log entry
    final logs = await DatabaseService.getLogsForReminder(reminder.id);
    if (logs.isNotEmpty) {
      final latestLog = logs.first;
      latestLog.response = LogResponse.disabledByUser;
      latestLog.respondedAt = DateTime.now();
      await DatabaseService.updateLog(latestLog);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _timeUntilSelected() {
    final now = DateTime.now();
    final target = DateTime(
      now.year, now.month, now.day + 1,
      _selectedTime.hour, _selectedTime.minute,
    );
    final diff = target.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return 'Tomorrow, ${hours}h ${minutes}m';
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followUpQuestion = getFollowUpQuestion(
      _categoryKey,
      widget.reminder.categoryFields,
    );

    final now = DateTime.now();
    final scheduledToday = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final isTomorrow = !scheduledToday.isAfter(now);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Friendly message
          Text(
            "No worries! Let's set a better time for you.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          // Escalation banner
          if (_escalationVisible) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.escalationRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.escalationRed.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                "You've skipped this ${widget.snoozeCount} times. Want to set a better time or disable it?",
                style: TextStyle(
                  color: AppColors.escalationRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category-specific follow-up question
          Text(
            followUpQuestion,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                ),
          ),
          const SizedBox(height: 16),

          // Time picker
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.alarmAccent),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.white,
                            ),
                      ),
                      if (isTomorrow)
                        Text(
                          _timeUntilSelected(),
                          style: const TextStyle(
                            color: AppColors.snoozeAmber,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Update my reminder button
          ElevatedButton(
            onPressed: _handleUpdateTime,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text("Update my reminder to this time"),
          ),
          const SizedBox(height: 12),

          // Snooze button
          OutlinedButton(
            onPressed: _handleSnooze,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.textSecondary),
            ),
            child: Text("Just remind me in $_snoozeMinutes min"),
          ),

          // Disable button (only in escalation mode)
          if (_escalationVisible) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _handleDisable,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.escalationRed,
                ),
                child: const Text("Disable this reminder"),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
