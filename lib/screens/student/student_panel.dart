// lib/screens/student/student_panel.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import 'dashboard_page.dart';
import 'quiz_list_page.dart';
import 'history_page.dart';
import 'class_list_page.dart';
import '../auth/login_page.dart';

class StudentPanel extends StatefulWidget {
  final String studentId;
  final String classId;
  final String className;

  const StudentPanel({
    Key? key,
    required this.studentId,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<StudentPanel> createState() => StudentPanelState();
}

class StudentPanelState extends State<StudentPanel> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(
        studentId: widget.studentId,
        classId: widget.classId,
        className: widget.className,
        onNavigateToQuizList: () => setState(() => _selectedIndex = 1),
      ),
      QuizListPage(
        studentId: widget.studentId,
        classId: widget.classId,
        className: widget.className,
      ),
      HistoryPage(
        studentId: widget.studentId,
        classId: widget.classId,
        className: widget.className,
      ),
    ];
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppConstants.surf(context),
        title: Text(
          'Đăng xuất',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppConstants.txt(context),
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppConstants.txtMuted(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppConstants.txtMuted(context))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đăng xuất: $e'),
              backgroundColor: AppConstants.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  void _navigateToClassList() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClassListPage(studentId: widget.studentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // ===================== DESKTOP LAYOUT =====================
  Widget _buildDesktopLayout() {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Row(
        children: [
          // Side Navigation
          _buildSideNav(user),
          // Main Content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav(User? user) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'iconFill': Icons.dashboard, 'label': 'Trang chủ'},
      {'icon': Icons.assignment_outlined, 'iconFill': Icons.assignment, 'label': 'Bài thi'},
      {'icon': Icons.history_edu_outlined, 'iconFill': Icons.history_edu, 'label': 'Lịch sử'},
    ];

    return Container(
      width: 256,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        border: Border(right: BorderSide(color: AppConstants.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: Row(
              children: [
                Icon(Icons.school, color: AppConstants.brand(context), size: 32),
                const SizedBox(width: 12),
                Text(
                  'QuizMaster Pro',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.brand(context),
                  ),
                ),
              ],
            ),
          ),
          // User Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.surfHigh(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppConstants.brand(context),
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
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.className,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppConstants.txtMuted(context),
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
                children: navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == i;
                  return _buildSideNavItem(
                    icon: isSelected ? (item['iconFill'] as IconData) : (item['icon'] as IconData),
                    label: item['label'] as String,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIndex = i),
                  );
                }).toList(),
              ),
            ),
          ),
          // Bottom actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              children: [
                Divider(color: AppConstants.border(context)),
                _buildSideNavItem(
                  icon: Icons.arrow_back_outlined,
                  label: 'Đổi lớp',
                  isSelected: false,
                  onTap: _navigateToClassList,
                ),
                _buildSideNavItem(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  isSelected: false,
                  onTap: _handleLogout,
                  color: AppConstants.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ??
        (isSelected
            ? AppConstants.brand(context)
            : AppConstants.txtMuted(context));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.surfHigh(context)
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== MOBILE LAYOUT =====================
  Widget _buildMobileLayout() {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Column(
        children: [
          // Mobile Top Nav (đồng bộ hoàn toàn với màn hình chọn lớp)
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                border: Border(
                    bottom: BorderSide(color: AppConstants.border(context))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Nút đổi lớp học ở góc trái trên cùng
                      InkWell(
                        onTap: _navigateToClassList,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppConstants.surfHigh(context),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppConstants.border(context)),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppConstants.txt(context),
                            size: 20,
                          ),
                        ),
                      ),
                      Icon(Icons.school,
                          color: AppConstants.brand(context), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'QuizMaster Pro',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.brand(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Nút đăng xuất đồng bộ với màn hình ngoài
                      GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppConstants.errorContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.logout_rounded,
                              color: AppConstants.error, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showMobileMenu(),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppConstants.brand(context),
                          child: Text(
                            _getInitials(user),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(top: BorderSide(color: AppConstants.border(context))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildBottomNavItem(
                icon: Icons.dashboard_outlined,
                iconFill: Icons.dashboard,
                label: 'Trang chủ',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.assignment_outlined,
                iconFill: Icons.assignment,
                label: 'Bài thi',
                index: 1,
              ),
              _buildBottomNavItem(
                icon: Icons.history_edu_outlined,
                iconFill: Icons.history_edu,
                label: 'Lịch sử',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData iconFill,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? AppConstants.brand(context)
        : AppConstants.txtMuted(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                if (index >= 0) setState(() => _selectedIndex = index);
              },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected && index >= 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.brand(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(iconFill, color: color, size: 22),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppConstants.surf(context),
      builder: (context) {
        final user = _auth.currentUser;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppConstants.brand(context),
                      child: Text(
                        _getInitials(user),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? widget.studentId,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppConstants.txt(context),
                            ),
                          ),
                          Text(
                            widget.className,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppConstants.txtMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppConstants.border(context)),
                ListTile(
                  leading: Icon(Icons.arrow_back, color: AppConstants.txtMuted(context)),
                  title: Text('Đổi lớp', style: TextStyle(color: AppConstants.txt(context))),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToClassList();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: AppConstants.error),
                  title: Text('Đăng xuất', style: TextStyle(color: AppConstants.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return user.displayName![0].toUpperCase();
    }
    if (widget.studentId.isNotEmpty) return widget.studentId[0].toUpperCase();
    return 'S';
  }
}