// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appTitle = 'Student Quiz App';
  static const String studentPanelTitle = '🎓 Học sinh Panel';

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color errorColor = Colors.red;
  static const Color goldColor = Colors.amber;

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