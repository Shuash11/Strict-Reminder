import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Medication category.
///
/// Fields: medicationName (required), dosage (optional), notes (optional).
class MedicationFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const MedicationFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<MedicationFields> createState() => _MedicationFieldsState();
}

class _MedicationFieldsState extends State<MedicationFields> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValues['medicationName'] ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.initialValues['dosage'] ?? '',
    );
    _notesController = TextEditingController(
      text: widget.initialValues['notes'] ?? '',
    );
  }

  void _emit() {
    widget.onChanged({
      'medicationName': _nameController.text,
      'dosage': _dosageController.text,
      'notes': _notesController.text,
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Medication name',
            hintText: 'e.g. Metformin',
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
          controller: _dosageController,
          decoration: const InputDecoration(
            labelText: 'Dosage (optional)',
            hintText: 'e.g. 500mg, 1 tablet',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: const TextStyle(color: AppColors.white),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g. take with food',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: const TextStyle(color: AppColors.white),
          maxLines: 2,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
