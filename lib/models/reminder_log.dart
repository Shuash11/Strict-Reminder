import 'package:uuid/uuid.dart';

import 'reminder_model.dart';

/// A single log entry recording what happened when a reminder fired.
class ReminderLog {
  String id;
  String reminderId;
  String reminderTitle;
  ReminderCategory category;
  DateTime firedAt;
  DateTime? respondedAt;
  LogResponse response;
  int snoozeCount;

  ReminderLog({
    String? id,
    required this.reminderId,
    required this.reminderTitle,
    required this.category,
    required this.firedAt,
    this.respondedAt,
    this.response = LogResponse.missed,
    this.snoozeCount = 0,
  }) : id = id ?? 'log_${const Uuid().v4()}';

  // ---------- Serialization ----------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'reminder_title': reminderTitle,
      'category': category.dbValue,
      'fired_at': firedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'response': response.dbValue,
      'snooze_count': snoozeCount,
    };
  }

  factory ReminderLog.fromMap(Map<String, dynamic> map) {
    return ReminderLog(
      id: map['id'] as String,
      reminderId: map['reminder_id'] as String,
      reminderTitle: map['reminder_title'] as String,
      category: ReminderCategory.fromDb(map['category'] as String),
      firedAt: DateTime.parse(map['fired_at'] as String),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'] as String)
          : null,
      response: LogResponse.fromDb((map['response'] as String?) ?? 'missed'),
      snoozeCount: map['snooze_count'] as int? ?? 0,
    );
  }
}

/// Track pending (unanswered) alarm fires — survives app kill.
class PendingResponse {
  String id;
  String reminderId;
  String reminderTitle;
  ReminderCategory category;
  String confirmQuestion;
  DateTime firedAt;
  int snoozeCount;

  PendingResponse({
    String? id,
    required this.reminderId,
    required this.reminderTitle,
    required this.category,
    required this.confirmQuestion,
    required this.firedAt,
    this.snoozeCount = 0,
  }) : id = id ?? 'pending_${const Uuid().v4()}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'reminder_title': reminderTitle,
      'category': category.dbValue,
      'confirm_question': confirmQuestion,
      'fired_at': firedAt.toIso8601String(),
      'snooze_count': snoozeCount,
    };
  }

  factory PendingResponse.fromMap(Map<String, dynamic> map) {
    return PendingResponse(
      id: map['id'] as String,
      reminderId: map['reminder_id'] as String,
      reminderTitle: map['reminder_title'] as String,
      category: ReminderCategory.fromDb(map['category'] as String),
      confirmQuestion: map['confirm_question'] as String,
      firedAt: DateTime.parse(map['fired_at'] as String),
      snoozeCount: map['snooze_count'] as int? ?? 0,
    );
  }
}


