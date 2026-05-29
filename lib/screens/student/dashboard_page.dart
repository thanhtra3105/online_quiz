// lib/screens/student/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class DashboardPage extends StatelessWidget {
  final String studentId;
  final String classId;

  const DashboardPage({
    Key? key,
    required this.studentId,
    required this.classId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = _getFirstName(user);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getClassQuizzes(classId),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.hasError) return _buildErrorWidget(quizSnapshot.error);
        if (!quizSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppConstants.primary));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getStudentClassSubmissions(studentId, classId),
          builder: (context, submissionSnapshot) {
            if (!submissionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppConstants.primary));
            }

            final completedQuizIds = submissionSnapshot.data!.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['quizId'] as String)
                .toSet();

            final availableQuizDocs = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .toList();

            final totalCompleted = submissionSnapshot.data!.docs.length;

            // Calculate average score
            double totalScore = 0;
            num totalMax = 0;
            for (var doc in submissionSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalScore += (data['score'] ?? 0);
              totalMax += (data['totalQuestions'] ?? 1);
            }
            final avgScore = totalMax > 0
                ? ((totalScore / totalMax) * 100).toStringAsFixed(1)
                : '0';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Header
                      _buildWelcomeHeader(context, firstName),
                      const SizedBox(height: 32),

                      // Bento Grid Stats
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 700) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildStatCard(
                                  context: context,
                                  title: 'TOTAL EXAMS TAKEN',
                                  value: totalCompleted.toString(),
                                  icon: Icons.assignment_turned_in_outlined,
                                  iconBgColor: AppConstants.primary.withValues(alpha: 0.1),
                                  iconColor: AppConstants.primary,
                                )),
                                const SizedBox(width: 20),
                                Expanded(child: _buildStatCard(
                                  context: context,
                                  title: 'AVERAGE SCORE',
                                  value: '$avgScore%',
                                  icon: Icons.analytics_outlined,
                                  iconBgColor: AppConstants.secondary.withValues(alpha: 0.1),
                                  iconColor: AppConstants.secondary,
                                  valueTrailing: '',
                                  rawValue: avgScore,
                                  showPercent: true,
                                )),
                                const SizedBox(width: 20),
                                Expanded(child: _buildWeeklyGoalCard(context)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildStatCard(
                                  context: context,
                                  title: 'TOTAL EXAMS TAKEN',
                                  value: totalCompleted.toString(),
                                  icon: Icons.assignment_turned_in_outlined,
                                  iconBgColor: AppConstants.primary.withValues(alpha: 0.1),
                                  iconColor: AppConstants.primary,
                                ),
                                const SizedBox(height: 16),
                                _buildStatCard(
                                  context: context,
                                  title: 'AVERAGE SCORE',
                                  value: '$avgScore%',
                                  icon: Icons.analytics_outlined,
                                  iconBgColor: AppConstants.secondary.withValues(alpha: 0.1),
                                  iconColor: AppConstants.secondary,
                                  rawValue: avgScore,
                                  showPercent: true,
                                ),
                                const SizedBox(height: 16),
                                _buildWeeklyGoalCard(context),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Two-column section
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildUpcomingExamsSection(context, availableQuizDocs),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 1,
                                  child: _buildRecentActivitySection(context),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildUpcomingExamsSection(context, availableQuizDocs),
                                const SizedBox(height: 32),
                                _buildRecentActivitySection(context),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== Welcome ====================

  Widget _buildWelcomeHeader(BuildContext context, String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $firstName!',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppConstants.onSurface,
            letterSpacing: -0.01 * 28,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's an overview of your academic progress today.",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ==================== Stat Cards ====================

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    String? valueTrailing,
    String? rawValue,
    bool showPercent = false,
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.onSurfaceVariant,
                    letterSpacing: 0.04 * 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
          if (showPercent && rawValue != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rawValue,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.onSurface,
                    letterSpacing: -0.02 * 36,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      color: AppConstants.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppConstants.onSurface,
                letterSpacing: -0.02 * 36,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalCard(BuildContext context) {
    return Container(
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppConstants.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WEEKLY GOAL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.track_changes, color: AppConstants.primary, size: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weekly Progress',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppConstants.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '75%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.75,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppConstants.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Upcoming Exams ====================

  Widget _buildUpcomingExamsSection(BuildContext context, List<QueryDocumentSnapshot> quizDocs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Exams',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppConstants.outlineVariant, height: 1),
        const SizedBox(height: 16),
        if (quizDocs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.outlineVariant),
            ),
            child: const Center(
              child: Text(
                'Bạn đã hoàn thành tất cả bài thi hiện có. 🎉',
                style: TextStyle(color: AppConstants.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 2 : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: quizDocs.take(4).map((quiz) {
                  final data = quiz.data() as Map<String, dynamic>;
                  return SizedBox(
                    width: cols == 2
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth,
                    child: _buildUpcomingExamCard(context, data),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildUpcomingExamCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppConstants.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'QUIZ / EXAM',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.science_outlined, color: AppConstants.onSurfaceVariant, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['title'] ?? 'Bài thi',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 14, color: AppConstants.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Available now',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppConstants.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== Recent Activity ====================

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Recent Activity',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.onSurface,
            ),
          ),
        ),
        const Divider(color: AppConstants.outlineVariant, height: 1),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppConstants.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildRecentActivityList(),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getRecentClassSubmissions(studentId, classId, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: AppConstants.primary)),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history_outlined, size: 40, color: AppConstants.outlineVariant),
                SizedBox(height: 12),
                Text('Chưa có hoạt động', style: TextStyle(color: AppConstants.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppConstants.outlineVariant),
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final score = data['score'] ?? 0;
            final total = data['totalQuestions'] ?? 1;
            final percentage = ((score / total) * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppConstants.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppConstants.onSurface,
                            ),
                            children: [
                              const TextSpan(text: 'Completed '),
                              TextSpan(
                                text: data['quizTitle'] ?? 'Bài thi',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Score: $percentage%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${Helpers.formatDate(data['timestamp'])}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppConstants.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== Helpers ====================

  String _getFirstName(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      return parts.last; // Vietnamese names: last part is first name
    }
    return 'Student';
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: AppConstants.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}