// lib/screens/student/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class HistoryPage extends StatefulWidget {
  final String studentId;
  final String classId;

  const HistoryPage({Key? key, required this.studentId, required this.classId})
      : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          width: double.infinity,
          color: AppConstants.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exam History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Xem lại điểm số và chi tiết bài làm của bạn.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppConstants.outlineVariant),

        // Submissions List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('classId', isEqualTo: widget.classId)
                .where('studentId', isEqualTo: widget.studentId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppConstants.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppConstants.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppConstants.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không thể tải lịch sử bài làm',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final submissions = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final doc = submissions[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final score = data['score'] ?? 0;
                  final total = data['totalQuestions'] ?? 1;
                  final percentage = (score / total * 100);
                  final scoreColor = _getScoreColor(percentage);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.outlineVariant),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showSubmissionDetail(context, doc.id, data),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Score Circle
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: scoreColor, width: 2.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: scoreColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '$score/$total',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: scoreColor.withValues(alpha: 0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['quizTitle'] ?? 'Bài thi',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppConstants.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 12,
                                          color: AppConstants.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(data['timestamp']),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppConstants.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 12,
                                          color: AppConstants.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDuration(data['timeSpent'] ?? 0),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppConstants.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Score badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: scoreColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        _getScoreLabel(percentage),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: scoreColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppConstants.onSurfaceVariant,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppConstants.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_edu_outlined,
                size: 56,
                color: AppConstants.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có bài làm nào',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hoàn thành bài thi đầu tiên của bạn để xem lịch sử.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF006C47); // secondary (green)
    if (percentage >= 50) return const Color(0xFFB86200); // amber
    return AppConstants.error; // red
  }

  String _getScoreLabel(double percentage) {
    if (percentage >= 80) return 'Xuất sắc';
    if (percentage >= 60) return 'Khá';
    if (percentage >= 50) return 'Trung bình';
    return 'Cần cải thiện';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  Future<void> _showSubmissionDetail(
    BuildContext context,
    String submissionId,
    Map<String, dynamic> submission,
  ) async {
    final quizId = submission['quizId'] as String?;
    if (quizId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppConstants.primary),
      ),
    );

    try {
      final questionsFuture = FirebaseFirestore.instance
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      final quizInfoFuture = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .get();

      final results = await Future.wait([questionsFuture, quizInfoFuture]);

      final questionsSnapshot = results[0] as QuerySnapshot;
      final quizDoc = results[1] as DocumentSnapshot;

      final bool allowViewDetail =
          (quizDoc.data() as Map<String, dynamic>?)?['allowViewDetail'] ?? false;

      if (!context.mounted) return;
      Navigator.pop(context);

      final studentAnswers =
          submission['answers'] as Map<String, dynamic>? ?? {};

      showDialog(
        context: context,
        builder: (context) => _DetailDialog(
          submission: submission,
          questions: questionsSnapshot.docs,
          studentAnswers: studentAnswers,
          allowViewDetail: allowViewDetail,
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải đề thi: $e'),
            backgroundColor: AppConstants.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

// ===================== Detail Dialog =====================
class _DetailDialog extends StatelessWidget {
  final Map<String, dynamic> submission;
  final List<QueryDocumentSnapshot> questions;
  final Map<String, dynamic> studentAnswers;
  final bool allowViewDetail;

  const _DetailDialog({
    required this.submission,
    required this.questions,
    required this.studentAnswers,
    required this.allowViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final score = submission['score'] ?? 0;
    final total = submission['totalQuestions'] ?? 1;
    final percentage = (score / total * 100);
    final timeSpent = submission['timeSpent'] ?? 0;
    final scoreColor = _getScoreColor(percentage);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppConstants.surface,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppConstants.surfaceContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppConstants.outlineVariant)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppConstants.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết bài làm',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.onSurface,
                          ),
                        ),
                        Text(
                          submission['quizTitle'] ?? 'N/A',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppConstants.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppConstants.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppConstants.outlineVariant)),
              ),
              child: Row(
                children: [
                  _buildStatChip(
                    icon: Icons.check_circle_outline,
                    value: score is double ? score.toStringAsFixed(1) : '$score',
                    label: 'Số câu đúng',
                    color: AppConstants.secondary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.cancel_outlined,
                    value: '${total - (score is double ? score.round() : score as int)}',
                    label: 'Sai',
                    color: AppConstants.error,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.schedule_outlined,
                    value: _formatTime(timeSpent),
                    label: 'Thời gian',
                    color: AppConstants.outline,
                  ),
                  const Spacer(),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: allowViewDetail ? _buildQuestionsList() : _buildHiddenMessage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_off_outlined,
                size: 48,
                color: AppConstants.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chi tiết chưa được công bố',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Giáo viên đã ẩn đáp án chi tiết của bài thi này. Liên hệ giáo viên để biết thêm thông tin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppConstants.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final questionDoc = questions[index];
        final questionData = questionDoc.data() as Map<String, dynamic>;
        final questionId = questionDoc.id;
        final rawCorrect = questionData['correctAnswer'];
        final rawStudent = studentAnswers[questionId];

        final bool isCorrect = _checkAnswerCorrect(rawCorrect, rawStudent);
        final borderColor = isCorrect ? AppConstants.secondary : AppConstants.error;
        final bgColor = isCorrect
            ? const Color(0xFFEDF7ED)
            : const Color(0xFFFFEDED);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Câu ${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: borderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        questionData['question'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppConstants.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: borderColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
              // Options
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: () {
                    final options = questionData['options'] as List? ?? [];
                    return List.generate(options.length, (i) {
                      final letter = String.fromCharCode(65 + i);
                      final bool isCorrectOption = _isCorrectOption(rawCorrect, letter);
                      final bool isStudentSelected = _isStudentSelected(rawStudent, letter);

                      Color optBg = AppConstants.surface;
                      Color optBorder = AppConstants.outlineVariant;
                      Color optText = AppConstants.onSurface;

                      if (isCorrectOption) {
                        optBg = const Color(0xFFEDF7ED);
                        optBorder = AppConstants.secondary;
                        optText = AppConstants.secondary;
                      } else if (isStudentSelected) {
                        optBg = const Color(0xFFFFEDED);
                        optBorder = AppConstants.error;
                        optText = AppConstants.error;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: optBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: optBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCorrectOption
                                    ? AppConstants.secondary
                                    : isStudentSelected
                                        ? AppConstants.error
                                        : AppConstants.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: (isCorrectOption || isStudentSelected)
                                        ? Colors.white
                                        : AppConstants.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                options[i].toString(),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: optText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    });
                  }(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return AppConstants.secondary;
    if (percentage >= 50) return const Color(0xFFB86200);
    return AppConstants.error;
  }

  bool _checkAnswerCorrect(dynamic correct, dynamic student) {
    if (student == null) return false;
    if (correct is List) {
      if (student is! List) return false;
      final correctSet = Set.from(correct.map((e) => e.toString()));
      final studentSet = Set.from(student.map((e) => e.toString()));
      return correctSet.length == studentSet.length &&
          correctSet.containsAll(studentSet);
    } else {
      return student.toString() == correct.toString();
    }
  }

  bool _isCorrectOption(dynamic correct, String letter) {
    if (correct is List) {
      return correct.map((e) => e.toString()).contains(letter);
    }
    return correct.toString() == letter;
  }

  bool _isStudentSelected(dynamic student, String letter) {
    if (student == null) return false;
    if (student is List) {
      return student.map((e) => e.toString()).contains(letter);
    }
    return student.toString() == letter;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
