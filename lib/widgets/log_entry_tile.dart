import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/reminder_log.dart';
import '../models/reminder_model.dart';

class LogEntryTile extends StatelessWidget {
  final ReminderLog log;

  const LogEntryTile({super.key, required this.log});

  String get _categoryIcon {
    switch (log.category) {
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

  String get _responseIcon {
    switch (log.response) {
      case LogResponse.completed:
        return '✅';
      case LogResponse.snoozed:
        return '🔁';
      case LogResponse.rescheduled:
        return '🔄';
      case LogResponse.ignored:
        return '⏰';
      case LogResponse.missed:
        return '❌';
      case LogResponse.disabledByUser:
        return '⏹️';
    }
  }

  Color get _responseColor {
    switch (log.response) {
      case LogResponse.completed:
        return AppColors.successGreen;
      case LogResponse.snoozed:
        return AppColors.snoozeAmber;
      case LogResponse.rescheduled:
        return Colors.cyan;
      case LogResponse.ignored:
        return AppColors.textSecondary;
      case LogResponse.missed:
        return AppColors.escalationRed;
      case LogResponse.disabledByUser:
        return AppColors.textSecondary;
    }
  }

  String get _responseLabel {
    switch (log.response) {
      case LogResponse.completed:
        return 'Done';
      case LogResponse.snoozed:
        return 'Snoozed';
      case LogResponse.rescheduled:
        return 'Rescheduled';
      case LogResponse.ignored:
        return 'Ignored';
      case LogResponse.missed:
        return 'Missed';
      case LogResponse.disabledByUser:
        return 'Disabled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firedTime = DateFormat('h:mm a').format(log.firedAt);
    final respondedTime = log.respondedAt != null
        ? DateFormat('h:mm a').format(log.respondedAt!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Category icon
            Text(_categoryIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.reminderTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fired at $firedTime${respondedTime != null ? ' · Responded $respondedTime' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                  if (log.snoozeCount > 0)
                    Text(
                      'Snoozed ${log.snoozeCount} times',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.snoozeAmber,
                      ),
                    ),
                ],
              ),
            ),
            // Response badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _responseColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _responseColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_responseIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    _responseLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: _responseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
