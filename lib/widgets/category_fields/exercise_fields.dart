import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Exercise / Physical Activity category.
///
/// Fields: activityName (required), duration (optional).
class ExerciseFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const ExerciseFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<ExerciseFields> createState() => _ExerciseFieldsState();
}

class _ExerciseFieldsState extends State<ExerciseFields> {
  late TextEditingController _activityController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _activityController = TextEditingController(
      text: widget.initialValues['activityName'] ?? '',
    );
    _durationController = TextEditingController(
      text: widget.initialValues['duration'] ?? '',
    );
  }

  void _emit() {
    widget.onChanged({
      'activityName': _activityController.text,
      'duration': _durationController.text,
    });
  }

  @override
  void dispose() {
    _activityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _activityController,
          decoration: const InputDecoration(
            labelText: 'Activity name',
            hintText: 'e.g. Morning Walk, Stretching',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: const TextStyle(color: AppColors.white),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _durationController,
          decoration: const InputDecoration(
            labelText: 'Duration (optional)',
            hintText: 'e.g. 30 minutes',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: const TextStyle(color: AppColors.white),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
