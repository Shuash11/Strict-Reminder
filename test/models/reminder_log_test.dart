import 'package:flutter_test/flutter_test.dart';

import 'package:forreal/models/reminder_log.dart';
import 'package:forreal/models/reminder_model.dart';

void main() {
  group('ReminderLog', () {
    test('defaults response to missed and snoozeCount to 0', () {
      final log = ReminderLog(
        id: 'log-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        firedAt: DateTime(2026, 6, 1, 8, 0),
      );
      expect(log.response, LogResponse.missed);
      expect(log.snoozeCount, 0);
      expect(log.respondedAt, isNull);
    });

    test('toMap serializes every field, leaves respondedAt null-safe', () {
      final fired = DateTime(2026, 6, 1, 8, 0);
      final log = ReminderLog(
        id: 'log-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        firedAt: fired,
      );
      final map = log.toMap();
      expect(map['id'], 'log-1');
      expect(map['reminder_id'], 'rem-1');
      expect(map['reminder_title'], 'Metformin');
      expect(map['category'], 'medication');
      expect(map['fired_at'], fired.toIso8601String());
      expect(map['responded_at'], isNull);
      expect(map['response'], 'missed');
      expect(map['snooze_count'], 0);
    });

    test('fromMap roundtrips with respondedAt present', () {
      final fired = DateTime(2026, 6, 1, 8, 0);
      final responded = DateTime(2026, 6, 1, 8, 3, 15);
      final original = ReminderLog(
        id: 'log-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        firedAt: fired,
        respondedAt: responded,
        response: LogResponse.completed,
        snoozeCount: 2,
      );
      final restored = ReminderLog.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.reminderId, original.reminderId);
      expect(restored.reminderTitle, original.reminderTitle);
      expect(restored.category, original.category);
      expect(restored.firedAt, fired);
      expect(restored.respondedAt, responded);
      expect(restored.response, LogResponse.completed);
      expect(restored.snoozeCount, 2);
    });

    test('fromMap handles null responded_at by leaving respondedAt null', () {
      final original = ReminderLog(
        id: 'log-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        firedAt: DateTime(2026, 6, 1, 8, 0),
      );
      final restored = ReminderLog.fromMap(original.toMap());
      expect(restored.respondedAt, isNull);
    });

    test('fromMap defaults snooze_count when missing', () {
      final original = ReminderLog(
        id: 'log-1',
        reminderId: 'rem-1',
        reminderTitle: 'X',
        category: ReminderCategory.custom,
        firedAt: DateTime(2026, 6, 1),
      );
      final map = original.toMap()..remove('snooze_count');
      final restored = ReminderLog.fromMap(map);
      expect(restored.snoozeCount, 0);
    });
  });

  group('PendingResponse', () {
    test('defaults snoozeCount to 0', () {
      final p = PendingResponse(
        id: 'p-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        confirmQuestion: 'Did you take it?',
        firedAt: DateTime(2026, 6, 1, 8, 0),
      );
      expect(p.snoozeCount, 0);
    });

    test('toMap serializes every field', () {
      final p = PendingResponse(
        id: 'p-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        confirmQuestion: 'Did you take it?',
        firedAt: DateTime(2026, 6, 1, 8, 0),
        snoozeCount: 1,
      );
      final map = p.toMap();
      expect(map['id'], 'p-1');
      expect(map['reminder_id'], 'rem-1');
      expect(map['reminder_title'], 'Metformin');
      expect(map['category'], 'medication');
      expect(map['confirm_question'], 'Did you take it?');
      expect(map['fired_at'], DateTime(2026, 6, 1, 8, 0).toIso8601String());
      expect(map['snooze_count'], 1);
    });

    test('fromMap roundtrips', () {
      final p = PendingResponse(
        id: 'p-1',
        reminderId: 'rem-1',
        reminderTitle: 'Metformin',
        category: ReminderCategory.medication,
        confirmQuestion: 'Did you take it?',
        firedAt: DateTime(2026, 6, 1, 8, 0),
        snoozeCount: 2,
      );
      final restored = PendingResponse.fromMap(p.toMap());
      expect(restored.id, p.id);
      expect(restored.reminderId, p.reminderId);
      expect(restored.reminderTitle, p.reminderTitle);
      expect(restored.category, p.category);
      expect(restored.confirmQuestion, p.confirmQuestion);
      expect(restored.firedAt, p.firedAt);
      expect(restored.snoozeCount, p.snoozeCount);
    });

    test('fromMap defaults snooze_count when missing', () {
      final p = PendingResponse(
        id: 'p-1',
        reminderId: 'rem-1',
        reminderTitle: 'X',
        category: ReminderCategory.custom,
        confirmQuestion: 'Q',
        firedAt: DateTime(2026, 6, 1),
      );
      final map = p.toMap()..remove('snooze_count');
      final restored = PendingResponse.fromMap(map);
      expect(restored.snoozeCount, 0);
    });
  });
}
