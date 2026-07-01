import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/reminder_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  final AsyncCallback onDelete;

  final VoidCallback onToggle;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onDelete,
    required this.onToggle,
  });

  String get _categoryIcon {
    switch (reminder.category) {
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

  String get _repeatLabel {
    switch (reminder.repeat) {
      case ReminderRepeatMode.once:
        return 'Once';
      case ReminderRepeatMode.daily:
        return 'Every day';
      case ReminderRepeatMode.specificDays:
        if (reminder.days.isEmpty) return 'Once';
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return reminder.days.map((d) => labels[d - 1]).join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('h:mm a').format(
      DateTime(2024, 1, 1, reminder.time.hour, reminder.time.minute),
    );

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.escalationRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        return false; // We handle removal ourselves
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Category icon
                Text(_categoryIcon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            timeString,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.repeat,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _repeatLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Enabled toggle
                Switch(
                  value: reminder.isEnabled,
                  onChanged: (_) => onToggle(),
                  activeTrackColor: AppColors.successGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
