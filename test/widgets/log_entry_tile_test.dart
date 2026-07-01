import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forreal/models/reminder_log.dart';
import 'package:forreal/models/reminder_model.dart';
import 'package:forreal/widgets/log_entry_tile.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

ReminderLog makeLog({
  String title = 'Metformin 500mg',
  ReminderCategory category = ReminderCategory.medication,
  LogResponse response = LogResponse.completed,
  int snoozeCount = 0,
  DateTime? respondedAt,
}) {
  return ReminderLog(
    id: 'log-1',
    reminderId: 'rem-1',
    reminderTitle: title,
    category: category,
    firedAt: DateTime(2026, 6, 1, 8, 0),
    respondedAt: respondedAt,
    response: response,
    snoozeCount: snoozeCount,
  );
}

void main() {
  testWidgets('renders the reminder title', (tester) async {
    await tester.pumpWidget(_harness(LogEntryTile(log: makeLog())));
    expect(find.text('Metformin 500mg'), findsOneWidget);
  });

  testWidgets('shows "Fired at" time', (tester) async {
    await tester.pumpWidget(_harness(LogEntryTile(log: makeLog())));
    expect(find.textContaining('Fired at'), findsOneWidget);
    expect(find.textContaining('8:00 AM'), findsOneWidget);
  });

  testWidgets('shows "Responded" time when respondedAt is set', (tester) async {
    await tester.pumpWidget(_harness(LogEntryTile(
      log: makeLog(respondedAt: DateTime(2026, 6, 1, 8, 3, 15)),
    )));
    expect(find.textContaining('Responded'), findsOneWidget);
  });

  testWidgets('omits "Responded" segment when respondedAt is null', (tester) async {
    await tester.pumpWidget(_harness(LogEntryTile(
      log: makeLog(respondedAt: null),
    )));
    expect(find.textContaining('Responded'), findsNothing);
  });

  testWidgets('shows snooze count when > 0', (tester) async {
    await tester.pumpWidget(_harness(
      LogEntryTile(log: makeLog(snoozeCount: 3)),
    ));
    expect(find.text('Snoozed 3 times'), findsOneWidget);
  });

  testWidgets('hides snooze count when 0', (tester) async {
    await tester.pumpWidget(_harness(
      LogEntryTile(log: makeLog(snoozeCount: 0)),
    ));
    expect(find.textContaining('Snoozed'), findsNothing);
  });

  testWidgets('shows correct response label for each LogResponse', (tester) async {
    final cases = <LogResponse, String>{
      LogResponse.completed: 'Done',
      LogResponse.snoozed: 'Snoozed',
      LogResponse.rescheduled: 'Rescheduled',
      LogResponse.ignored: 'Ignored',
      LogResponse.missed: 'Missed',
      LogResponse.disabledByUser: 'Disabled',
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(_harness(
        LogEntryTile(log: makeLog(response: entry.key)),
      ));
      expect(find.text(entry.value), findsOneWidget,
          reason: '${entry.key} -> ${entry.value}');
    }
  });

  testWidgets('shows correct response icon for each LogResponse', (tester) async {
    final cases = <LogResponse, String>{
      LogResponse.completed: '✅',
      LogResponse.snoozed: '🔁',
      LogResponse.rescheduled: '🔄',
      LogResponse.ignored: '⏰',
      LogResponse.missed: '❌',
      LogResponse.disabledByUser: '⏹️',
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(_harness(
        LogEntryTile(log: makeLog(response: entry.key)),
      ));
      expect(find.text(entry.value), findsOneWidget,
          reason: '${entry.key} -> ${entry.value}');
    }
  });

  testWidgets('shows correct category emoji', (tester) async {
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
        LogEntryTile(log: makeLog(category: entry.key)),
      ));
      expect(find.text(entry.value), findsOneWidget,
          reason: 'category ${entry.key} should render ${entry.value}');
    }
  });
}
