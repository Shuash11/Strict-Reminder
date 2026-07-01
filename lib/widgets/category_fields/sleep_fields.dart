import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Sleep / Rest category.
///
/// Fields: sleepType (dropdown: go to bed / wake up / nap).
class SleepFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const SleepFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<SleepFields> createState() => _SleepFieldsState();
}

class _SleepFieldsState extends State<SleepFields> {
  late String _sleepType;

  static const _options = ['go to bed', 'wake up', 'nap'];

  @override
  void initState() {
    super.initState();
    _sleepType = widget.initialValues['sleepType']?.isNotEmpty == true
        ? widget.initialValues['sleepType']!
        : _options.first;
  }

  void _emit() {
    widget.onChanged({'sleepType': _sleepType});
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _sleepType,
      decoration: const InputDecoration(
        labelText: 'Type',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.surface,
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.white),
      items: _options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() => _sleepType = v);
          _emit();
        }
      },
    );
  }
}
