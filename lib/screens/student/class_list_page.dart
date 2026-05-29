// lib/screens/student/class_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import 'student_panel.dart';
import '../auth/login_page.dart';
import 'achievement_page.dart';
import 'schedule_page.dart';
import 'setting_page.dart';

class ClassListPage extends StatefulWidget {
  final String studentId;

  const ClassListPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends State<ClassListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  // Cycle through a set of subject icons
  static const List<IconData> _subjectIcons = [
    Icons.science_outlined,
    Icons.biotech_outlined,
    Icons.calculate_outlined,
    Icons.public_outlined,
    Icons.history_edu_outlined,
    Icons.computer_outlined,
    Icons.psychology_outlined,
    Icons.architecture_outlined,
  ];

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppConstants.surface,
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppConstants.onSurface,
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppConstants.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppConstants.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đăng xuất: $e'),
              backgroundColor: AppConstants.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return Scaffold(
          backgroundColor: AppConstants.background,
          body: isDesktop
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        );
      },
    );
  }

  // ===================== DESKTOP =====================
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSideNav(context),
        Expanded(child: _buildMainContent(context, isDesktop: true)),
      ],
    );
  }

  Widget _buildSideNav(BuildContext context) {
    final user = _auth.currentUser;
    return Container(
      width: 256,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppConstants.surfaceContainerLow,
        border: Border(right: BorderSide(color: AppConstants.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: Row(
              children: [
                const Icon(Icons.school, color: AppConstants.primary, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'QuizMaster Pro',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primary,
                  ),
                ),
              ],
            ),
          ),
          // User Info Profile Chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppConstants.primary,
                    child: Text(
                      _getInitials(user),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? widget.studentId,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.studentId,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppConstants.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nav Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _buildNavItem(
                    icon: _selectedIndex == 0 ? Icons.school : Icons.school_outlined,
                    label: 'Lớp của tôi',
                    isActive: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 1 ? Icons.emoji_events : Icons.emoji_events_outlined,
                    label: 'Thành tích',
                    isActive: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 2 ? Icons.calendar_month : Icons.calendar_month_outlined,
                    label: 'Lịch trình',
                    isActive: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ],
              ),
            ),
          ),

          // Bottom: Settings & Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              children: [
                const Divider(color: AppConstants.outlineVariant),
                _buildNavItem(
                  icon: _selectedIndex == 3 ? Icons.settings : Icons.settings_outlined,
                  label: 'Cài đặt',
                  isActive: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _buildNavItem(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  isActive: false,
                  color: AppConstants.error,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? color,
    VoidCallback? onTap,
  }) {
    final itemColor =
        color ?? (isActive ? AppConstants.primary : AppConstants.onSurfaceVariant);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppConstants.surfaceContainerHigh
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: itemColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== MOBILE =====================
  Widget _buildMobileLayout(BuildContext context) {
    final user = _auth.currentUser;
    return Column(
      children: [
        // Mobile Top Nav
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppConstants.surface,
              border: Border(
                  bottom: BorderSide(color: AppConstants.outlineVariant)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QuizMaster Pro',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primary,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleLogout(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppConstants.errorContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppConstants.error, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppConstants.primary,
                      child: Text(
                        _getInitials(user),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildMainContent(context, isDesktop: false)),
      ],
    );
  }

  // ===================== MAIN CONTENT SWITCHER =====================
  Widget _buildMainContent(BuildContext context, {required bool isDesktop}) {
    switch (_selectedIndex) {
      case 0:
        return _buildClassGrid(context, isDesktop: isDesktop);
      case 1:
        return AchievementPage(studentId: widget.studentId);
      case 2:
        return SchedulePage(studentId: widget.studentId);
      case 3:
        return SettingPage(studentId: widget.studentId);
      default:
        return _buildClassGrid(context, isDesktop: isDesktop);
    }
  }

  // ===================== CLASS GRID CONTENT =====================
  Widget _buildClassGrid(BuildContext context, {required bool isDesktop}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getStudentClasses(widget.studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.primary),
          );
        }

        if (snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        final classes = snapshot.data!;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lớp học của tôi',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isDesktop ? 36 : 24,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.onSurface,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Chọn một lớp học để bắt đầu ôn tập và làm bài kiểm tra.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: AppConstants.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bento Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 520 ? 2 : 1;
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: classes.asMap().entries.map((entry) {
                          final i = entry.key;
                          final classData = entry.value;
                          final classId = classData['id'] as String;
                          return SizedBox(
                            width: cols == 2
                                ? (constraints.maxWidth - 24) / 2
                                : constraints.maxWidth,
                            child: _buildClassCard(
                                context, classId, classData, i),
                          );
                        }).toList(),
                      );
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
  }

  Widget _buildClassCard(
    BuildContext context,
    String classId,
    Map<String, dynamic> data,
    int index,
  ) {
    final icon = _subjectIcons[index % _subjectIcons.length];
    final className = data['name'] ?? 'Lớp học';
    final description = data['description'] ?? 'Không có mô tả';

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppConstants.surfaceContainerLow,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentPanel(
                  studentId: widget.studentId,
                  classId: classId,
                  className: className,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon row + badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          color: AppConstants.primary, size: 24),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBECF0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _getClassBadge(index),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF42526E),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Class name
                Text(
                  className,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Stats row (quizCount, studentCount)
                if ((data['quizCount'] != null) ||
                    (data['studentCount'] != null)) ...[
                  Row(
                    children: [
                      if (data['quizCount'] != null)
                        _buildStatPill(
                          icon: Icons.quiz_outlined,
                          label: '${data['quizCount']} bài thi',
                        ),
                      if (data['quizCount'] != null &&
                          data['studentCount'] != null)
                        const SizedBox(width: 8),
                      if (data['studentCount'] != null)
                        _buildStatPill(
                          icon: Icons.group_outlined,
                          label: '${data['studentCount']} HS',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentPanel(
                            studentId: widget.studentId,
                            classId: classId,
                            className: className,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primary,
                      foregroundColor: AppConstants.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Truy cập lớp học'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppConstants.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppConstants.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppConstants.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
              decoration: const BoxDecoration(
                color: AppConstants.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 56,
                color: AppConstants.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa tham gia lớp học nào',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Liên hệ giáo viên để được thêm vào lớp học.',
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

  Widget _buildErrorWidget(dynamic error) {
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
                Icons.error_outline,
                size: 40,
                color: AppConstants.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppConstants.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Helpers =====================
  String _getInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return user.displayName![0].toUpperCase();
    }
    return widget.studentId.isNotEmpty
        ? widget.studentId[0].toUpperCase()
        : 'S';
  }

  String _getClassBadge(int index) {
    const badges = [
      'Active',
      'Weekly',
      'Midterm',
      'Ongoing',
      'New',
      'Final',
      'Practice',
      'Review',
    ];
    return badges[index % badges.length];
  }
}