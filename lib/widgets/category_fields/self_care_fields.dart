import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Self-Care / Hygiene category.
///
/// Fields: taskName (required).
class SelfCareFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const SelfCareFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<SelfCareFields> createState() => _SelfCareFieldsState();
}

class _SelfCareFieldsState extends State<SelfCareFields> {
  late TextEditingController _taskController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(
      text: widget.initialValues['taskName'] ?? '',
    );
  }

  void _emit() {
    widget.onChanged({'taskName': _taskController.text});
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _taskController,
      decoration: const InputDecoration(
        labelText: 'Task name',
        hintText: 'e.g. Brush teeth, Take a bath',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: const TextStyle(color: AppColors.white),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
      onChanged: (_) => _emit(),
    );
  }
}
