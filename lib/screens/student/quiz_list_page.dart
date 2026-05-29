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

            return Container(
              color: Theme.of(context).colorScheme.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Header & Filters
                    Text(
                      'Exam Library',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse and select from our comprehensive collection of practice exams to prepare for your next big test.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Filter Chips (Dummy UI to match prototype)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(context, 'All Subjects', true),
                          _buildFilterChip(context, 'Biology', false),
                          _buildFilterChip(context, 'Chemistry', false),
                          _buildFilterChip(context, 'Physics', false),
                          _buildFilterChip(context, 'Mathematics', false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (availableQuizzes.isEmpty)
                      _buildEmptyState(context)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 1200
                              ? 3
                              : constraints.maxWidth > 800
                                  ? 2
                                  : 1;
                          final cardWidth =
                              (constraints.maxWidth - (crossAxisCount - 1) * 24) /
                                  crossAxisCount;

                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: availableQuizzes.map((quiz) {
                              final quizId = quiz.id;
                              final data = quiz.data() as Map<String, dynamic>;

                              return FutureBuilder<QuizSchedule?>(
                                future: QuizScheduleService.getSchedule(
                                    classId, quizId),
                                builder: (context, scheduleSnapshot) {
                                  if (scheduleSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: _buildLoadingCard(),
                                    );
                                  }

                                  final schedule = scheduleSnapshot.data;
                                  final canTake = _checkCanTakeQuiz(schedule);
                                  final statusInfo = _getStatusInfo(schedule);

                                  // KHÔNG HIỂN THỊ NẾU ĐÃ ĐÓNG
                                  if (schedule != null && schedule.isClosed) {
                                    return const SizedBox.shrink();
                                  }

                                  return SizedBox(
                                    width: cardWidth,
                                    child: _buildQuizCard(
                                      context,
                                      quizId,
                                      data,
                                      canTake,
                                      statusInfo,
                                      schedule,
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bạn đã hoàn thành tất cả bài thi!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hiện tại không có bài thi nào mới dành cho bạn.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    String quizId,
    Map<String, dynamic> data,
    bool canTake,
    Map<String, dynamic> statusInfo,
    QuizSchedule? schedule,
  ) {
    final statusColor = statusInfo['color'] as Color;
    final statusText = statusInfo['text'] as String;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canTake
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QUIZ / EXAM',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              Icon(
                Icons.science,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['title'] ?? 'Bài thi chưa được đặt tên',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'A practice exam to test your knowledge.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data['questionCount'] ?? 0} Qs',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data['duration'] ?? 0}m',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                canTake
                    ? TextButton(
                        onPressed: () => _startQuiz(context, quizId, data),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Start',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LOGIC KIỂM TRA SCHEDULE
  // ============================================

  bool _checkCanTakeQuiz(QuizSchedule? schedule) {
    if (schedule == null) return true;
    final now = DateTime.now();
    if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
      return false;
    }
    if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
      return false;
    }
    return schedule.status == 'open';
  }

  Map<String, dynamic> _getStatusInfo(QuizSchedule? schedule) {
    if (schedule == null) {
      return {
        'text': 'Ready',
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      };
    }

    final now = DateTime.now();

    if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
      return {'text': 'Closed', 'color': Colors.red, 'icon': Icons.lock};
    }

    if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
      final timeUntil = schedule.openTime!.difference(now);
      String timeText;
      if (timeUntil.inDays > 0) {
        timeText = 'Opens in ${timeUntil.inDays}d';
      } else if (timeUntil.inHours > 0) {
        timeText = 'Opens in ${timeUntil.inHours}h';
      } else {
        final minutes = (timeUntil.inSeconds / 60).ceil();
        timeText = 'Opens in ${minutes}m';
      }
      return {'text': timeText, 'color': Colors.orange, 'icon': Icons.schedule};
    }

    if (schedule.status == 'open') {
      if (schedule.closeTime != null) {
        final timeLeft = schedule.closeTime!.difference(now);
        String timeText;
        if (timeLeft.inDays > 0) {
          timeText = '${timeLeft.inDays}d left';
        } else if (timeLeft.inHours > 0) {
          timeText = '${timeLeft.inHours}h left';
        } else {
          final minutes = (timeLeft.inSeconds / 60).ceil();
          timeText = '${minutes}m left';
        }
        return {
          'text': timeText,
          'color': Colors.green,
          'icon': Icons.lock_open,
        };
      }
      return {
        'text': 'Open',
        'color': Colors.green,
        'icon': Icons.lock_open,
      };
    }

    return {
      'text': 'Scheduled',
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
      height: 220,
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
