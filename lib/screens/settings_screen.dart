import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _snoozeMinutes = 5;
  int _escalationThreshold = 3;
  String _alarmSound = 'buzzer';
  bool _screenFlashEnabled = true;
  bool _vibrationEnabled = true;
  bool _loading = true;

  final _snoozeOptions = [3, 5, 10];
  final _thresholdOptions = [2, 3, 5];
  final _soundOptions = ['buzzer', 'bell', 'beep', 'gentle'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final snooze = await DatabaseService.getSnoozeMinutes();
    final threshold = await DatabaseService.getEscalationThreshold();
    final sound = await DatabaseService.getAlarmSound();
    final flash = await DatabaseService.isScreenFlashEnabled();
    final vibrate = await DatabaseService.isVibrationEnabled();

    if (mounted) {
      setState(() {
        _snoozeMinutes = snooze;
        _escalationThreshold = threshold;
        _alarmSound = sound;
        _screenFlashEnabled = flash;
        _vibrationEnabled = vibrate;
        _loading = false;
      });
    }
  }

  Future<void> _saveSnooze(int value) async {
    setState(() => _snoozeMinutes = value);
    await DatabaseService.setSetting('snooze_minutes', value.toString());
  }

  Future<void> _saveThreshold(int value) async {
    setState(() => _escalationThreshold = value);
    await DatabaseService.setSetting('escalation_threshold', value.toString());
  }

  Future<void> _saveSound(String value) async {
    setState(() => _alarmSound = value);
    await DatabaseService.setSetting('alarm_sound', value);
  }

  Future<void> _saveFlash(bool value) async {
    setState(() => _screenFlashEnabled = value);
    await DatabaseService.setSetting('screen_flash_enabled', value ? '1' : '0');
  }

  Future<void> _saveVibration(bool value) async {
    setState(() => _vibrationEnabled = value);
    await DatabaseService.setSetting('vibration_enabled', value ? '1' : '0');
  }

  Future<void> _testAlarm() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Test alarm! (stub — production would play sound)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resetHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all history?'),
        content: const Text(
          'This will delete all logs and pending responses. Reminders will not be affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.resetAllHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History reset')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Snooze duration
                _buildSectionHeader('Snooze Duration'),
                _buildChipSelector(
                  options: _snoozeOptions.map((v) => MapEntry('$v min', v)).toList(),
                  selected: _snoozeMinutes,
                  onSelected: (v) => _saveSnooze(v),
                ),
                const SizedBox(height: 24),

                // Escalation threshold
                _buildSectionHeader('Escalation Threshold'),
                _buildChipSelector(
                  options: _thresholdOptions
                      .map((v) => MapEntry('$v snoozes', v))
                      .toList(),
                  selected: _escalationThreshold,
                  onSelected: (v) => _saveThreshold(v),
                ),
                const SizedBox(height: 24),

                // Alarm sound
                _buildSectionHeader('Alarm Sound'),
                _buildChipSelector(
                  options: _soundOptions
                      .map((v) => MapEntry(v[0].toUpperCase() + v.substring(1), v))
                      .toList(),
                  selected: _alarmSound,
                  onSelected: (v) => _saveSound(v),
                ),
                const SizedBox(height: 24),

                // Toggle options
                _buildSectionHeader('Behavior'),
                SwitchListTile(
                  title: const Text('Screen flash on ignored alarm'),
                  value: _screenFlashEnabled,
                  onChanged: _saveFlash,
                  activeTrackColor: AppColors.alarmAccent,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: _vibrationEnabled,
                  onChanged: _saveVibration,
                  activeTrackColor: AppColors.alarmAccent,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),

                // Test alarm
                ElevatedButton.icon(
                  onPressed: _testAlarm,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Test Alarm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alarmAccent,
                  ),
                ),
                const SizedBox(height: 12),

                // Reset history
                OutlinedButton.icon(
                  onPressed: _resetHistory,
                  icon: const Icon(Icons.delete_sweep, color: AppColors.escalationRed),
                  label: const Text(
                    'Reset All History',
                    style: TextStyle(color: AppColors.escalationRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.escalationRed),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildChipSelector<T>({
    required List<MapEntry<String, T>> options,
    required T selected,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      children: options
          .map((opt) => ChoiceChip(
                label: Text(opt.key),
                selected: opt.value == selected,
                onSelected: (_) => onSelected(opt.value),
                selectedColor: AppColors.alarmAccent,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: opt.value == selected ? AppColors.white : AppColors.textSecondary,
                ),
              ))
          .toList(),
    );
  }
}
