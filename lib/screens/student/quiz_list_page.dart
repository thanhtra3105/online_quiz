// lib/screens/student/quiz_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/quiz_schedule_service.dart';
import '../../models/quiz_schedule_model.dart';
import '../../utils/constants.dart';
import 'quiz_taking_page.dart';

class QuizListPage extends StatelessWidget {
  final String studentId;
  final String classId;

  const QuizListPage({Key? key, required this.studentId, required this.classId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getClassQuizzes(classId),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.hasError) {
          return _buildErrorWidget(quizSnapshot.error);
        }

        if (!quizSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getStudentClassSubmissions(
            studentId,
            classId,
          ),
          builder: (context, submissionSnapshot) {
            if (!submissionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final completedQuizIds = submissionSnapshot.data!.docs
                .map(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['quizId'] as String,
                )
                .toSet();

            // Lọc quiz: chưa hoàn thành
            final availableQuizzes = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .toList();

            if (availableQuizzes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 80,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn đã hoàn thành tất cả bài thi!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = availableQuizzes[index];
                final quizId = quiz.id;
                final data = quiz.data() as Map<String, dynamic>;

                // ✅ KIỂM TRA SCHEDULE CHO MỖI QUIZ
                return FutureBuilder<QuizSchedule?>(
                  future: QuizScheduleService.getSchedule(classId, quizId),
                  builder: (context, scheduleSnapshot) {
                    if (scheduleSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingCard();
                    }

                    final schedule = scheduleSnapshot.data;
                    final canTake = _checkCanTakeQuiz(schedule);
                    final statusInfo = _getStatusInfo(schedule);

                    // ❌ KHÔNG HIỂN THỊ NẾU ĐÃ ĐÓNG
                    if (schedule != null && schedule.isClosed) {
                      return const SizedBox.shrink(); // Ẩn hoàn toàn
                    }

                    return _buildQuizCard(
                      context,
                      index,
                      quizId,
                      data,
                      canTake,
                      statusInfo,
                      schedule,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    int index,
    String quizId,
    Map<String, dynamic> data,
    bool canTake,
    Map<String, dynamic> statusInfo,
    QuizSchedule? schedule,
  ) {
    final statusColor = statusInfo['color'] as Color;
    final statusText = statusInfo['text'] as String;
    final statusIcon = statusInfo['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: canTake ? Colors.grey.shade200 : Colors.orange.shade200,
          width: canTake ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với số thứ tự và status
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: canTake
                        ? AppConstants.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: canTake
                            ? AppConstants.primaryColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Bài thi chưa được đặt tên',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data['questionCount'] ?? 0} câu hỏi',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data['duration'] ?? 0} phút',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Status badge (nếu có schedule)
            if (schedule != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canTake
                      ? AppConstants.primaryColor
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: canTake
                    ? () => _startQuiz(context, quizId, data)
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canTake ? Icons.play_arrow_rounded : Icons.lock_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canTake ? 'Làm bài' : 'Chưa mở',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // LOGIC KIỂM TRA SCHEDULE
  // ============================================

  bool _checkCanTakeQuiz(QuizSchedule? schedule) {
    // Nếu không có schedule → có thể làm
    if (schedule == null) return true;

    final now = DateTime.now();

    // Kiểm tra đã đóng chưa
    if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
      return false;
    }

    // Kiểm tra đã mở chưa
    if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
      return false;
    }

    // Kiểm tra status
    return schedule.status == 'open';
  }

  Map<String, dynamic> _getStatusInfo(QuizSchedule? schedule) {
    if (schedule == null) {
      return {
        'text': 'Sẵn sàng làm bài',
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      };
    }

    final now = DateTime.now();

    // Đã đóng
    if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
      return {'text': 'Đã đóng', 'color': Colors.red, 'icon': Icons.lock};
    }

    // Chưa mở
    if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
      final timeUntil = schedule.openTime!.difference(now);
      String timeText;

      if (timeUntil.inDays > 0) {
        timeText = 'Mở sau ${timeUntil.inDays} ngày';
      } else if (timeUntil.inHours > 0) {
        timeText = 'Mở sau ${timeUntil.inHours} giờ';
      } else {
        // ✅ LÀM TRÒN LÊN: 4 phút 1 giây → hiển thị 5 phút
        final minutes = (timeUntil.inSeconds / 60).ceil();
        timeText = 'Mở sau $minutes phút';
      }

      return {'text': timeText, 'color': Colors.orange, 'icon': Icons.schedule};
    }

    // Đang mở
    if (schedule.status == 'open') {
      if (schedule.closeTime != null) {
        final timeLeft = schedule.closeTime!.difference(now);
        String timeText;

        if (timeLeft.inDays > 0) {
          timeText = 'Còn ${timeLeft.inDays} ngày';
        } else if (timeLeft.inHours > 0) {
          timeText = 'Còn ${timeLeft.inHours} giờ';
        } else {
          // ✅ LÀM TRÒN LÊN: 4 phút 1 giây → hiển thị 5 phút
          final minutes = (timeLeft.inSeconds / 60).ceil();
          timeText = 'Còn $minutes phút';
        }

        return {
          'text': timeText,
          'color': Colors.green,
          'icon': Icons.lock_open,
        };
      }

      return {
        'text': 'Đang mở',
        'color': Colors.green,
        'icon': Icons.lock_open,
      };
    }

    // Đã lên lịch
    return {
      'text': 'Đã lên lịch',
      'color': Colors.orange,
      'icon': Icons.schedule,
    };
  }

  // ============================================
  // BẮT ĐẦU LÀM BÀI
  // ============================================

  Future<void> _startQuiz(
    BuildContext context,
    String quizId,
    Map<String, dynamic> data,
  ) async {
    // Kiểm tra lần cuối trước khi vào trang làm bài
    final canTake = await QuizScheduleService.canTakeQuiz(classId, quizId);

    if (!canTake) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Bài thi chưa mở hoặc đã đóng'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    // Vào trang làm bài
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTakingPage(
          quizId: quizId,
          classId: classId,
          quizTitle: data['title'] ?? 'Quiz',
          duration: data['duration'] ?? 30,
          studentId: studentId,
        ),
      ),
    );
  }

  // ============================================
  // UI HELPERS
  // ============================================

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Lỗi: $error', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
