// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appTitle = 'Student Quiz App';
  static const String studentPanelTitle = '🎓 Học sinh Panel';

  // Colors (from Material 3 / Web UI)
  static const Color primary = Color(0xFF003D9B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0052CC);
  static const Color onPrimaryContainer = Color(0xFFC4D2FF);
  
  static const Color secondary = Color(0xFF006C47);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF82F9BE);
  static const Color onSecondaryContainer = Color(0xFF00734C);
  
  static const Color tertiary = Color(0xFF851800);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB02300);
  static const Color onTertiaryContainer = Color(0xFFFFC6B9);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color background = Color(0xFFF9F9FF);
  static const Color onBackground = Color(0xFF041B3C);
  
  static const Color surface = Color(0xFFF9F9FF);
  static const Color onSurface = Color(0xFF041B3C);
  static const Color surfaceVariant = Color(0xFFD7E2FF);
  static const Color onSurfaceVariant = Color(0xFF434654);
  
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFE8EDFF);
  static const Color surfaceContainerHigh = Color(0xFFE0E8FF);
  
  static const Color outline = Color(0xFF737685);
  static const Color outlineVariant = Color(0xFFC3C6D6);
  
  // Legacy aliases to prevent breaking changes while refactoring
  static const Color primaryColor = primary;
  static const Color surfaceColor = surface;
  static const Color onSurfaceColor = onSurface;
  static const Color successColor = secondary;
  static const Color errorColor = error;
  static const Color warningColor = tertiary;

  // Score Thresholds
  static const double excellentScoreThreshold = 0.8; // 80%
  static const double goodScoreThreshold = 0.6; // 60%

  // Timer Colors
  static const double timerGreenThreshold = 0.5; // 50%
  static const double timerOrangeThreshold = 0.25; // 25%

  // Messages
  static const String noQuizzesMessage = 'Chưa có bài thi nào';
  static const String allQuizzesCompletedMessage = 'Bạn đã hoàn thành tất cả bài thi!';
  static const String noSubmissionsMessage = 'Chưa có bài nộp nào';
  static const String answerAllQuestionsMessage = 'Vui lòng trả lời tất cả câu hỏi!';
  static const String timeUpMessage = '⏰ Hết giờ! Tự động nộp bài...';
  static const String exitConfirmMessage = 'Bạn có chắc muốn thoát? Bài làm sẽ không được lưu.';

  // Dashboard
  static const String availableQuizzesTitle = 'Bài thi khả dụng';
  static const String highlightsTitle = 'Thông tin nổi bật';

  // Icons
  static const IconData dashboardIcon = Icons.dashboard;
  static const IconData quizIcon = Icons.quiz;
  static const IconData uploadIcon = Icons.upload;
  static const IconData historyIcon = Icons.history;
  static const IconData timerIcon = Icons.timer;
  static const IconData errorIcon = Icons.error;
  static const IconData checkCircleIcon = Icons.check_circle;
  static const IconData visibilityIcon = Icons.visibility;
  static const IconData trophyIcon = Icons.emoji_events;
  static const IconData thumbUpIcon = Icons.thumb_up;
}

class AppStrings {
  // Navigation Labels
  static const String dashboard = 'Dashboard';
  static const String quizList = 'Làm bài thi';
  static const String submitQuiz = 'Nộp bài';
  static const String history = 'Lịch sử';

  // Button Labels
  static const String start = 'Bắt đầu';
  static const String submit = 'Nộp bài';
  static const String ok = 'OK';
  static const String cancel = 'Hủy';
  static const String retry = 'Thử lại';
  static const String stay = 'Ở lại';
  static const String exit = 'Thoát';

  // Labels
  static const String availableQuizzes = 'Bài thi khả dụng';
  static const String highlights = 'Thông tin nổi bật';
  static const String loading = 'Đang tải...';
  static const String score = 'Điểm';
  static const String timeSpent = 'Thời gian';
  static const String yourAnswers = 'Câu trả lời của bạn';
  static const String resultDetail = 'Chi tiết kết quả';
  static const String confirm = 'Xác nhận';
  static const String completed = '🎉 Hoàn thành!';
}