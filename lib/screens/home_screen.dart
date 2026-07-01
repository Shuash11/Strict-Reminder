import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../services/update_service.dart';
import '../widgets/reminder_card.dart';
import '../widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ReminderModel> _reminders = [];
  Map<String, List<ReminderModel>> _grouped = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _loading = true);
    final reminders = await DatabaseService.getAllReminders();
    final grouped = <String, List<ReminderModel>>{};

    for (final r in reminders) {
      final period = _timePeriod(r.time.hour);
      grouped.putIfAbsent(period, () => []).add(r);
    }

    if (mounted) {
      setState(() {
        _reminders = reminders;
        _grouped = grouped;
        _loading = false;
      });
    }

    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final update = await UpdateService.checkForUpdate();
      if (update == null || !mounted) return;
      final skipped = await UpdateService.isVersionSkipped(update.latestVersion);
      if (!mounted || skipped) return;
      UpdateDialog.show(context, update);
    } catch (_) {}
  }

  String _timePeriod(int hour) {
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _navigateToAdd() {
    Navigator.pushNamed(context, '/choose-category').then((_) => _loadReminders());
  }

  void _navigateToEdit(ReminderModel reminder) {
    Navigator.pushNamed(
      context,
      '/add-reminder',
      arguments: {'category': reminder.category, 'existingReminder': reminder},
    ).then((_) => _loadReminders());
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AlarmService.cancel(reminder.id);
      await DatabaseService.deleteReminder(reminder.id);
      if (mounted) _loadReminders();
    }
  }

  Future<void> _toggleEnabled(ReminderModel reminder) async {
    final updated = reminder.copyWith(isEnabled: !reminder.isEnabled);
    await DatabaseService.updateReminder(updated);
    if (updated.isEnabled) {
      await AlarmService.schedule(updated);
    } else {
      await AlarmService.cancel(updated.id);
    }
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ForReal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildReminderList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        tooltip: 'Add Reminder',
        child: const Icon(Icons.add),
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
            Text('📋', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No reminders yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first reminder.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alarmAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderList() {
    final periods = ['Morning', 'Afternoon', 'Evening'];
    return RefreshIndicator(
      onRefresh: _loadReminders,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final period in periods)
            if (_grouped.containsKey(period)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  period,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              for (final reminder in _grouped[period]!)
                ReminderCard(
                  reminder: reminder,
                  onTap: () => _navigateToEdit(reminder),
                  onDelete: () => _deleteReminder(reminder),
                  onToggle: () => _toggleEnabled(reminder),
                ),
            ],
        ],
      ),
    );
  }
}
