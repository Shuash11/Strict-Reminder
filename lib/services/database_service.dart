import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

import '../models/reminder_model.dart';
import '../models/reminder_log.dart';

class DatabaseService {
  static Database? _db;

  /// Initialize the database. Call once at app startup.
  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'forreal.db');

    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
    );

    // Insert default settings if not present
    await _seedDefaults();

    debugPrint('[DatabaseService] Database initialized at $path');
  }

  static Database get db {
    if (_db == null) {
      throw StateError('DatabaseService not initialized. Call init() first.');
    }
    return _db!;
  }

  // ---------------------------------------------------------------------------
  // Schema
  // ---------------------------------------------------------------------------

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id                TEXT PRIMARY KEY,
        category          TEXT NOT NULL,
        title             TEXT NOT NULL,
        category_fields   TEXT NOT NULL,
        confirm_question  TEXT NOT NULL,
        time_hour         INTEGER NOT NULL,
        time_minute       INTEGER NOT NULL,
        repeat_mode       TEXT NOT NULL,
        repeat_days       TEXT NOT NULL,
        is_enabled        INTEGER NOT NULL,
        created_at        TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminder_logs (
        id              TEXT PRIMARY KEY,
        reminder_id     TEXT NOT NULL,
        reminder_title  TEXT NOT NULL,
        category        TEXT NOT NULL,
        fired_at        TEXT NOT NULL,
        responded_at    TEXT,
        response        TEXT NOT NULL DEFAULT 'missed',
        snooze_count    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (reminder_id) REFERENCES reminders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_responses (
        id                TEXT PRIMARY KEY,
        reminder_id       TEXT NOT NULL,
        reminder_title    TEXT NOT NULL,
        category          TEXT NOT NULL,
        confirm_question  TEXT NOT NULL,
        fired_at          TEXT NOT NULL,
        snooze_count      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (reminder_id) REFERENCES reminders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_logs_reminder_id ON reminder_logs(reminder_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_reminder_id ON pending_responses(reminder_id)');
  }

  static Future<void> _seedDefaults() async {
    const defaults = <String, String>{
      'snooze_minutes': '5',
      'escalation_threshold': '3',
      'alarm_sound': 'buzzer',
      'screen_flash_enabled': '1',
      'vibration_enabled': '1',
      'onboarding_complete': '0',
    };

    for (final entry in defaults.entries) {
      await db.insert(
        'app_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reminders CRUD
  // ---------------------------------------------------------------------------

  static Future<void> insertReminder(ReminderModel reminder) async {
    await db.insert('reminders', reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateReminder(ReminderModel reminder) async {
    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<void> deleteReminder(String id) async {
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    await db.delete('reminder_logs', where: 'reminder_id = ?', whereArgs: [id]);
    await db.delete('pending_responses', where: 'reminder_id = ?', whereArgs: [id]);
  }

  static Future<ReminderModel?> getReminderById(String id) async {
    final rows = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ReminderModel.fromMap(rows.first);
  }

  static Future<List<ReminderModel>> getAllReminders() async {
    final rows = await db.query('reminders', orderBy: 'time_hour, time_minute');
    return rows.map((r) => ReminderModel.fromMap(r)).toList();
  }

  static Future<List<ReminderModel>> getEnabledReminders() async {
    final rows = await db.query(
      'reminders',
      where: 'is_enabled = ?',
      whereArgs: [1],
      orderBy: 'time_hour, time_minute',
    );
    return rows.map((r) => ReminderModel.fromMap(r)).toList();
  }

  // ---------------------------------------------------------------------------
  // Logs CRUD
  // ---------------------------------------------------------------------------

  static Future<void> insertLog(ReminderLog log) async {
    await db.insert('reminder_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateLog(ReminderLog log) async {
    await db.update(
      'reminder_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  static Future<List<ReminderLog>> getLogsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'reminder_logs',
      where: 'fired_at >= ? AND fired_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'fired_at DESC',
    );
    return rows.map((r) => ReminderLog.fromMap(r)).toList();
  }

  static Future<List<ReminderLog>> getLogsForReminder(String reminderId) async {
    final rows = await db.query(
      'reminder_logs',
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'fired_at DESC',
    );
    return rows.map((r) => ReminderLog.fromMap(r)).toList();
  }

  static Future<List<ReminderLog>> getAllLogs() async {
    final rows = await db.query('reminder_logs', orderBy: 'fired_at DESC');
    return rows.map((r) => ReminderLog.fromMap(r)).toList();
  }

  static Future<void> deleteLog(String id) async {
    await db.delete('reminder_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // Pending Responses
  // ---------------------------------------------------------------------------

  static Future<void> insertPendingResponse(PendingResponse pending) async {
    await db.insert('pending_responses', pending.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deletePendingResponse(String id) async {
    await db.delete('pending_responses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<PendingResponse>> getAllPendingResponses() async {
    final rows = await db.query('pending_responses');
    return rows.map((r) => PendingResponse.fromMap(r)).toList();
  }

  static Future<bool> hasPendingResponses() async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pending_responses'),
    );
    return (count ?? 0) > 0;
  }

  static Future<PendingResponse?> getPendingResponseByReminderId(
      String reminderId) async {
    final rows = await db.query(
      'pending_responses',
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'fired_at DESC',
    );
    if (rows.isEmpty) return null;
    return PendingResponse.fromMap(rows.first);
  }

  static Future<void> updatePendingResponseSnoozeCount(
      String id, int snoozeCount) async {
    await db.update(
      'pending_responses',
      {'snooze_count': snoozeCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  static Future<String?> getSetting(String key) async {
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  static Future<void> setSetting(String key, String value) async {
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> getSnoozeMinutes() async {
    final val = await getSetting('snooze_minutes');
    return int.tryParse(val ?? '5') ?? 5;
  }

  static Future<int> getEscalationThreshold() async {
    final val = await getSetting('escalation_threshold');
    return int.tryParse(val ?? '3') ?? 3;
  }

  static Future<String> getAlarmSound() async {
    return (await getSetting('alarm_sound')) ?? 'buzzer';
  }

  static Future<bool> isScreenFlashEnabled() async {
    final val = await getSetting('screen_flash_enabled');
    return val == '1';
  }

  static Future<bool> isVibrationEnabled() async {
    final val = await getSetting('vibration_enabled');
    return val == '1';
  }

  static Future<bool> isOnboardingComplete() async {
    final val = await getSetting('onboarding_complete');
    return val == '1';
  }

  static Future<void> setOnboardingComplete() async {
    await setSetting('onboarding_complete', '1');
  }

  static Future<Map<String, String>> getAllSettings() async {
    final rows = await db.query('app_settings');
    return {for (final row in rows) row['key'] as String: row['value'] as String};
  }

  /// Delete all logs and pending responses. Does NOT delete reminders or settings.
  static Future<void> resetAllHistory() async {
    await db.delete('reminder_logs');
    await db.delete('pending_responses');
  }
}
