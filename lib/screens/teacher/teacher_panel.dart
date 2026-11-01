// lib/screens/teacher/teacher_panel.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_classes_page.dart';
import 'quiz_bank_page.dart';
import 'quiz_bank_list_page.dart';
import 'teacher_setting_page.dart';
import '../auth/login_page.dart';
import '../../utils/constants.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({super.key});

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildNavigator(int index, Widget rootWidget) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => rootWidget,
        );
      },
    );
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < _navigatorKeys.length) {
      final navState = _navigatorKeys[index].currentState;
      if (navState != null && navState.canPop()) {
        navState.popUntil((route) => route.isFirst);
      }
    }
    setState(() => _selectedIndex = index);
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
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Lỗi khi đăng xuất: $e'))]),
              backgroundColor: AppConstants.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        if (constraints.maxWidth >= 768) return _buildDesktopLayout();
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Row(
        children: [
          _buildSideNav(user),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildNavigator(0, ManageClassesPage(onNavigate: _navigateToTab)),
                _buildNavigator(1, QuizBankPage(onNavigate: _navigateToTab)),
                _buildNavigator(2, QuizBankListPage(onNavigate: _navigateToTab)),
                _buildNavigator(3, const TeacherSettingPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav(User? user) {
    final isDark = AppConstants.isDarkMode(context);
    final navItems = [
      {'icon': Icons.groups_outlined, 'iconFill': Icons.groups, 'label': 'Quản lí lớp học'},
      {'icon': Icons.library_books_outlined, 'iconFill': Icons.library_books, 'label': 'Bài thi'},
      {'icon': Icons.storage_outlined, 'iconFill': Icons.storage, 'label': 'Ngân hàng câu hỏi'},
      {'icon': Icons.settings_outlined, 'iconFill': Icons.settings, 'label': 'Cài đặt'},
    ];

    return Container(
      width: 256,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(right: BorderSide(color: AppConstants.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 4),
            child: Row(children: [
              Icon(Icons.school, color: AppConstants.brand(context), size: 28),
              const SizedBox(width: 8),
              Text(
                'DUT QuizMaster',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.brand(context),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 32),
            child: Text(
              'Giáo viên',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.txtMuted(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.darkSurfaceContainerHigh : const Color(0xFFE8EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConstants.border(context)),
                    image: user?.photoURL != null ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover) : null,
                    color: user?.photoURL == null ? AppConstants.brand(context) : null,
                  ),
                  child: user?.photoURL == null ? Center(child: Text(_getInitials(user), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'))) : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    user?.displayName ?? 'Giảng viên',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.txt(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Giáo viên',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppConstants.txtMuted(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: navItems.asMap().entries.map((entry) {
                  return _buildSideNavItem(icon: entry.value['icon'] as IconData, iconFill: entry.value['iconFill'] as IconData, label: entry.value['label'] as String, index: entry.key);
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AppConstants.border(context), height: 16),
              ),
              _buildSideNavActionItem(icon: Icons.help_outline, label: 'Trung tâm trợ giúp', color: AppConstants.txtMuted(context), hoverColor: AppConstants.brand(context), onTap: () {}),
              _buildSideNavActionItem(icon: Icons.logout_rounded, label: 'Đăng xuất', color: AppConstants.txtMuted(context), hoverColor: const Color(0xFFBA1A1A), onTap: _handleLogout),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavItem({required IconData icon, required IconData iconFill, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    final isDark = AppConstants.isDarkMode(context);
    final activeBg = isDark ? AppConstants.darkSurfaceContainerHigh : const Color(0xFFE0E8FF);
    final activeColor = AppConstants.brand(context);
    final inactiveColor = AppConstants.txtMuted(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTab(index),
        borderRadius: BorderRadius.circular(8),
        hoverColor: isDark ? AppConstants.darkSurfaceContainer : const Color(0xFFF1F3FF),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(isSelected ? iconFill : icon, size: 24, color: isSelected ? activeColor : inactiveColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                          color: isSelected ? activeColor : AppConstants.txt(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavActionItem({required IconData icon, required String label, required Color color, required Color hoverColor, required VoidCallback onTap}) {
    final isDark = AppConstants.isDarkMode(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: isDark ? AppConstants.darkSurfaceContainer : const Color(0xFFF1F3FF),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      appBar: AppBar(
        backgroundColor: AppConstants.surf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppConstants.border(context))),
        title: Row(children: [
          Icon(Icons.school, color: AppConstants.brand(context), size: 24),
          const SizedBox(width: 8),
          Text('DUT QuizMaster', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: AppConstants.brand(context))),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _handleLogout,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppConstants.brand(context),
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null ? Text(_getInitials(user), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)) : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildNavigator(0, ManageClassesPage(onNavigate: _navigateToTab)),
          _buildNavigator(1, QuizBankPage(onNavigate: _navigateToTab)),
          _buildNavigator(2, QuizBankListPage(onNavigate: _navigateToTab)),
          _buildNavigator(3, const TeacherSettingPage()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.groups_outlined, 'iconFill': Icons.groups, 'label': 'Lớp học'},
      {'icon': Icons.library_books_outlined, 'iconFill': Icons.library_books, 'label': 'Bài thi'},
      {'icon': Icons.storage_outlined, 'iconFill': Icons.storage, 'label': 'Ngân hàng'},
      {'icon': Icons.settings_outlined, 'iconFill': Icons.settings, 'label': 'Cài đặt'},
    ];
    return Container(
      decoration: BoxDecoration(color: AppConstants.surf(context), border: Border(top: BorderSide(color: AppConstants.border(context)))),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = _selectedIndex == i;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToTab(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: AppConstants.brand(context).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                          child: Icon(item['iconFill'] as IconData, color: AppConstants.brand(context), size: 22),
                        )
                      else
                        Icon(item['icon'] as IconData, color: AppConstants.txtMuted(context), size: 22),
                      const SizedBox(height: 2),
                      Text(item['label'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppConstants.brand(context) : AppConstants.txtMuted(context))),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      return user.displayName![0].toUpperCase();
    }
    return 'GV';
  }
}
