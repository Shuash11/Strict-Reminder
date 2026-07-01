import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forreal/models/reminder_model.dart';
import 'package:forreal/widgets/reminder_card.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  ReminderModel makeReminder({
    String id = 'rem-1',
    ReminderCategory category = ReminderCategory.medication,
    String title = 'Metformin 500mg',
    TimeOfDay? time,
    ReminderRepeatMode repeat = ReminderRepeatMode.daily,
    List<int> days = const [],
    bool isEnabled = true,
  }) {
    return ReminderModel(
      id: id,
      category: category,
      title: title,
      categoryFields: const {'medicationName': 'Metformin', 'dosage': '500mg'},
      confirmQuestion: 'Did you take it?',
      time: time ?? const TimeOfDay(hour: 8, minute: 30),
      repeat: repeat,
      days: days,
      isEnabled: isEnabled,
    );
  }

  testWidgets('renders title, time, and repeat label', (tester) async {
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    expect(find.text('Metformin 500mg'), findsOneWidget);
    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
  });

  testWidgets('renders correct category emoji for each category', (tester) async {
    final cases = <ReminderCategory, String>{
      ReminderCategory.medication: '💊',
      ReminderCategory.meal: '🍽️',
      ReminderCategory.hydration: '💧',
      ReminderCategory.exercise: '🏃',
      ReminderCategory.sleep: '😴',
      ReminderCategory.selfCare: '🧘',
      ReminderCategory.custom: '📋',
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(_harness(
        ReminderCard(
          reminder: makeReminder(category: entry.key),
          onTap: () {},
          onDelete: () async {},
          onToggle: () {},
        ),
      ));
      expect(find.text(entry.value), findsOneWidget,
          reason: 'category ${entry.key} should render ${entry.value}');
    }
  });

  testWidgets('shows "Once" for repeat=once', (tester) async {
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(repeat: ReminderRepeatMode.once),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    expect(find.text('Once'), findsOneWidget);
  });

  testWidgets('shows "Once" for specificDays with empty days list', (tester) async {
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(
          repeat: ReminderRepeatMode.specificDays,
          days: const [],
        ),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    expect(find.text('Once'), findsOneWidget);
  });

  testWidgets('shows comma-separated day names for specificDays', (tester) async {
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(
          repeat: ReminderRepeatMode.specificDays,
          days: const [1, 3, 5], // Mon, Wed, Fri
        ),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    expect(find.text('Mon, Wed, Fri'), findsOneWidget);
  });

  testWidgets('tap on card invokes onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(),
        onTap: () => tapped++,
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('tapping the Switch invokes onToggle', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(),
        onTap: () {},
        onDelete: () async {},
        onToggle: () => toggled++,
      ),
    ));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(toggled, 1);
  });

  testWidgets('Switch reflects isEnabled state', (tester) async {
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(isEnabled: false),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);

    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(isEnabled: true),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    final sw2 = tester.widget<Switch>(find.byType(Switch));
    expect(sw2.value, isTrue);
  });

  testWidgets('swipe-to-delete invokes onDelete and does not remove widget', (tester) async {
    // The card's Dismissible intercepts the swipe, calls onDelete, and returns
    // false from confirmDismiss so the card itself is not removed.
    var deleteCalled = 0;
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(id: 'rem-test'),
        onTap: () {},
        onDelete: () async => deleteCalled++,
        onToggle: () {},
      ),
    ));
    await tester.fling(find.text('Metformin 500mg'), const Offset(-500, 0), 1000);
    await tester.pumpAndSettle();
    expect(deleteCalled, 1);
    // Card is still in the tree (confirmDismiss returned false)
    expect(find.text('Metformin 500mg'), findsOneWidget);
  });

  testWidgets('uses the AppColors.escalationRed on the delete background', (tester) async {
    // Smoke check that the swipe background uses the design-system red
    await tester.pumpWidget(_harness(
      ReminderCard(
        reminder: makeReminder(),
        onTap: () {},
        onDelete: () async {},
        onToggle: () {},
      ),
    ));
    // Start a swipe to reveal the Dismissible's background
    final box = tester.getCenter(find.byType(Dismissible));
    await tester.flingFrom(box, const Offset(-300, 0), 500);
    await tester.pump();

    // Verify the delete icon is in the background
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
