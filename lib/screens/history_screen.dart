import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/reminder_log.dart';
import '../services/database_service.dart';
import '../widgets/log_entry_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ReminderLog> _logs = [];
  Map<String, List<ReminderLog>> _groupedByDate = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final logs = await DatabaseService.getAllLogs();
    final grouped = <String, List<ReminderLog>>{};

    for (final log in logs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.firedAt);
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }

    // Sort entries within each date group newest-first
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.firedAt.compareTo(a.firedAt));
    }

    if (mounted) {
      setState(() {
        _logs = logs;
        _groupedByDate = grouped;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadLogs,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: _buildLogList(context),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your reminder responses will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLogList(BuildContext context) {
    final sortedKeys = _groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return [
      for (final key in sortedKeys) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            _formatDateHeader(key),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        for (final log in _groupedByDate[key]!)
          LogEntryTile(log: log),
      ],
    ];
  }

  String _formatDateHeader(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }
}
