import 'package:flutter/material.dart';

import '../constants/category_config.dart';
import '../models/reminder_model.dart';

class ChooseCategoryScreen extends StatelessWidget {
  const ChooseCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What kind of reminder?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: CategoryConfig.all.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final entry = CategoryConfig.all.entries.elementAt(index);
            final key = entry.key;
            final config = entry.value;

            return _CategoryTile(
              icon: config.icon,
              label: config.label,
              onTap: () {
                final category = _categoryFromKey(key);
                Navigator.pushNamed(
                  context,
                  '/add-reminder',
                  arguments: {'category': category, 'existingReminder': null},
                );
              },
            );
          },
        ),
      ),
    );
  }

  ReminderCategory _categoryFromKey(String key) {
    switch (key) {
      case 'medication':
        return ReminderCategory.medication;
      case 'meal':
        return ReminderCategory.meal;
      case 'hydration':
        return ReminderCategory.hydration;
      case 'exercise':
        return ReminderCategory.exercise;
      case 'sleep':
        return ReminderCategory.sleep;
      case 'selfCare':
        return ReminderCategory.selfCare;
      case 'custom':
        return ReminderCategory.custom;
      default:
        return ReminderCategory.custom;
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
