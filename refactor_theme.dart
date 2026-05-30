import 'dart:io';

void main() {
  final files = [
    'lib/screens/student/setting_page.dart',
    'lib/screens/student/student_panel.dart',
    'lib/screens/student/achievement_page.dart',
    'lib/screens/student/schedule_page.dart',
    'lib/screens/student/quiz_taking_page.dart',
    'lib/screens/student/class_detail_page.dart',
    'lib/screens/student/class_list_page.dart'
  ];

  final mappings = {
    'AppConstants.background': 'Theme.of(context).colorScheme.surface',
    'AppConstants.onBackground': 'Theme.of(context).colorScheme.onSurface',
    'AppConstants.surface': 'Theme.of(context).colorScheme.surface',
    'AppConstants.onSurface': 'Theme.of(context).colorScheme.onSurface',
    'AppConstants.surfaceVariant': 'Theme.of(context).colorScheme.surfaceContainerHighest',
    'AppConstants.onSurfaceVariant': 'Theme.of(context).colorScheme.onSurfaceVariant',
    'AppConstants.primary': 'Theme.of(context).colorScheme.primary',
    'AppConstants.onPrimary': 'Theme.of(context).colorScheme.onPrimary',
    'AppConstants.secondary': 'Theme.of(context).colorScheme.secondary',
    'AppConstants.onSecondary': 'Theme.of(context).colorScheme.onSecondary',
    'AppConstants.error': 'Theme.of(context).colorScheme.error',
    'AppConstants.onError': 'Theme.of(context).colorScheme.onError',
    'AppConstants.outlineVariant': 'Theme.of(context).colorScheme.outlineVariant',
    'AppConstants.surfaceContainerHigh': 'Theme.of(context).colorScheme.surfaceContainerHigh',
    'AppConstants.surfaceContainerLow': 'Theme.of(context).colorScheme.surfaceContainerLow',
    'AppConstants.surfaceContainer': 'Theme.of(context).colorScheme.surfaceContainer',
  };

  for (var filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    
    // First pass to remove `const` where `AppConstants` was used in `const Color(...)` context
    // Actually, AppConstants itself wasn't wrapped in const, but sometimes parents are.
    // Let's replace the mappings.
    for (var entry in mappings.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    
    file.writeAsStringSync(content);
    print('Refactored \$filePath');
  }
}
