import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/reminder_model.dart';
import '../models/reminder_log.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../widgets/smart_followup_sheet.dart';

class AlarmScreen extends StatefulWidget {
  final PendingResponse pendingResponse;

  const AlarmScreen({super.key, required this.pendingResponse});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _flashController;
  Timer? _ignoreTimer;
  int _snoozeCount = 0;
  bool _escalationMode = false;

  @override
  void initState() {
    super.initState();

    _snoozeCount = widget.pendingResponse.snoozeCount;

    // Pulsing gradient animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Flash animation (for escalation)
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Lock screen orientation and hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Start 2-minute ignore timer
    _ignoreTimer = Timer(const Duration(minutes: 2), _onIgnoreTimerFired);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flashController.dispose();
    _ignoreTimer?.cancel();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    super.dispose();
  }

  void _onIgnoreTimerFired() {
    if (!mounted) return;
    setState(() => _escalationMode = true);
    _flashController.repeat(reverse: true);
    // TODO: Increase volume in production
  }

  Future<void> _handleYes() async {
    _ignoreTimer?.cancel();
    _flashController.stop();

    final pending = widget.pendingResponse;

    // Update the latest log for this reminder
    final logs = await DatabaseService.getLogsForReminder(pending.reminderId);
    if (logs.isNotEmpty) {
      final latestLog = logs.first;
      latestLog.respondedAt = DateTime.now();
      latestLog.response = LogResponse.completed;
      latestLog.snoozeCount = _snoozeCount;
      await DatabaseService.updateLog(latestLog);
    }

    // Delete pending response
    await DatabaseService.deletePendingResponse(pending.id);

    // Stop audio (stub)
    debugPrint('[AlarmScreen] Audio stopped');

    // Schedule next occurrence if repeating
    final reminder = await DatabaseService.getReminderById(pending.reminderId);
    if (reminder != null && reminder.repeat != ReminderRepeatMode.once) {
      await AlarmService.schedule(reminder);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleNo() async {
    _ignoreTimer?.cancel();
    _flashController.stop();

    final pending = widget.pendingResponse;

    // Increment snooze count in DB
    await DatabaseService.updatePendingResponseSnoozeCount(
      pending.id,
      pending.snoozeCount + 1,
    );

    if (!mounted) return;
    setState(() {
      _snoozeCount++;
    });

    final navigator = Navigator.of(context);

    // Show the smart follow-up sheet
    final reminder = await DatabaseService.getReminderById(pending.reminderId);
    if (!mounted) return;

    if (reminder == null) {
      navigator.pop();
      return;
    }

    final result = await SmartFollowUpSheet.show(
      context: context,
      reminder: reminder,
      snoozeCount: _snoozeCount,
    );

    if (result != null && mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pendingResponse;

    return PopScope(
      canPop: false, // Cannot swipe away
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: _escalationMode && _flashController.isAnimating
                      ? [AppColors.alarmAccent, Colors.black]
                      : AppColors.alarmGradient,
                  center: Alignment.center,
                  radius: _pulseAnimation.value,
                ),
              ),
              child: _buildContent(pending),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(PendingResponse pending) {
    // Map category key from enum
    String categoryIcon;
    switch (pending.category) {
      case ReminderCategory.medication:
        categoryIcon = '💊';
      case ReminderCategory.meal:
        categoryIcon = '🍽️';
      case ReminderCategory.hydration:
        categoryIcon = '💧';
      case ReminderCategory.exercise:
        categoryIcon = '🏃';
      case ReminderCategory.sleep:
        categoryIcon = '😴';
      case ReminderCategory.selfCare:
        categoryIcon = '🧘';
      case ReminderCategory.custom:
        categoryIcon = '📋';
    }

    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Category icon
          Text(categoryIcon, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          // Reminder title
          Text(
            pending.reminderTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Current time
          Text(
            timeString,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          // Confirmation question
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              pending.confirmQuestion,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontSize: 20,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          // Yes button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton(
              onPressed: _handleYes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: AppColors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Yes, I did it!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // No button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: OutlinedButton(
              onPressed: _handleNo,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.textSecondary),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Not yet — remind me later",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          // Snooze count
          if (_snoozeCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Snoozed $_snoozeCount times',
                style: const TextStyle(
                  color: AppColors.snoozeAmber,
                  fontSize: 14,
                ),
              ),
            ),
          const Spacer(flex: 1),
          // Escalation banner
          if (_escalationMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.escalationRed.withValues(alpha: 0.8),
              child: Text(
                '⚠️ Alarm escalating — tap Yes or No to stop',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
