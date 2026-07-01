import 'dart:convert';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum ReminderCategory {
  medication,
  meal,
  hydration,
  exercise,
  sleep,
  selfCare,
  custom;

  String get dbValue {
    switch (this) {
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
        return 'self_care';
      case ReminderCategory.custom:
        return 'custom';
    }
  }

  static ReminderCategory fromDb(String value) {
    switch (value) {
      case 'medication':
        return ReminderCategory.medication;
      case 'meal':
        return ReminderCategory.meal;
      case 'hydration':
        return ReminderCategory.hydration;
      case 'exercise':
        return ReminderCategory.exercise;
      case 'sleep':
        return ReminderCategory.sleep;
      case 'self_care':
        return ReminderCategory.selfCare;
      case 'custom':
        return ReminderCategory.custom;
      default:
        return ReminderCategory.custom;
    }
  }
}

enum ReminderRepeatMode { daily, specificDays, once }

enum LogResponse {
  completed,
  snoozed,
  rescheduled,
  ignored,
  missed,
  disabledByUser;

  String get dbValue {
    switch (this) {
      case LogResponse.completed:
        return 'completed';
      case LogResponse.snoozed:
        return 'snoozed';
      case LogResponse.rescheduled:
        return 'rescheduled';
      case LogResponse.ignored:
        return 'ignored';
      case LogResponse.missed:
        return 'missed';
      case LogResponse.disabledByUser:
        return 'disabled_by_user';
    }
  }

  static LogResponse fromDb(String value) {
    switch (value) {
      case 'completed':
        return LogResponse.completed;
      case 'snoozed':
        return LogResponse.snoozed;
      case 'rescheduled':
        return LogResponse.rescheduled;
      case 'ignored':
        return LogResponse.ignored;
      case 'missed':
        return LogResponse.missed;
      case 'disabled_by_user':
        return LogResponse.disabledByUser;
      default:
        return LogResponse.missed;
    }
  }
}

// ---------------------------------------------------------------------------
// ReminderModel
// ---------------------------------------------------------------------------

class ReminderModel {
  String id;
  ReminderCategory category;
  String title;
  Map<String, String> categoryFields;
  String confirmQuestion;
  TimeOfDay time;
  ReminderRepeatMode repeat;
  List<int> days; // 1=Mon..7=Sun
  bool isEnabled;
  DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.category,
    required this.title,
    required this.categoryFields,
    required this.confirmQuestion,
    required this.time,
    this.repeat = ReminderRepeatMode.once,
    this.days = const [],
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ---------- Serialization ----------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.dbValue,
      'title': title,
      'category_fields': jsonEncode(categoryFields),
      'confirm_question': confirmQuestion,
      'time_hour': time.hour,
      'time_minute': time.minute,
      'repeat_mode': _repeatModeDbValue(repeat),
      'repeat_days': jsonEncode(days),
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String,
      category: ReminderCategory.fromDb(map['category'] as String),
      title: map['title'] as String,
      categoryFields: Map<String, String>.from(
        jsonDecode(map['category_fields'] as String) as Map,
      ),
      confirmQuestion: map['confirm_question'] as String,
      time: TimeOfDay(
        hour: map['time_hour'] as int,
        minute: map['time_minute'] as int,
      ),
      repeat: _repeatModeFromDb(map['repeat_mode'] as String),
      days: List<int>.from(jsonDecode(map['repeat_days'] as String) as List),
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ReminderModel copyWith({
    String? id,
    ReminderCategory? category,
    String? title,
    Map<String, String>? categoryFields,
    String? confirmQuestion,
    TimeOfDay? time,
    ReminderRepeatMode? repeat,
    List<int>? days,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      categoryFields: categoryFields ?? Map.from(this.categoryFields),
      confirmQuestion: confirmQuestion ?? this.confirmQuestion,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      days: days ?? List.from(this.days),
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------- Helper ----------

  static String _repeatModeDbValue(ReminderRepeatMode mode) {
    return switch (mode) {
      ReminderRepeatMode.daily => 'daily',
      ReminderRepeatMode.specificDays => 'specific_days',
      ReminderRepeatMode.once => 'once',
    };
  }

  static ReminderRepeatMode _repeatModeFromDb(String value) {
    switch (value) {
      case 'daily':
        return ReminderRepeatMode.daily;
      case 'specific_days':
        return ReminderRepeatMode.specificDays;
      case 'once':
        return ReminderRepeatMode.once;
      default:
        return ReminderRepeatMode.once;
    }
  }
}

// ---------------------------------------------------------------------------
// Title & Question builders (spec section 5)
// ---------------------------------------------------------------------------

String buildTitle(ReminderCategory category, Map<String, String> fields) {
  switch (category) {
    case ReminderCategory.medication:
      final name = fields['medicationName'] ?? '';
      final dose = fields['dosage'] ?? '';
      return dose.isNotEmpty ? '$name $dose' : name;
    case ReminderCategory.meal:
      return fields['mealType'] ?? 'Meal';
    case ReminderCategory.hydration:
      return 'Drink Water';
    case ReminderCategory.exercise:
      return fields['activityName'] ?? 'Exercise';
    case ReminderCategory.sleep:
      return fields['sleepType'] ?? 'Sleep';
    case ReminderCategory.selfCare:
      return fields['taskName'] ?? 'Self-Care';
    case ReminderCategory.custom:
      return fields['title'] ?? 'Reminder';
  }
}

String buildQuestion(ReminderCategory category, Map<String, String> fields) {
  switch (category) {
    case ReminderCategory.medication:
      final name = fields['medicationName'] ?? 'medication';
      final dose = fields['dosage'] ?? '';
      return dose.isNotEmpty
          ? 'Did you take your $name $dose?'
          : 'Did you take your $name?';
    case ReminderCategory.meal:
      final meal = fields['mealType'] ?? 'meal';
      return 'Did you eat your $meal?';
    case ReminderCategory.hydration:
      final amount = fields['targetAmount'] ?? '';
      return amount.isNotEmpty
          ? 'Did you drink water? ($amount)'
          : 'Did you drink water?';
    case ReminderCategory.exercise:
      final activity = fields['activityName'] ?? 'exercise';
      final duration = fields['duration'] ?? '';
      return duration.isNotEmpty
          ? 'Did you complete your $activity ($duration)?'
          : 'Did you complete your $activity?';
    case ReminderCategory.sleep:
      final type = fields['sleepType'] ?? 'rest';
      return 'Did you $type?';
    case ReminderCategory.selfCare:
      final task = fields['taskName'] ?? 'self-care task';
      return 'Did you $task?';
    case ReminderCategory.custom:
      return fields['confirmQuestion'] ?? 'Did you complete this?';
  }
}
