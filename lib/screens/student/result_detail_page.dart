// lib/screens/student/result_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';

class ResultDetailPage extends StatelessWidget {
  final String submissionId;

  const ResultDetailPage({Key? key, required this.submissionId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseService.getSubmissionById(submissionId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(context, snapshot.error);
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: AppConstants.brand(context)),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final answers = Map<String, dynamic>.from(data['answers'] ?? {});
                  final quizId = data['quizId'] ?? '';
                  final classId = data['classId'] ?? '';

                  return FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      FirebaseService.getQuizQuestionsOnce(quizId),
                      FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .collection('quizzes')
                          .doc(quizId)
                          .get(),
                    ]),
                    builder: (context, compositeSnapshot) {
                      if (!compositeSnapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(color: AppConstants.brand(context)),
                        );
                      }

                      final questionSnapshot =
                          compositeSnapshot.data![0] as QuerySnapshot;
                      final quizDocSnapshot =
                          compositeSnapshot.data![1] as DocumentSnapshot;

                      final quizData =
                          quizDocSnapshot.data() as Map<String, dynamic>?;
                      final bool allowViewDetail =
                          quizData?['allowViewDetail'] ?? false;
                      final String quizTitle =
                          quizData?['title'] ?? 'Exam Results';

                      final questions = questionSnapshot.docs;

                      double calculatedTotalScore = 0.0;
                      int correctQuestionsCount = 0;
                      Map<String, double> questionScores = {};

                      for (var doc in questions) {
                        final qData = doc.data() as Map<String, dynamic>;
                        final rawCorrect = qData['correctAnswer'];
                        final rawUser = answers[doc.id];
                        double points =
                            _calculateQuestionScore(rawCorrect, rawUser);
                        questionScores[doc.id] = points;
                        calculatedTotalScore += points;
                        if (points >= 0.99) correctQuestionsCount++;
                      }

                      double maxScore = questions.length.toDouble();
                      String percentage = maxScore > 0
                          ? ((calculatedTotalScore / maxScore) * 100)
                              .toStringAsFixed(0)
                          : '0';
                      String scorePoints = maxScore > 0
                          ? ((calculatedTotalScore / maxScore) * 100)
                              .toStringAsFixed(2)
                              .replaceAll(RegExp(r'\.?0+$'), '')
                          : '0';

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hero Score Section
                                _buildScoreCard(
                                  context,
                                  data: data,
                                  correctCount: correctQuestionsCount,
                                  totalCount: questions.length,
                                  scorePoints: scorePoints,
                                  percentage: percentage,
                                  quizTitle: quizTitle,
                                ),
                                const SizedBox(height: 32),

                                // Question Breakdown section
                                if (allowViewDetail) ...[
                                  _buildSectionHeader(
                                      context, 'Chi tiết từng câu hỏi'),
                                  const SizedBox(height: 20),
                                  ...questions.asMap().entries.map((entry) {
                                    return _buildQuestionDetail(
                                      context,
                                      entry.key,
                                      entry.value,
                                      answers[entry.value.id],
                                      questionScores[entry.value.id] ?? 0.0,
                                    );
                                  }),
                                ] else ...[
                                  _buildHiddenDetailMessage(context),
                                ],
                                const SizedBox(height: 32),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded,
                  color: AppConstants.txtMuted(context)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Kết quả bài thi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.brand(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context, {
    required Map<String, dynamic> data,
    required int correctCount,
    required int totalCount,
    required String scorePoints,
    required String percentage,
    required String quizTitle,
  }) {
    final pct = double.tryParse(percentage) ?? 0;
    final scoreColor = pct >= 80
        ? AppConstants.secondary
        : pct >= 50
            ? const Color(0xFFB86200)
            : AppConstants.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 580;

          final scoreCircle = SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 10,
                    backgroundColor: AppConstants.surfHigh(context),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          percentage,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.brand(context),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.brand(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SCORE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.txtMuted(context),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final textSection = Column(
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                pct >= 80
                    ? 'Xuất sắc!'
                    : pct >= 60
                        ? 'Khá tốt!'
                        : 'Cần cố gắng thêm!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                ),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn đã hoàn thành bài thi $quizTitle.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppConstants.txtMuted(context),
                ),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment:
                    isMobile ? WrapAlignment.center : WrapAlignment.start,
                children: [
                  _buildStatChip(
                    context,
                    icon: Icons.check_circle_outline,
                    iconColor: AppConstants.secondary,
                    value: '$correctCount',
                    label: 'Đúng',
                  ),
                  _buildStatChip(
                    context,
                    icon: Icons.cancel_outlined,
                    iconColor: AppConstants.error,
                    value: '${totalCount - correctCount}',
                    label: 'Sai / Chưa làm',
                  ),
                  _buildStatChip(
                    context,
                    icon: Icons.schedule_outlined,
                    iconColor: AppConstants.txtMuted(context),
                    value: _formatTime(data['timeSpent'] ?? 0),
                    label: 'Thời gian',
                  ),
                ],
              ),
            ],
          );

          final actionSection = SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.brand(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                scoreCircle,
                const SizedBox(height: 24),
                textSection,
                const SizedBox(height: 24),
                actionSection,
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                scoreCircle,
                const SizedBox(width: 32),
                Expanded(child: textSection),
                const SizedBox(width: 24),
                actionSection,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.surfHigh(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppConstants.txtMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppConstants.border(context)),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppConstants.txt(context),
        ),
      ),
    );
  }

  Widget _buildHiddenDetailMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_off_outlined,
              size: 44,
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
            'Giáo viên tạm thời ẩn đáp án chi tiết của bài thi này.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppConstants.txtMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 40, color: AppConstants.error),
            ),
            const SizedBox(height: 16),
            Text('Không thể tải kết quả',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.txt(context))),
            const SizedBox(height: 8),
            Text('$error',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.txtMuted(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDetail(
    BuildContext context,
    int index,
    DocumentSnapshot questionDoc,
    dynamic userAnswer,
    double earnedScore,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = questionDoc.data() as Map<String, dynamic>;
    final options = List<String>.from(data['options'] ?? []);
    final List<String> correctList = _normalizeToList(data['correctAnswer']);
    final List<String> userList = _normalizeToList(userAnswer);
    final isMultiple = data['correctAnswer'] is List;

    final Color statusColor = earnedScore >= 0.99
        ? (isDark ? const Color(0xFF81C784) : AppConstants.secondary)
        : (earnedScore > 0
            ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFB86200))
            : (isDark ? const Color(0xFFE57373) : AppConstants.error));
    final Color statusBg = earnedScore >= 0.99
        ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFEDF7ED))
        : (earnedScore > 0
            ? (isDark ? const Color(0xFF3E2D1B) : const Color(0xFFFFF3E0))
            : (isDark ? const Color(0xFF3E1B1B) : AppConstants.errorContainer));
    final IconData statusIcon = earnedScore >= 0.99
        ? Icons.check_circle_outline
        : (earnedScore > 0
            ? Icons.warning_amber_outlined
            : Icons.cancel_outlined);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Câu ${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '+${_formatScore(earnedScore)} điểm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['question'] ?? '',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppConstants.txt(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...options.asMap().entries.map((optEntry) {
            final letter = String.fromCharCode(65 + optEntry.key);
            final text = optEntry.value;
            final bool isCorrectOption = correctList.contains(letter);
            final bool isUserSelected = userList.contains(letter);

            Color optBg = isDark ? AppConstants.surfHigh(context) : AppConstants.surface;
            Color optBorder = AppConstants.border(context);
            Color optText = AppConstants.txt(context);
            Color badgeColor = isDark ? AppConstants.surf(context) : AppConstants.surfaceContainerHigh;
            Color badgeTextColor = AppConstants.txtMuted(context);
            Widget? statusBadge;

            if (isUserSelected && isCorrectOption) {
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
            } else if (isUserSelected && !isCorrectOption) {
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
            } else if (!isUserSelected && isCorrectOption) {
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: optBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: optBorder,
                  width: statusBadge != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isMultiple ? BorderRadius.circular(6) : null,
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
                      text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: optText,
                        fontWeight: statusBadge != null
                            ? FontWeight.w600
                            : FontWeight.normal,
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
          }),
        ],
      ),
    );
  }

  // ===================== Logic =====================

  double _calculateQuestionScore(dynamic rawCorrect, dynamic rawUser) {
    if (rawUser == null) return 0.0;
    List<String> correctList = _normalizeToList(rawCorrect);
    List<String> userList = _normalizeToList(rawUser);
    if (correctList.isEmpty) return 0.0;
    if (correctList.length > 1 || rawCorrect is List) {
      double unitScore = 1.0 / correctList.length;
      double penaltyScore = 2.0 * unitScore;
      double currentScore = 0.0;
      for (var ans in userList) {
        if (correctList.contains(ans))
          currentScore += unitScore;
        else
          currentScore -= penaltyScore;
      }
      return currentScore.clamp(0.0, 1.0);
    } else {
      return (userList.isNotEmpty && correctList.contains(userList.first))
          ? 1.0
          : 0.0;
    }
  }

  List<String> _normalizeToList(dynamic input) {
    if (input == null) return [];
    if (input is List) return input.map((e) => e.toString().trim()).toList();
    return [input.toString().trim()];
  }

  String _formatScore(double score) =>
      score.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
