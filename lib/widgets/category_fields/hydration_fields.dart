import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Form fields for the Hydration / Water category.
///
/// Fields: targetAmount (optional).
class HydrationFields extends StatefulWidget {
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const HydrationFields({
    super.key,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<HydrationFields> createState() => _HydrationFieldsState();
}

class _HydrationFieldsState extends State<HydrationFields> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialValues['targetAmount'] ?? '',
    );
  }

  void _emit() {
    widget.onChanged({'targetAmount': _amountController.text});
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Target amount (optional)',
        hintText: 'e.g. 2 glasses, 500ml',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.surface,
      ),
      style: const TextStyle(color: AppColors.white),
      onChanged: (_) => _emit(),
    );
  }
}
