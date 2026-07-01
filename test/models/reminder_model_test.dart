import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forreal/models/reminder_model.dart';

void main() {
  group('ReminderCategory enum', () {
    test('dbValue matches spec section 4.2', () {
      expect(ReminderCategory.medication.dbValue, 'medication');
      expect(ReminderCategory.meal.dbValue, 'meal');
      expect(ReminderCategory.hydration.dbValue, 'hydration');
      expect(ReminderCategory.exercise.dbValue, 'exercise');
      expect(ReminderCategory.sleep.dbValue, 'sleep');
      expect(ReminderCategory.selfCare.dbValue, 'self_care');
      expect(ReminderCategory.custom.dbValue, 'custom');
    });

    test('fromDb roundtrips every defined value', () {
      for (final c in ReminderCategory.values) {
        expect(ReminderCategory.fromDb(c.dbValue), c);
      }
    });

    test('fromDb falls back to custom for unknown values', () {
      expect(ReminderCategory.fromDb('nonsense'), ReminderCategory.custom);
      expect(ReminderCategory.fromDb(''), ReminderCategory.custom);
    });
  });

  group('LogResponse enum', () {
    test('dbValue matches spec (snake_case)', () {
      expect(LogResponse.completed.dbValue, 'completed');
      expect(LogResponse.snoozed.dbValue, 'snoozed');
      expect(LogResponse.rescheduled.dbValue, 'rescheduled');
      expect(LogResponse.ignored.dbValue, 'ignored');
      expect(LogResponse.missed.dbValue, 'missed');
      expect(LogResponse.disabledByUser.dbValue, 'disabled_by_user');
    });

    test('fromDb roundtrips every defined value', () {
      for (final r in LogResponse.values) {
        expect(LogResponse.fromDb(r.dbValue), r);
      }
    });

    test('fromDb falls back to missed for unknown values', () {
      expect(LogResponse.fromDb('who-knows'), LogResponse.missed);
    });
  });

  group('ReminderModel', () {
    ReminderModel makeReminder({
      ReminderCategory category = ReminderCategory.medication,
      ReminderRepeatMode repeat = ReminderRepeatMode.daily,
      List<int> days = const [1, 2, 3, 4, 5],
      bool isEnabled = true,
    }) {
      return ReminderModel(
        id: 'rem-1',
        category: category,
        title: 'Test',
        categoryFields: const {'medicationName': 'Metformin', 'dosage': '500mg'},
        confirmQuestion: 'Did you take your Metformin 500mg?',
        time: const TimeOfDay(hour: 8, minute: 30),
        repeat: repeat,
        days: days,
        isEnabled: isEnabled,
        createdAt: DateTime(2026, 1, 1, 12, 0, 0),
      );
    }

    test('defaults repeat to once, days to [], isEnabled to true', () {
      final r = ReminderModel(
        id: 'a',
        category: ReminderCategory.hydration,
        title: 'Water',
        categoryFields: const {},
        confirmQuestion: 'Drink?',
        time: const TimeOfDay(hour: 9, minute: 0),
      );
      expect(r.repeat, ReminderRepeatMode.once);
      expect(r.days, isEmpty);
      expect(r.isEnabled, isTrue);
      expect(r.createdAt, isA<DateTime>());
    });

    test('toMap serializes every field with snake_case keys', () {
      final r = makeReminder();
      final map = r.toMap();
      expect(map['id'], 'rem-1');
      expect(map['category'], 'medication');
      expect(map['title'], 'Test');
      // category_fields is JSON
      expect(map['category_fields'], contains('medicationName'));
      expect(map['confirm_question'], 'Did you take your Metformin 500mg?');
      expect(map['time_hour'], 8);
      expect(map['time_minute'], 30);
      expect(map['repeat_mode'], 'daily');
      // repeat_days is JSON
      expect(map['repeat_days'], isNotNull);
      expect(map['is_enabled'], 1);
      expect(map['created_at'], '2026-01-01T12:00:00.000');
    });

    test('toMap serializes isEnabled=false as 0', () {
      final r = makeReminder(isEnabled: false);
      expect(r.toMap()['is_enabled'], 0);
    });

    test('toMap serializes repeat=specificDays as specific_days', () {
      final r = makeReminder(repeat: ReminderRepeatMode.specificDays);
      expect(r.toMap()['repeat_mode'], 'specific_days');
    });

    test('toMap serializes repeat=once as once', () {
      final r = makeReminder(repeat: ReminderRepeatMode.once);
      expect(r.toMap()['repeat_mode'], 'once');
    });

    test('fromMap roundtrips a fully populated reminder', () {
      final original = makeReminder();
      final restored = ReminderModel.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.category, original.category);
      expect(restored.title, original.title);
      expect(restored.categoryFields, original.categoryFields);
      expect(restored.confirmQuestion, original.confirmQuestion);
      expect(restored.time.hour, original.time.hour);
      expect(restored.time.minute, original.time.minute);
      expect(restored.repeat, original.repeat);
      expect(restored.days, original.days);
      expect(restored.isEnabled, original.isEnabled);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromMap handles unknown repeat_mode by defaulting to once', () {
      final original = makeReminder();
      final map = original.toMap();
      map['repeat_mode'] = 'gibberish';
      final restored = ReminderModel.fromMap(map);
      expect(restored.repeat, ReminderRepeatMode.once);
    });

    test('fromMap handles isEnabled=0 as false', () {
      final original = makeReminder(isEnabled: false);
      final restored = ReminderModel.fromMap(original.toMap());
      expect(restored.isEnabled, isFalse);
    });

    test('copyWith only overrides supplied fields', () {
      final r = makeReminder();
      final c = r.copyWith(title: 'New Title', isEnabled: false);
      expect(c.title, 'New Title');
      expect(c.isEnabled, isFalse);
      // Unchanged
      expect(c.id, r.id);
      expect(c.category, r.category);
      expect(c.time, r.time);
      expect(c.days, r.days);
    });

    test('copyWith clones categoryFields and days (no shared references)', () {
      final r = makeReminder();
      final c = r.copyWith();
      c.categoryFields['medicationName'] = 'MUTATED';
      c.days.add(99);
      expect(r.categoryFields['medicationName'], 'Metformin');
      expect(r.days, isNot(contains(99)));
    });
  });

  group('buildTitle (spec section 5)', () {
    test('medication combines name and dose when dose is present', () {
      expect(
        buildTitle(ReminderCategory.medication, {
          'medicationName': 'Metformin',
          'dosage': '500mg',
        }),
        'Metformin 500mg',
      );
    });

    test('medication returns just the name when dose is empty', () {
      expect(
        buildTitle(ReminderCategory.medication, {'medicationName': 'Aspirin'}),
        'Aspirin',
      );
    });

    test('medication returns empty string when name and dose are missing', () {
      expect(buildTitle(ReminderCategory.medication, const {}), '');
    });

    test('meal uses mealType', () {
      expect(buildTitle(ReminderCategory.meal, {'mealType': 'Lunch'}), 'Lunch');
    });

    test('meal falls back to "Meal" when mealType is missing', () {
      expect(buildTitle(ReminderCategory.meal, const {}), 'Meal');
    });

    test('hydration always returns "Drink Water"', () {
      expect(
        buildTitle(ReminderCategory.hydration, const {}),
        'Drink Water',
      );
      expect(
        buildTitle(ReminderCategory.hydration, {'targetAmount': '2L'}),
        'Drink Water',
      );
    });

    test('exercise uses activityName', () {
      expect(
        buildTitle(ReminderCategory.exercise, {'activityName': 'Run'}),
        'Run',
      );
    });

    test('sleep uses sleepType', () {
      expect(buildTitle(ReminderCategory.sleep, {'sleepType': 'nap'}), 'nap');
    });

    test('selfCare uses taskName', () {
      expect(
        buildTitle(ReminderCategory.selfCare, {'taskName': 'Meditate'}),
        'Meditate',
      );
    });

    test('custom uses title', () {
      expect(
        buildTitle(ReminderCategory.custom, {'title': 'Pay bills'}),
        'Pay bills',
      );
    });

    test('custom falls back to "Reminder"', () {
      expect(buildTitle(ReminderCategory.custom, const {}), 'Reminder');
    });
  });

  group('buildQuestion (spec section 2.2)', () {
    test('medication with name+dose', () {
      expect(
        buildQuestion(ReminderCategory.medication, {
          'medicationName': 'Metformin',
          'dosage': '500mg',
        }),
        'Did you take your Metformin 500mg?',
      );
    });

    test('medication with name only', () {
      expect(
        buildQuestion(ReminderCategory.medication, {'medicationName': 'Aspirin'}),
        'Did you take your Aspirin?',
      );
    });

    test('medication with neither falls back gracefully', () {
      expect(
        buildQuestion(ReminderCategory.medication, const {}),
        'Did you take your medication?',
      );
    });

    test('meal uses mealType', () {
      expect(
        buildQuestion(ReminderCategory.meal, {'mealType': 'Dinner'}),
        'Did you eat your Dinner?',
      );
    });

    test('hydration with target amount', () {
      expect(
        buildQuestion(ReminderCategory.hydration, {'targetAmount': '500ml'}),
        'Did you drink water? (500ml)',
      );
    });

    test('hydration without target amount', () {
      expect(
        buildQuestion(ReminderCategory.hydration, const {}),
        'Did you drink water?',
      );
    });

    test('exercise with duration', () {
      expect(
        buildQuestion(ReminderCategory.exercise, {
          'activityName': 'Run',
          'duration': '30 min',
        }),
        'Did you complete your Run (30 min)?',
      );
    });

    test('sleep uses sleepType as the verb', () {
      expect(
        buildQuestion(ReminderCategory.sleep, {'sleepType': 'go to bed'}),
        'Did you go to bed?',
      );
    });

    test('selfCare uses taskName as the verb', () {
      expect(
        buildQuestion(ReminderCategory.selfCare, {'taskName': 'meditate'}),
        'Did you meditate?',
      );
    });

    test('custom uses confirmQuestion field', () {
      expect(
        buildQuestion(ReminderCategory.custom, {
          'confirmQuestion': 'Did you lock the door?',
        }),
        'Did you lock the door?',
      );
    });

    test('custom falls back to "Did you complete this?"', () {
      expect(
        buildQuestion(ReminderCategory.custom, const {}),
        'Did you complete this?',
      );
    });
  });
}
