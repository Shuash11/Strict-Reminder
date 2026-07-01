/// Defines the metadata and field structure for each reminder category.
class CategoryConfig {
  final String label;
  final String icon;
  final List<CategoryFieldDef> fields;

  const CategoryConfig({
    required this.label,
    required this.icon,
    required this.fields,
  });

  static const Map<String, CategoryConfig> all = {
    'medication': CategoryConfig(
      label: 'Medication',
      icon: '💊',
      fields: [
        CategoryFieldDef(key: 'medicationName', label: 'Medication name', type: FieldType.text, required: true),
        CategoryFieldDef(key: 'dosage', label: 'Dosage', type: FieldType.text, required: false),
        CategoryFieldDef(key: 'notes', label: 'Notes', type: FieldType.text, required: false),
      ],
    ),
    'meal': CategoryConfig(
      label: 'Meal',
      icon: '🍽️',
      fields: [
        CategoryFieldDef(
          key: 'mealType',
          label: 'Meal type',
          type: FieldType.dropdown,
          required: true,
          options: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Merienda'],
        ),
      ],
    ),
    'hydration': CategoryConfig(
      label: 'Hydration',
      icon: '💧',
      fields: [
        CategoryFieldDef(key: 'targetAmount', label: 'Target amount', type: FieldType.text, required: false),
      ],
    ),
    'exercise': CategoryConfig(
      label: 'Exercise',
      icon: '🏃',
      fields: [
        CategoryFieldDef(key: 'activityName', label: 'Activity name', type: FieldType.text, required: true),
        CategoryFieldDef(key: 'duration', label: 'Duration', type: FieldType.text, required: false),
      ],
    ),
    'sleep': CategoryConfig(
      label: 'Sleep / Rest',
      icon: '😴',
      fields: [
        CategoryFieldDef(
          key: 'sleepType',
          label: 'Type',
          type: FieldType.dropdown,
          required: true,
          options: ['go to bed', 'wake up', 'nap'],
        ),
      ],
    ),
    'selfCare': CategoryConfig(
      label: 'Self-Care',
      icon: '🧘',
      fields: [
        CategoryFieldDef(key: 'taskName', label: 'Task name', type: FieldType.text, required: true),
      ],
    ),
    'custom': CategoryConfig(
      label: 'Custom',
      icon: '📋',
      fields: [
        CategoryFieldDef(key: 'title', label: 'Reminder title', type: FieldType.text, required: true),
        CategoryFieldDef(key: 'confirmQuestion', label: 'Confirmation question', type: FieldType.text, required: true),
      ],
    ),
  };
}

enum FieldType { text, dropdown }

class CategoryFieldDef {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options;

  const CategoryFieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
  });
}

/// Returns the follow-up question to show in SmartFollowUpSheet for a category.
String getFollowUpQuestion(String categoryKey, Map<String, String> fields) {
  switch (categoryKey) {
    case 'medication':
      final name = fields['medicationName'] ?? 'medication';
      return 'What time do you usually take your $name?';
    case 'meal':
      final meal = fields['mealType'] ?? 'meal';
      return 'What time do you usually have $meal?';
    case 'hydration':
      return "When's a good time to remind you to drink water?";
    case 'exercise':
      final activity = fields['activityName'] ?? 'activity';
      return 'What time do you usually do your $activity?';
    case 'sleep':
      final type = fields['sleepType'] ?? 'rest';
      return type == 'wake up'
          ? 'What time do you usually wake up?'
          : 'What time do you usually $type?';
    case 'selfCare':
      final task = fields['taskName'] ?? 'task';
      return 'When do you usually $task?';
    case 'custom':
      return 'When would you like to be reminded instead?';
    default:
      return 'When would you like to be reminded instead?';
  }
}
