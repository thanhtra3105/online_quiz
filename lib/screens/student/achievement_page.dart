// lib/screens/student/achievement_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class AchievementPage extends StatefulWidget {
  final String studentId;
  final bool showTopBar;

  const AchievementPage({
    super.key,
    required this.studentId,
    this.showTopBar = true,
  });

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _fetchUserNames();
  }

  void _fetchUserNames() {
    FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {
      if (!mounted) return;
      final map = <String, String>{};
      for (var doc in snap.docs) {
        final d = doc.data();
        final name = d['displayName'] ?? d['name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          map[doc.id] = name.toString().trim();
          final uId = d['userId']?.toString();
          if (uId != null && uId.isNotEmpty) {
            map[uId] = name.toString().trim();
          }
        }
      }
      setState(() {
        _userNames = map;
      });
    });
  }

  String _getStudentDisplayName(String sId) {
    if (sId == widget.studentId) {
      final currentAuthName = FirebaseAuth.instance.currentUser?.displayName;
      if (currentAuthName != null && currentAuthName.trim().isNotEmpty) {
        return '$currentAuthName (Bạn)';
      }
      if (_userNames.containsKey(sId)) {
        return '${_userNames[sId]} (Bạn)';
      }
      return 'Bạn ($sId)';
    }

    if (_userNames.containsKey(sId)) {
      return _userNames[sId]!;
    }
    return 'Sinh viên $sId';
  }

  String _getInitials(String name) {
    final clean = name.replaceAll('(Bạn)', '').trim();
    if (clean.isEmpty) return 'SV';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean.toUpperCase();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(ts.toDate());
    }
    return '';
  }

  String _getLevelTitle(int level) {
    if (level <= 1) return 'Tân binh học tập';
    if (level <= 3) return 'Người tập sự';
    if (level <= 6) return 'Học giả triển vọng';
    if (level <= 9) return 'Học giả tinh anh';
    return 'Bậc thầy tri thức';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Column(
        children: [
          if (widget.showTopBar) _buildTopBar(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('submissions').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppConstants.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Lỗi khi tải dữ liệu thành tích: ${snapshot.error}',
                        style: TextStyle(color: AppConstants.error),
                      ),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final List<Map<String, dynamic>> allSubmissions = [];
                for (var doc in allDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  allSubmissions.add(data);
                }

                // 1. Phân loại bài làm của sinh viên hiện tại
                final mySubmissions = allSubmissions
                    .where((s) => s['studentId'] == widget.studentId)
                    .toList();

                // Sắp xếp theo thời gian tăng dần để xác định ngày mở khóa huy hiệu
                mySubmissions.sort((a, b) {
                  final tA = a['timestamp'] is Timestamp
                      ? (a['timestamp'] as Timestamp).toDate()
                      : DateTime(2000);
                  final tB = b['timestamp'] is Timestamp
                      ? (b['timestamp'] as Timestamp).toDate()
                      : DateTime(2000);
                  return tA.compareTo(tB);
                });

                final totalCompleted = mySubmissions.length;

                // Các bài đạt điểm tuyệt đối 10/10
                final perfectSubmissions = mySubmissions.where((s) {
                  final score = (s['score'] ?? 0).toDouble();
                  final total = (s['totalQuestions'] ?? 1).toDouble();
                  if (total <= 0) return false;
                  final score10 = (score / total) * 10;
                  return score10 >= 9.99;
                }).toList();
                final perfectCount = perfectSubmissions.length;

                // Các bài đạt điểm >= 8.0
                final score8PlusSubmissions = mySubmissions.where((s) {
                  final score = (s['score'] ?? 0).toDouble();
                  final total = (s['totalQuestions'] ?? 1).toDouble();
                  if (total <= 0) return false;
                  final score10 = (score / total) * 10;
                  return score10 >= 8.0;
                }).toList();
                final score8PlusCount = score8PlusSubmissions.length;

                // Các bài làm nhanh <= 5 phút (300s) với điểm >= 8.0
                final speedSubmissions = mySubmissions.where((s) {
                  final score = (s['score'] ?? 0).toDouble();
                  final total = (s['totalQuestions'] ?? 1).toDouble();
                  final timeSpent = s['timeSpent'] is num
                      ? (s['timeSpent'] as num).toInt()
                      : 99999;
                  if (total <= 0) return false;
                  final score10 = (score / total) * 10;
                  return score10 >= 8.0 && timeSpent > 0 && timeSpent <= 300;
                }).toList();
                final speedCount = speedSubmissions.length;

                // Tổng điểm của sinh viên hiện tại
                double myTotalScore = 0.0;
                for (var s in mySubmissions) {
                  final score = (s['score'] ?? 0).toDouble();
                  final total = (s['totalQuestions'] ?? 1).toDouble();
                  if (total > 0) {
                    myTotalScore += (score / total) * 10;
                  }
                }

                final myXP = (myTotalScore * 100).round();
                final myLevel = (myXP ~/ 1000) + 1;
                final xpInCurrentLevel = myXP % 1000;
                final xpToNextLevel = 1000 - xpInCurrentLevel;
                final levelProgress = (xpInCurrentLevel / 1000.0).clamp(0.0, 1.0);

                // 2. Tính bảng xếp hạng theo tổng điểm tất cả các bài thi
                final Map<String, double> studentTotalScoreMap = {};
                final Map<String, int> studentQuizCountMap = {};

                for (var sub in allSubmissions) {
                  final sId = (sub['studentId'] ?? '').toString().trim();
                  if (sId.isEmpty) continue;
                  final score = (sub['score'] ?? 0).toDouble();
                  final total = (sub['totalQuestions'] ?? 1).toDouble();
                  final score10 = total > 0 ? (score / total) * 10 : 0.0;
                  studentTotalScoreMap[sId] =
                      (studentTotalScoreMap[sId] ?? 0.0) + score10;
                  studentQuizCountMap[sId] =
                      (studentQuizCountMap[sId] ?? 0) + 1;
                }

                // Đảm bảo sinh viên hiện tại có trong map
                if (!studentTotalScoreMap.containsKey(widget.studentId)) {
                  studentTotalScoreMap[widget.studentId] = 0.0;
                  studentQuizCountMap[widget.studentId] = 0;
                }

                // Sắp xếp giảm dần theo tổng điểm
                final sortedStudents = studentTotalScoreMap.entries.toList()
                  ..sort((a, b) {
                    final cmp = b.value.compareTo(a.value);
                    if (cmp != 0) return cmp;
                    return (studentQuizCountMap[b.key] ?? 0)
                        .compareTo(studentQuizCountMap[a.key] ?? 0);
                  });

                // Xác định thứ hạng của sinh viên hiện tại
                int myRank = 1;
                for (int i = 0; i < sortedStudents.length; i++) {
                  if (sortedStudents[i].key == widget.studentId) {
                    myRank = i + 1;
                    break;
                  }
                }

                // 3. Danh sách huy hiệu theo dữ liệu thực tế
                final badges = [
                  {
                    'icon': Icons.menu_book_rounded,
                    'iconColor': AppConstants.primary,
                    'iconBg': AppConstants.surfaceContainerHigh,
                    'title': 'Học giả chăm chỉ',
                    'desc': 'Hoàn thành đủ 10 bài kiểm tra trên hệ thống.',
                    'progressText': totalCompleted >= 10
                        ? 'Đã hoàn thành $totalCompleted/10 bài thi'
                        : 'Đang tiến hành ($totalCompleted/10 bài thi)',
                    'progress': (totalCompleted / 10.0).clamp(0.0, 1.0),
                    'date': totalCompleted >= 10
                        ? _formatTimestamp(mySubmissions[9]['timestamp'])
                        : null,
                    'locked': totalCompleted < 10,
                  },
                  {
                    'icon': Icons.verified_rounded,
                    'iconColor': const Color(0xFFD97706),
                    'iconBg': const Color(0xFFFEF3C7),
                    'title': 'Hoàn hảo 10/10',
                    'desc': 'Đạt điểm số tuyệt đối 10/10 trong bài kiểm tra.',
                    'progressText': perfectCount > 0
                        ? 'Đã đạt $perfectCount lần điểm 10'
                        : 'Chưa có bài nào đạt 10/10',
                    'progress': perfectCount > 0 ? 1.0 : 0.0,
                    'date': perfectCount > 0
                        ? _formatTimestamp(perfectSubmissions.first['timestamp'])
                        : null,
                    'locked': perfectCount == 0,
                  },
                  {
                    'icon': Icons.flag_rounded,
                    'iconColor': AppConstants.secondary,
                    'iconBg': const Color(0xFFD1FAE5),
                    'title': 'Khởi đầu vững chắc',
                    'desc': 'Hoàn thành bài thi đầu tiên trên hệ thống.',
                    'progressText': totalCompleted >= 1
                        ? 'Đã hoàn thành bài đầu tiên'
                        : 'Chưa nộp bài thi nào',
                    'progress': totalCompleted >= 1 ? 1.0 : 0.0,
                    'date': totalCompleted >= 1
                        ? _formatTimestamp(mySubmissions.first['timestamp'])
                        : null,
                    'locked': totalCompleted < 1,
                  },
                  {
                    'icon': Icons.workspace_premium_rounded,
                    'iconColor': const Color(0xFF9333EA),
                    'iconBg': const Color(0xFFF3E8FF),
                    'title': 'Cao thủ điểm 8+',
                    'desc': 'Đạt từ 8.0 điểm trở lên trong ít nhất 3 bài thi.',
                    'progressText': score8PlusCount >= 3
                        ? 'Đã đạt $score8PlusCount bài điểm 8+'
                        : 'Đang tiến hành ($score8PlusCount/3 bài)',
                    'progress': (score8PlusCount / 3.0).clamp(0.0, 1.0),
                    'date': score8PlusCount >= 3
                        ? _formatTimestamp(score8PlusSubmissions[2]['timestamp'])
                        : null,
                    'locked': score8PlusCount < 3,
                  },
                  {
                    'icon': Icons.shield_rounded,
                    'iconColor': const Color(0xFF0284C7),
                    'iconBg': const Color(0xFFE0F2FE),
                    'title': 'Chiến binh bền bỉ',
                    'desc': 'Hoàn thành từ 5 bài kiểm tra trở lên.',
                    'progressText': totalCompleted >= 5
                        ? 'Đã hoàn thành $totalCompleted/5 bài'
                        : 'Đang tiến hành ($totalCompleted/5 bài)',
                    'progress': (totalCompleted / 5.0).clamp(0.0, 1.0),
                    'date': totalCompleted >= 5
                        ? _formatTimestamp(mySubmissions[4]['timestamp'])
                        : null,
                    'locked': totalCompleted < 5,
                  },
                  {
                    'icon': Icons.bolt_rounded,
                    'iconColor': const Color(0xFFEF4444),
                    'iconBg': const Color(0xFFFEE2E2),
                    'title': 'Vua tốc độ',
                    'desc': 'Nộp bài dưới 5 phút với điểm số đạt từ 8.0 trở lên.',
                    'progressText': speedCount > 0
                        ? 'Đã đạt $speedCount lần thần tốc'
                        : 'Chưa đạt (< 5 phút, điểm >= 8.0)',
                    'progress': speedCount > 0 ? 1.0 : 0.0,
                    'date': speedCount > 0
                        ? _formatTimestamp(speedSubmissions.first['timestamp'])
                        : null,
                    'locked': speedCount == 0,
                  },
                ];

                final unlockedCount = badges.where((b) => b['locked'] == false).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page Header
                          Text(
                            'Thành tích cá nhân',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.txt(context),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Theo dõi sự tiến bộ, điểm tích lũy và bảng xếp hạng thi đua.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: AppConstants.txtMuted(context),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Stats Bento
                          _buildStatsBento(
                            unlockedBadges: unlockedCount,
                            totalBadges: badges.length,
                            rank: myRank,
                            level: myLevel,
                            levelTitle: _getLevelTitle(myLevel),
                            xpInCurrentLevel: xpInCurrentLevel,
                            xpToNextLevel: xpToNextLevel,
                            levelProgress: levelProgress,
                          ),
                          const SizedBox(height: 32),

                          // Badges Section
                          _buildSectionTitle(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Huy hiệu học tập ($unlockedCount/${badges.length})',
                          ),
                          const SizedBox(height: 16),
                          _buildBadgesGrid(badges),
                          const SizedBox(height: 36),

                          // Leaderboard
                          _buildSectionTitle(
                            icon: Icons.leaderboard_outlined,
                            title: 'Bảng xếp hạng tổng điểm thi',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Xếp hạng dựa trên tổng điểm thang 10 của các bài thi đã nộp. Top 10 sinh viên xuất sắc nhất.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppConstants.txtMuted(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLeaderboard(
                            sortedStudents: sortedStudents,
                            quizCounts: studentQuizCountMap,
                            myRank: myRank,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
          Icon(Icons.emoji_events_rounded,
              color: AppConstants.brand(context), size: 24),
          const SizedBox(width: 8),
          Text(
            'Thành tích',
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

  Widget _buildStatsBento({
    required int unlockedBadges,
    required int totalBadges,
    required int rank,
    required int level,
    required String levelTitle,
    required int xpInCurrentLevel,
    required int xpToNextLevel,
    required double levelProgress,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 560;
        if (!isWide) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.military_tech_rounded,
                      iconBg: isDark ? AppConstants.surfHigh(context) : AppConstants.surfaceContainerHigh,
                      iconColor: AppConstants.brand(context),
                      value: '$unlockedBadges/$totalBadges',
                      label: 'HUY HIỆU',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up_rounded,
                      iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                      iconColor: isDark ? const Color(0xFF34D399) : AppConstants.secondary,
                      value: '#$rank',
                      label: 'XẾP HẠNG',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildXpCard(
                level: level,
                levelTitle: levelTitle,
                xpInCurrentLevel: xpInCurrentLevel,
                xpToNextLevel: xpToNextLevel,
                levelProgress: levelProgress,
              ),
            ],
          );
        }
        return Row(
          children: [
            // Badges count
            Expanded(
              child: _buildStatCard(
                icon: Icons.military_tech_rounded,
                iconBg: isDark ? AppConstants.surfHigh(context) : AppConstants.surfaceContainerHigh,
                iconColor: AppConstants.brand(context),
                value: '$unlockedBadges/$totalBadges',
                label: 'HUY HIỆU',
              ),
            ),
            const SizedBox(width: 12),
            // Rank
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up_rounded,
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                iconColor: isDark ? const Color(0xFF34D399) : AppConstants.secondary,
                value: '#$rank',
                label: 'XẾP HẠNG',
              ),
            ),
            const SizedBox(width: 12),
            // XP Progress
            Expanded(
              flex: 2,
              child: _buildXpCard(
                level: level,
                levelTitle: levelTitle,
                xpInCurrentLevel: xpInCurrentLevel,
                xpToNextLevel: xpToNextLevel,
                levelProgress: levelProgress,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppConstants.txt(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppConstants.txtMuted(context),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard({
    required int level,
    required String levelTitle,
    required int xpInCurrentLevel,
    required int xpToNextLevel,
    required double levelProgress,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cấp độ $level — $levelTitle',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                ),
              ),
              Text(
                '$xpInCurrentLevel / 1000 XP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.brand(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppConstants.surfHigh(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: max(0.02, levelProgress),
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.brand(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Chỉ còn $xpToNextLevel XP nữa để thăng cấp. Hãy tiếp tục làm bài thi!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppConstants.txtMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.brand(context), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.txt(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid(List<Map<String, dynamic>> badges) {
    final isDark = AppConstants.isDarkMode(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 560 ? 2 : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: badges.map((b) {
            final isLocked = b['locked'] as bool;
            final progress = (b['progress'] as num).toDouble();
            final date = b['date'] as String?;
            final progressText = b['progressText'] as String;

            return SizedBox(
              width: cols == 2
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth,
              child: Opacity(
                opacity: isLocked ? 0.72 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.surf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocked
                          ? AppConstants.border(context)
                          : (b['iconColor'] as Color).withValues(alpha: isDark ? 0.5 : 0.35),
                      width: isLocked ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isLocked
                              ? AppConstants.surfHigh(context)
                              : (isDark
                                  ? (b['iconColor'] as Color).withValues(alpha: 0.18)
                                  : (b['iconBg'] as Color)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLocked
                                ? AppConstants.border(context)
                                : (b['iconColor'] as Color).withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          b['icon'] as IconData,
                          color: isLocked
                              ? AppConstants.txtMuted(context)
                              : (b['iconColor'] as Color),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    b['title'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isLocked
                                          ? AppConstants.txtMuted(context)
                                          : AppConstants.txt(context),
                                    ),
                                  ),
                                ),
                                if (isLocked)
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: AppConstants.txtMuted(context),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b['desc'] as String,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppConstants.txtMuted(context),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!isLocked && date != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppConstants.surfHigh(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Đạt được: $date',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.brand(context),
                                  ),
                                ),
                              )
                            else ...[
                              Text(
                                progressText,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isLocked
                                      ? AppConstants.txtMuted(context)
                                      : (isDark ? const Color(0xFF34D399) : AppConstants.secondary),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppConstants.surfHigh(context),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: max(0.03, progress),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? AppConstants.border(context)
                                          : AppConstants.brand(context),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLeaderboard({
    required List<MapEntry<String, double>> sortedStudents,
    required Map<String, int> quizCounts,
    required int myRank,
  }) {
    if (sortedStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.border(context)),
        ),
        child: Center(
          child: Text(
            'Chưa có dữ liệu bài nộp nào trên hệ thống.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppConstants.txtMuted(context),
            ),
          ),
        ),
      );
    }

    // Top 10 học sinh
    final top10 = sortedStudents.take(10).toList();
    final bool isMyRankOutsideTop10 = myRank > 10;

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppConstants.surfLow(context),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'Hạng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txtMuted(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Học viên',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txtMuted(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Số bài',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txtMuted(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    'Tổng điểm (XP)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txtMuted(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Render Top 10
          ...top10.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final studentEntry = entry.value;
            final sId = studentEntry.key;
            final totalScore = studentEntry.value;
            final quizCount = quizCounts[sId] ?? 0;
            final isMe = sId == widget.studentId;

            return _buildLeaderboardRow(
              rank: rank,
              studentId: sId,
              totalScore: totalScore,
              quizCount: quizCount,
              isMe: isMe,
              hasBottomBorder: !(isMyRankOutsideTop10 && rank == 10),
            );
          }),

          // Nếu sinh viên hiện tại nằm ngoài Top 10
          if (isMyRankOutsideTop10) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              color: AppConstants.surfLow(context).withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.border(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.border(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.border(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Builder(builder: (context) {
              final myEntry = sortedStudents.firstWhere(
                (e) => e.key == widget.studentId,
                orElse: () => MapEntry(widget.studentId, 0.0),
              );
              final myScore = myEntry.value;
              final myQuizCount = quizCounts[widget.studentId] ?? 0;

              return _buildLeaderboardRow(
                rank: myRank,
                studentId: widget.studentId,
                totalScore: myScore,
                quizCount: myQuizCount,
                isMe: true,
                hasBottomBorder: false,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required int rank,
    required String studentId,
    required double totalScore,
    required int quizCount,
    required bool isMe,
    required bool hasBottomBorder,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    Color rankColor;
    Widget rankWidget;

    if (rank == 1) {
      rankColor = const Color(0xFFD97706);
      rankWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.emoji_events, color: Color(0xFFD97706), size: 16),
        ),
      );
    } else if (rank == 2) {
      rankColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
      rankWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '2',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: rankColor,
            ),
          ),
        ),
      );
    } else if (rank == 3) {
      rankColor = isDark ? const Color(0xFFFDBA74) : const Color(0xFFB45309);
      rankWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFEDD5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '3',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: rankColor,
            ),
          ),
        ),
      );
    } else {
      rankColor = AppConstants.txtMuted(context);
      rankWidget = Text(
        '#$rank',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
          color: isMe ? AppConstants.brand(context) : rankColor,
        ),
      );
    }

    final displayName = _getStudentDisplayName(studentId);
    final initials = _getInitials(displayName);
    final xp = (totalScore * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: isMe
            ? AppConstants.brand(context).withValues(alpha: isDark ? 0.15 : 0.08)
            : Colors.transparent,
        border: Border(
          bottom: hasBottomBorder
              ? BorderSide(color: AppConstants.border(context).withValues(alpha: 0.6))
              : BorderSide.none,
          left: isMe
              ? BorderSide(color: AppConstants.brand(context), width: 3.5)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 17,
            backgroundColor: isMe
                ? AppConstants.brand(context)
                : AppConstants.surfHigh(context),
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMe ? Colors.white : AppConstants.txtMuted(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                    color: isMe ? AppConstants.brand(context) : AppConstants.txt(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'MSSV: $studentId',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '$quizCount bài',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: AppConstants.txt(context),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${totalScore.toStringAsFixed(1)} đ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppConstants.brand(context) : AppConstants.txt(context),
                  ),
                ),
                Text(
                  '$xp XP',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
