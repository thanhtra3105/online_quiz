// lib/screens/student/achievement_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';

class AchievementPage extends StatelessWidget {
  final String studentId;
  const AchievementPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Header
                      const Text(
                        'Thành tích cá nhân',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Theo dõi sự tiến bộ và những cột mốc học tập của bạn.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: AppConstants.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Bento
                      _buildStatsBento(),
                      const SizedBox(height: 32),

                      // Badges Section
                      _buildSectionTitle(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Huy hiệu đã đạt được',
                      ),
                      const SizedBox(height: 16),
                      _buildBadgesGrid(),
                      const SizedBox(height: 32),

                      // Leaderboard
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(
                            icon: Icons.leaderboard_outlined,
                            title: 'Bảng xếp hạng tháng',
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Xem tất cả',
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
                      const SizedBox(height: 12),
                      _buildLeaderboard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
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
              child: Icon(Icons.arrow_back_rounded, color: AppConstants.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_events, color: AppConstants.primary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Thành tích',
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

  Widget _buildStatsBento() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return Row(
          children: [
            // Badges count
            Expanded(
              child: _buildStatCard(
                icon: Icons.military_tech,
                iconBg: AppConstants.surfaceContainerHigh,
                iconColor: AppConstants.primary,
                value: '12',
                label: 'HUY HIỆU',
              ),
            ),
            const SizedBox(width: 12),
            // Rank
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: AppConstants.secondary,
                value: '#4',
                label: 'XẾP HẠNG',
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 12),
              // XP Progress
              Expanded(
                flex: 2,
                child: _buildXpCard(),
              ),
            ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppConstants.onSurface,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppConstants.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard() {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cấp độ 8 — Học giả',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.onSurface,
                ),
              ),
              Text(
                '2400 / 3000 XP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppConstants.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.80,
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chỉ còn 600 XP để thăng cấp. Cố lên!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppConstants.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid() {
    final badges = [
      {
        'icon': Icons.bolt,
        'iconColor': AppConstants.secondary,
        'iconBg': const Color(0xFFD1FAE5),
        'title': 'Vua tốc độ',
        'desc': 'Hoàn thành bài kiểm tra dưới 50% thời gian cho phép với điểm số tuyệt đối.',
        'date': '12/10/2023',
        'locked': false,
      },
      {
        'icon': Icons.menu_book,
        'iconColor': AppConstants.primary,
        'iconBg': AppConstants.surfaceContainerHigh,
        'title': 'Học giả chăm chỉ',
        'desc': 'Hoàn thành 50 bài tập tự luyện trong một tuần liên tiếp.',
        'date': '05/11/2023',
        'locked': false,
      },
      {
        'icon': Icons.verified,
        'iconColor': const Color(0xFFB8860B),
        'iconBg': const Color(0xFFFFF9C4),
        'title': 'Hoàn hảo 10/10',
        'desc': 'Đạt điểm tuyệt đối trong bài kiểm tra cuối kỳ môn Toán Cao Cấp.',
        'date': '20/11/2023',
        'locked': false,
      },
      {
        'icon': Icons.analytics_outlined,
        'iconColor': AppConstants.onSurfaceVariant,
        'iconBg': AppConstants.surfaceContainerHigh,
        'title': 'Chuyên gia phân tích',
        'desc': 'Hoàn thành chuỗi 10 bài tập Phân tích Dữ liệu khó. Đang tiến hành (7/10).',
        'date': null,
        'locked': true,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 540 ? 2 : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: badges.map((b) {
            final isLocked = b['locked'] as bool;
            return SizedBox(
              width: cols == 2
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth,
              child: Opacity(
                opacity: isLocked ? 0.6 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLocked
                          ? AppConstants.outlineVariant
                          : AppConstants.outlineVariant,
                      style:
                          isLocked ? BorderStyle.solid : BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: b['iconBg'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (b['iconColor'] as Color)
                                .withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          b['icon'] as IconData,
                          color: b['iconColor'] as Color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['title'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b['desc'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppConstants.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (!isLocked && b['date'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppConstants.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Đạt được: ${b['date']}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: AppConstants.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else if (isLocked) ...[
                              const SizedBox(height: 4),
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppConstants.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.7,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppConstants.outline,
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

  Widget _buildLeaderboard() {
    final rows = [
      {'rank': '1', 'initials': 'NV', 'name': 'Nguyễn Văn A', 'xp': '5,240', 'rankColor': const Color(0xFFFFD700), 'isMe': false},
      {'rank': '2', 'initials': 'TH', 'name': 'Trần Thị B', 'xp': '4,890', 'rankColor': const Color(0xFFC0C0C0), 'isMe': false},
      {'rank': '3', 'initials': 'LM', 'name': 'Lê Văn C', 'xp': '4,120', 'rankColor': const Color(0xFFCD7F32), 'isMe': false},
      {'rank': '4', 'initials': 'Bạn', 'name': 'Bạn', 'xp': '3,850', 'rankColor': AppConstants.primary, 'isMe': true},
      {'rank': '5', 'initials': 'PH', 'name': 'Phạm Thị D', 'xp': '3,600', 'rankColor': AppConstants.onSurfaceVariant, 'isMe': false},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppConstants.surfaceContainerLow,
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('Hạng', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.onSurfaceVariant, letterSpacing: 0.5))),
                SizedBox(width: 12),
                Expanded(child: Text('Học viên', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.onSurfaceVariant, letterSpacing: 0.5))),
                Text('Điểm XP', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.onSurfaceVariant, letterSpacing: 0.5)),
              ],
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final r = entry.value;
            final isMe = r['isMe'] as bool;
            return Container(
              decoration: BoxDecoration(
                color: isMe
                    ? AppConstants.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(color: AppConstants.outlineVariant.withValues(alpha: 0.5)),
                  left: isMe ? const BorderSide(color: AppConstants.primary, width: 3) : BorderSide.none,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      r['rank'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: r['rankColor'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isMe
                        ? AppConstants.primary
                        : AppConstants.surfaceContainerHigh,
                    child: Text(
                      (r['initials'] as String).length > 2
                          ? (r['initials'] as String).substring(0, 2)
                          : r['initials'] as String,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isMe
                            ? Colors.white
                            : AppConstants.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['name'] as String,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                        color: AppConstants.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    r['xp'] as String,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                      color: isMe
                          ? AppConstants.primary
                          : AppConstants.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
