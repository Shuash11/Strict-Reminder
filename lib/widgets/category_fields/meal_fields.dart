import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Meal category.
///
/// Fields: mealType (dropdown: Breakfast / Lunch / Dinner / Snack / Merienda).
class MealFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const MealFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<MealFields> createState() => _MealFieldsState();
}

class _MealFieldsState extends State<MealFields> {
  late String _mealType;

  static const _options = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Merienda'];

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialValues['mealType']?.isNotEmpty == true
        ? widget.initialValues['mealType']!
        : _options.first;
  }

  void _emit() {
    widget.onChanged({'mealType': _mealType});
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _mealType,
      decoration: const InputDecoration(
        labelText: 'Meal type',
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
          setState(() => _mealType = v);
          _emit();
        }
      },
    );
  }
}
