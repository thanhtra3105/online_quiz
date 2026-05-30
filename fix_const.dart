import 'dart:io';

void main() {
  final files = [
    'lib/screens/student/student_panel.dart',
    'lib/screens/student/setting_page.dart',
    'lib/screens/student/schedule_page.dart',
    'lib/screens/student/class_list_page.dart',
    'lib/screens/student/achievement_page.dart'
  ];

  for (var filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    
    content = content.replaceAll(r'const Divider(color: Theme.of(context)', r'Divider(color: Theme.of(context)');
    content = content.replaceAll(r'const Icon(Icons.arrow_back, color: Theme.of(context)', r'Icon(Icons.arrow_back, color: Theme.of(context)');
    content = content.replaceAll(r"const Text('Đổi lớp', style: TextStyle(color: Theme.of(context)", r"Text('Đổi lớp', style: TextStyle(color: Theme.of(context)");
    content = content.replaceAll(r'const Icon(Icons.logout_rounded, color: Theme.of(context)', r'Icon(Icons.logout_rounded, color: Theme.of(context)');
    content = content.replaceAll(r"const Text('Đăng xuất', style: TextStyle(color: Theme.of(context)", r"Text('Đăng xuất', style: TextStyle(color: Theme.of(context)");
    content = content.replaceAll(r'const Icon(Icons.settings_outlined, color: Theme.of(context)', r'Icon(Icons.settings_outlined, color: Theme.of(context)');
    content = content.replaceAll(r'const BorderSide(color: Theme.of(context)', r'BorderSide(color: Theme.of(context)');
    content = content.replaceAll(r'const Divider(height: 1, color: Theme.of(context)', r'Divider(height: 1, color: Theme.of(context)');
    content = content.replaceAll(r'const Icon(Icons.calendar_month_outlined, color: Theme.of(context)', r'Icon(Icons.calendar_month_outlined, color: Theme.of(context)');
    content = content.replaceAll(r'const Icon(Icons.school, color: Theme.of(context)', r'Icon(Icons.school, color: Theme.of(context)');
    content = content.replaceAll(r'const Icon(Icons.emoji_events, color: Theme.of(context)', r'Icon(Icons.emoji_events, color: Theme.of(context)');
    
    file.writeAsStringSync(content);
    print('Fixed \$filePath');
  }
}
