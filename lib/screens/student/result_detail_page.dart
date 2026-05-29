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
      backgroundColor: AppConstants.background,
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
                    return const Center(
                      child: CircularProgressIndicator(color: AppConstants.primary),
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
                        return const Center(
                          child: CircularProgressIndicator(color: AppConstants.primary),
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
                                      context, 'Question Breakdown'),
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
      decoration: const BoxDecoration(
        color: AppConstants.surface,
        border: Border(bottom: BorderSide(color: AppConstants.outlineVariant)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded,
                  color: AppConstants.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Exam Results',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.primary,
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
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.outlineVariant),
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
                    backgroundColor: AppConstants.surfaceContainerHigh,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppConstants.primary),
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
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primary,
                            height: 1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.onSurfaceVariant,
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
                    ? 'Excellent Work!'
                    : pct >= 60
                        ? 'Good Job!'
                        : 'Keep Practicing!',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.onSurface,
                ),
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ),
              const SizedBox(height: 6),
              Text(
                'You have completed $quizTitle.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppConstants.onSurfaceVariant,
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
                    icon: Icons.check_circle_outline,
                    iconColor: AppConstants.secondary,
                    value: '$correctCount',
                    label: 'Correct',
                  ),
                  _buildStatChip(
                    icon: Icons.cancel_outlined,
                    iconColor: AppConstants.error,
                    value: '${totalCount - correctCount}',
                    label: 'Incorrect',
                  ),
                  _buildStatChip(
                    icon: Icons.schedule_outlined,
                    iconColor: AppConstants.outline,
                    value: _formatTime(data['timeSpent'] ?? 0),
                    label: 'Time',
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
                backgroundColor: AppConstants.primary,
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

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.outlineVariant),
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
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.onSurface,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppConstants.onSurfaceVariant,
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
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppConstants.outlineVariant),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppConstants.onSurface,
        ),
      ),
    );
  }

  Widget _buildHiddenDetailMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.errorContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility_off_outlined,
              size: 44,
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
            'Giáo viên tạm thời ẩn đáp án chi tiết của bài thi này.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppConstants.onSurfaceVariant,
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
              decoration: const BoxDecoration(
                color: AppConstants.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: AppConstants.error),
            ),
            const SizedBox(height: 16),
            const Text('Không thể tải kết quả',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.onSurface)),
            const SizedBox(height: 8),
            Text('$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.onSurfaceVariant)),
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
    final data = questionDoc.data() as Map<String, dynamic>;
    final options = List<String>.from(data['options'] ?? []);
    final List<String> correctList = _normalizeToList(data['correctAnswer']);
    final List<String> userList = _normalizeToList(userAnswer);
    final isMultiple = data['correctAnswer'] is List;

    final Color statusColor = earnedScore >= 0.99
        ? AppConstants.secondary
        : (earnedScore > 0
            ? const Color(0xFFB86200)
            : AppConstants.error);
    final Color statusBg = earnedScore >= 0.99
        ? const Color(0xFFEDF7ED)
        : (earnedScore > 0
            ? const Color(0xFFFFF3E0)
            : AppConstants.errorContainer);
    final IconData statusIcon = earnedScore >= 0.99
        ? Icons.check_circle_outline
        : (earnedScore > 0
            ? Icons.warning_amber_outlined
            : Icons.cancel_outlined);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
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
              Text(
                '${_formatScore(earnedScore)} pts',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['question'] ?? '',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppConstants.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...options.asMap().entries.map((optEntry) {
            final letter = String.fromCharCode(65 + optEntry.key);
            final text = optEntry.value;
            final bool isCorrectOption = correctList.contains(letter);
            final bool isUserSelected = userList.contains(letter);

            Color optBg = AppConstants.surface;
            Color optBorder = AppConstants.outlineVariant;
            Color optText = AppConstants.onSurface;
            IconData? optIcon;

            if (isCorrectOption) {
              optBg = const Color(0xFFEDF7ED);
              optBorder = AppConstants.secondary;
              optText = AppConstants.secondary;
              optIcon = Icons.check_circle_outline;
            }
            if (isUserSelected && !isCorrectOption) {
              optBg = const Color(0xFFFFEDED);
              optBorder = AppConstants.error;
              optText = AppConstants.error;
              optIcon = Icons.cancel_outlined;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: optBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: optBorder,
                    width: (isCorrectOption || isUserSelected) ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCorrectOption
                          ? AppConstants.secondary
                          : isUserSelected
                              ? AppConstants.error
                              : AppConstants.surfaceContainerHigh,
                      shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isMultiple ? BorderRadius.circular(6) : null,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: (isCorrectOption || isUserSelected)
                              ? Colors.white
                              : AppConstants.onSurfaceVariant,
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
                        fontWeight: (isCorrectOption || isUserSelected)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (optIcon != null)
                    Icon(optIcon, color: optBorder, size: 18),
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
