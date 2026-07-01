import 'package:flutter_test/flutter_test.dart';

import 'package:forreal/constants/category_config.dart';

void main() {
  group('CategoryConfig.all', () {
    test('contains every category key expected by the spec', () {
      expect(CategoryConfig.all.keys, containsAll(<String>[
      'medication',
      'meal',
      'hydration',
      'exercise',
      'sleep',
      'selfCare',
      'custom',
    ]));
    });

    test('every category has a non-empty label and icon', () {
      for (final entry in CategoryConfig.all.entries) {
        expect(entry.value.label, isNotEmpty, reason: '${entry.key} label');
        expect(entry.value.icon, isNotEmpty, reason: '${entry.key} icon');
        expect(entry.value.fields, isNotEmpty, reason: '${entry.key} fields');
      }
    });

    test('medication fields include name (required) and dosage (optional)', () {
      final med = CategoryConfig.all['medication']!;
      final name = med.fields.firstWhere(
        (f) => f.key == 'medicationName',
        orElse: () => fail('medicationName field missing'),
      );
      expect(name.required, isTrue);
      expect(name.type, FieldType.text);
      final dose = med.fields.firstWhere(
        (f) => f.key == 'dosage',
        orElse: () => fail('dosage field missing'),
      );
      expect(dose.required, isFalse);
    });

    test('meal has a dropdown with the expected meal-type options', () {
      final meal = CategoryConfig.all['meal']!;
      final type = meal.fields.firstWhere(
        (f) => f.key == 'mealType',
        orElse: () => fail('mealType field missing'),
      );
      expect(type.type, FieldType.dropdown);
      expect(type.required, isTrue);
      expect(type.options, containsAll(['Breakfast', 'Lunch', 'Dinner']));
    });

    test('sleep has a dropdown including the "wake up" verb option', () {
      // The spec / getFollowUpQuestion needs 'wake up' to work
      final sleep = CategoryConfig.all['sleep']!;
      final type = sleep.fields.firstWhere(
        (f) => f.key == 'sleepType',
        orElse: () => fail('sleepType field missing'),
      );
      expect(type.type, FieldType.dropdown);
      expect(type.options, contains('wake up'));
    });

    test('custom requires both title and confirmQuestion', () {
      final custom = CategoryConfig.all['custom']!;
      final title = custom.fields.firstWhere((f) => f.key == 'title');
      final cq = custom.fields.firstWhere((f) => f.key == 'confirmQuestion');
      expect(title.required, isTrue);
      expect(cq.required, isTrue);
    });
  });

  group('getFollowUpQuestion (Smart Follow-Up Sheet)', () {
    test('medication uses medicationName', () {
      expect(
        getFollowUpQuestion('medication', {'medicationName': 'Metformin'}),
        'What time do you usually take your Metformin?',
      );
    });

    test('medication falls back to "medication" when name is missing', () {
      expect(
        getFollowUpQuestion('medication', const {}),
        'What time do you usually take your medication?',
      );
    });

    test('meal uses mealType', () {
      expect(
        getFollowUpQuestion('meal', {'mealType': 'Dinner'}),
        'What time do you usually have Dinner?',
      );
    });

    test('hydration is a fixed question (no field substitution)', () {
      expect(
        getFollowUpQuestion('hydration', const {}),
        "When's a good time to remind you to drink water?",
      );
    });

    test('exercise uses activityName', () {
      expect(
        getFollowUpQuestion('exercise', {'activityName': 'Run'}),
        'What time do you usually do your Run?',
      );
    });

    test('sleep with sleepType=go to bed uses the type as verb', () {
      expect(
        getFollowUpQuestion('sleep', {'sleepType': 'go to bed'}),
        'What time do you usually go to bed?',
      );
    });

    test('sleep with sleepType=wake up gets a special-cased question', () {
      expect(
        getFollowUpQuestion('sleep', {'sleepType': 'wake up'}),
        'What time do you usually wake up?',
      );
    });

    test('selfCare uses taskName as the verb', () {
      expect(
        getFollowUpQuestion('selfCare', {'taskName': 'meditate'}),
        'When do you usually meditate?',
      );
    });

    test('custom returns the generic "When would you like..." prompt', () {
      expect(
        getFollowUpQuestion('custom', const {}),
        'When would you like to be reminded instead?',
      );
    });

    test('unknown category returns the generic fallback', () {
      expect(
        getFollowUpQuestion('nonsense', const {}),
        'When would you like to be reminded instead?',
      );
    });
  });
}
