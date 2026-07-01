import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Custom category.
///
/// Fields: title (required), confirmQuestion (required).
class CustomFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const CustomFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<CustomFields> createState() => _CustomFieldsState();
}

class _CustomFieldsState extends State<CustomFields> {
  late TextEditingController _titleController;
  late TextEditingController _questionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialValues['title'] ?? '',
    );
    _questionController = TextEditingController(
      text: widget.initialValues['confirmQuestion'] ?? '',
    );
  }

  void _emit() {
    widget.onChanged({
      'title': _titleController.text,
      'confirmQuestion': _questionController.text,
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Reminder title',
            hintText: 'e.g. Call the doctor',
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
          controller: _questionController,
          decoration: const InputDecoration(
            labelText: 'Confirmation question',
            hintText: 'e.g. Did you call the doctor today?',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: const TextStyle(color: AppColors.white),
          maxLines: 2,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
