// lib/screens/student/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class HistoryPage extends StatefulWidget {
  final String studentId;
  final String classId;
  final String? className;

  const HistoryPage({
    Key? key,
    required this.studentId,
    required this.classId,
    this.className,
  }) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Widget _buildClassBanner(BuildContext context) {
    final name = widget.className?.isNotEmpty == true ? widget.className! : 'Lớp học';
    final brandColor = AppConstants.brand(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school_rounded, color: brandColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppConstants.txt(context),
                ),
                children: [
                  TextSpan(
                    text: 'Bạn đang ở lớp học: ',
                    style: TextStyle(color: AppConstants.txtMuted(context)),
                  ),
                  TextSpan(
                    text: name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          width: double.infinity,
          color: AppConstants.surf(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassBanner(context),
              Text(
                'Lịch sử làm bài thi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Xem lại điểm số và chi tiết bài làm của bạn.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppConstants.txtMuted(context),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppConstants.border(context)),

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
                        Text(
                          'Không thể tải lịch sử bài làm',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.txtMuted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(context);
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
                  final score10 = total > 0 ? (score / total * 10) : 0.0;
                  final score10Text = score10.toStringAsFixed(score10 % 1 == 0 ? 0 : 1);
                  final scoreColor = _getScoreColor(percentage);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.surf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.border(context)),
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
                                  color: scoreColor.withValues(alpha: 0.12),
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
                                      '$score10Text đ',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: scoreColor.withValues(alpha: 0.85),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppConstants.txt(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 12,
                                          color: AppConstants.txtMuted(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(data['timestamp']),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppConstants.txtMuted(context),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 12,
                                          color: AppConstants.txtMuted(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDuration(data['timeSpent'] ?? 0),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppConstants.txtMuted(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Score badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: scoreColor.withValues(alpha: 0.12),
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
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppConstants.txtMuted(context),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppConstants.surfHigh(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_edu_outlined,
                size: 56,
                color: AppConstants.txtMuted(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có bài làm nào',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.txt(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hoàn thành bài thi đầu tiên của bạn để xem lịch sử.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppConstants.txtMuted(context),
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
    final double score10 = total > 0 ? (score / total * 10) : 0.0;
    final String score10Str =
        score10.toStringAsFixed(score10 % 1 == 0 ? 1 : 2);
    final int answeredCount = studentAnswers.length;
    final timeSpent = submission['timeSpent'] ?? 0;
    final scoreColor = _getScoreColor(percentage);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppConstants.surf(context),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surfLow(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppConstants.border(context))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppConstants.brand(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết bài làm',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        Text(
                          submission['quizTitle'] ?? 'N/A',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppConstants.txtMuted(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppConstants.border(context))),
              ),
              child: Row(
                children: [
                  _buildStatChip(
                    context: context,
                    icon: Icons.stars_rounded,
                    value: '$score10Str / 10',
                    label: 'Điểm số',
                    color: AppConstants.secondary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    context: context,
                    icon: Icons.task_alt_outlined,
                    value: '$answeredCount/$total',
                    label: 'Đã hoàn thành',
                    color: AppConstants.brand(context),
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    context: context,
                    icon: Icons.schedule_outlined,
                    value: _formatTime(timeSpent),
                    label: 'Thời gian',
                    color: AppConstants.txtMuted(context),
                  ),
                  const Spacer(),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
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
              child: allowViewDetail
                  ? Column(
                      children: [
                        _buildLegendBar(context),
                        Expanded(child: _buildQuestionsList(context)),
                      ],
                    )
                  : _buildHiddenMessage(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Chú thích:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppConstants.txtMuted(context),
            ),
          ),
          _buildLegendChip(
            color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
            bgColor: isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9),
            icon: Icons.check_circle,
            label: 'Bạn chọn đúng',
          ),
          _buildLegendChip(
            color: isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F),
            bgColor: isDark ? const Color(0xFF3E1B1B) : const Color(0xFFFFEDED),
            icon: Icons.cancel,
            label: 'Bạn chọn sai',
          ),
          _buildLegendChip(
            color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
            bgColor: isDark ? const Color(0xFF3E2D1B) : const Color(0xFFFFF8E1),
            icon: Icons.info,
            label: 'Đáp án đúng (chưa chọn)',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppConstants.txtMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_off_outlined,
                size: 48,
                color: AppConstants.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chi tiết chưa được công bố',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.txt(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Giáo viên đã ẩn đáp án chi tiết của bài thi này. Liên hệ giáo viên để biết thêm thông tin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppConstants.txtMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final questionDoc = questions[index];
        final questionData = questionDoc.data() as Map<String, dynamic>;
        final questionId = questionDoc.id;
        final rawCorrect = questionData['correctAnswer'];
        final rawStudent = studentAnswers[questionId];
        final isMultiple = rawCorrect is List;

        final double earnedScore = _calculateQuestionScore(rawCorrect, rawStudent);
        final bool isFullyCorrect = earnedScore >= 0.99;
        final bool isPartiallyCorrect = earnedScore > 0 && earnedScore < 0.99;

        final Color borderColor = isFullyCorrect
            ? AppConstants.secondary
            : (isPartiallyCorrect
                ? const Color(0xFFE65100)
                : AppConstants.error);
        final Color headerBgColor = isFullyCorrect
            ? (isDark ? const Color(0xFF132B1F) : const Color(0xFFEDF7ED))
            : (isPartiallyCorrect
                ? (isDark ? const Color(0xFF2E2312) : const Color(0xFFFFF8E1))
                : (isDark ? const Color(0xFF2E1515) : const Color(0xFFFFEDED)));
        final IconData statusIcon = isFullyCorrect
            ? Icons.check_circle_rounded
            : (isPartiallyCorrect
                ? Icons.warning_amber_rounded
                : Icons.cancel_rounded);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
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
                  color: headerBgColor,
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
                    if (isMultiple) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.surfHigh(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Nhiều đáp án',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppConstants.txtMuted(context),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        questionData['question'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppConstants.txt(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Điểm số nhận được cho câu này
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        earnedScore == 1.0
                            ? '+1.0 điểm'
                            : (earnedScore == 0.0
                                ? '+0.0 điểm'
                                : '+${earnedScore.toStringAsFixed(2)} điểm'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: borderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      statusIcon,
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
                    final rawOptions = questionData['options'];
                    final options = rawOptions is List ? rawOptions : [];
                    return List.generate(options.length, (i) {
                      final letter = String.fromCharCode(65 + i);
                      final bool isCorrectOption = _isCorrectOption(rawCorrect, letter);
                      final bool isStudentSelected = _isStudentSelected(rawStudent, letter);

                      Color optBg = isDark ? AppConstants.surfHigh(context) : AppConstants.surface;
                      Color optBorder = AppConstants.border(context);
                      Color optText = AppConstants.txt(context);
                      Color badgeColor = isDark ? AppConstants.surf(context) : AppConstants.surfaceContainerHigh;
                      Color badgeTextColor = AppConstants.txtMuted(context);
                      Widget? statusBadge;

                      if (isStudentSelected && isCorrectOption) {
                        // 1. Sinh viên chọn ĐÚNG: Xanh lá
                        optBg = isDark ? const Color(0xFF163322) : const Color(0xFFEDF7ED);
                        optBorder = isDark ? const Color(0xFF388E3C) : const Color(0xFF2E7D32);
                        optText = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20);
                        badgeColor = const Color(0xFF2E7D32);
                        badgeTextColor = Colors.white;
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E7D32).withValues(alpha: 0.35) : const Color(0xFFC8E6C9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 13, color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20)),
                              const SizedBox(width: 4),
                              Text(
                                'Bạn đã chọn (Đúng)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (isStudentSelected && !isCorrectOption) {
                        // 2. Sinh viên chọn SAI: Đỏ
                        optBg = isDark ? const Color(0xFF351717) : const Color(0xFFFFEDED);
                        optBorder = isDark ? const Color(0xFFE53935) : const Color(0xFFD32F2F);
                        optText = isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
                        badgeColor = const Color(0xFFD32F2F);
                        badgeTextColor = Colors.white;
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFD32F2F).withValues(alpha: 0.35) : const Color(0xFFFFCDD2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 13, color: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828)),
                              const SizedBox(width: 4),
                              Text(
                                'Bạn đã chọn (Sai)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (!isStudentSelected && isCorrectOption) {
                        // 3. Đáp án ĐÚNG mà sinh viên CHƯA CHỌN / BỎ SÓT: Vàng/Cam
                        optBg = isDark ? const Color(0xFF332712) : const Color(0xFFFFF8E1);
                        optBorder = isDark ? const Color(0xFFFB8C00) : const Color(0xFFFFA000);
                        optText = isDark ? const Color(0xFFFFE082) : const Color(0xFFB78103);
                        badgeColor = const Color(0xFFFFA000);
                        badgeTextColor = Colors.white;
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFFFA000).withValues(alpha: 0.35) : const Color(0xFFFFECB3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 13, color: isDark ? const Color(0xFFFFE082) : const Color(0xFF8F6B00)),
                              const SizedBox(width: 4),
                              Text(
                                'Đáp án đúng (Chưa chọn)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFFE082) : const Color(0xFF8F6B00),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: optBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: optBorder,
                            width: statusBadge != null ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                                borderRadius: isMultiple ? BorderRadius.circular(4) : null,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: badgeTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[i]?.toString() ?? '',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: optText,
                                  fontWeight: statusBadge != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (statusBadge != null) ...[
                              const SizedBox(width: 8),
                              statusBadge,
                            ],
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

  double _calculateQuestionScore(dynamic rawCorrect, dynamic rawStudent) {
    if (rawStudent == null) return 0.0;
    if (rawCorrect is List) {
      final correctList = List<String>.from(rawCorrect.map((e) => e.toString()));
      final studentList = rawStudent is List
          ? List<String>.from(rawStudent.map((e) => e.toString()))
          : [rawStudent.toString()];
      if (correctList.isEmpty) return 0.0;
      double unitScore = 1.0 / correctList.length;
      double penaltyScore = 2.0 * unitScore;
      double score = 0.0;
      for (var ans in studentList) {
        if (correctList.contains(ans)) {
          score += unitScore;
        } else {
          score -= penaltyScore;
        }
      }
      return score < 0 ? 0.0 : score;
    } else {
      return (rawStudent.toString() == rawCorrect.toString()) ? 1.0 : 0.0;
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
