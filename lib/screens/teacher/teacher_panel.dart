// lib/screens/teacher/teacher_panel.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_classes_page.dart';
import 'quiz_bank_page.dart';
import 'quiz_bank_list_page.dart';
import '../auth/login_page.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({Key? key}) : super(key: key);

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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAD6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A), size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Dang xuat', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF041B3C))),
              const SizedBox(height: 8),
              const Text('Ban co chac chan muon dang xuat?', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654), height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFC3C6D6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Huy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF041B3C))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFBA1A1A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Dang xuat', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Loi khi dang xuat: $e'))]),
              backgroundColor: const Color(0xFFBA1A1A),
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
      backgroundColor: const Color(0xFFF9F9FF),
      body: Row(
        children: [
          _buildSideNav(user),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildNavigator(0, ManageClassesPage(onNavigate: (i) => setState(() => _selectedIndex = i))),
                _buildNavigator(1, QuizBankPage(onNavigate: (i) => setState(() => _selectedIndex = i))),
                _buildNavigator(2, const QuizBankListPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav(User? user) {
    final navItems = [
      {'icon': Icons.groups_outlined, 'iconFill': Icons.groups, 'label': 'Quản lí lớp học'},
      {'icon': Icons.library_books_outlined, 'iconFill': Icons.library_books, 'label': 'Bài thi'},
      {'icon': Icons.storage_outlined, 'iconFill': Icons.storage, 'label': 'Ngân hàng câu hỏi'},
      {'icon': Icons.analytics_outlined, 'iconFill': Icons.analytics, 'label': 'Thống kê'},
      {'icon': Icons.settings_outlined, 'iconFill': Icons.settings, 'label': 'Cài đặt'},
    ];

    return Container(
      width: 256,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9FF),
        border: Border(right: BorderSide(color: Color(0xFFC3C6D6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 4),
            child: Row(children: [
              const Icon(Icons.school, color: Color(0xFF003D9B), size: 28),
              const SizedBox(width: 8),
              const Text('DUT QuizMaster', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF003D9B))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 32),
            child: Text('Giáo viên', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF434654).withValues(alpha: 0.7))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC3C6D6)),
                    image: user?.photoURL != null ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover) : null,
                    color: user?.photoURL == null ? const Color(0xFF003D9B) : null,
                  ),
                  child: user?.photoURL == null ? Center(child: Text(_getInitials(user), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'))) : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? 'Alex Johnson', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF041B3C)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Text('Giáo viên', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF434654), letterSpacing: 0.5)),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Color(0xFFC3C6D6), height: 16),
              ),
              _buildSideNavActionItem(icon: Icons.help_outline, label: 'Help Center', color: const Color(0xFF434654), hoverColor: const Color(0xFF003D9B), onTap: () {}),
              _buildSideNavActionItem(icon: Icons.logout_rounded, label: 'Logout', color: const Color(0xFF434654), hoverColor: const Color(0xFFBA1A1A), onTap: _handleLogout),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavItem({required IconData icon, required IconData iconFill, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    final isDisabled = index > 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFF1F3FF),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0E8FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(isSelected ? iconFill : icon, size: 24, color: isSelected ? const Color(0xFF003D9B) : const Color(0xFF434654)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                          color: isSelected ? const Color(0xFF003D9B) : const Color(0xFF434654),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF003D9B),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFF1F3FF),
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
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: const Color(0xFFC3C6D6))),
        title: const Row(children: [
          Icon(Icons.school, color: Color(0xFF003D9B), size: 24),
          SizedBox(width: 8),
          Text('QuizMaster Pro', style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF003D9B))),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _handleLogout,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF003D9B),
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
          _buildNavigator(0, ManageClassesPage(onNavigate: (i) => setState(() => _selectedIndex = i))),
          _buildNavigator(1, QuizBankPage(onNavigate: (i) => setState(() => _selectedIndex = i))),
          _buildNavigator(2, const QuizBankListPage()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.groups_outlined, 'iconFill': Icons.groups, 'label': 'Lop hoc'},
      {'icon': Icons.library_books_outlined, 'iconFill': Icons.library_books, 'label': 'Kho de thi'},
      {'icon': Icons.storage_outlined, 'iconFill': Icons.storage, 'label': 'Ngan hang'},
    ];
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF9F9FF), border: Border(top: BorderSide(color: Color(0xFFC3C6D6)))),
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
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF003D9B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                          child: Icon(item['iconFill'] as IconData, color: const Color(0xFF003D9B), size: 22),
                        )
                      else
                        Icon(item['icon'] as IconData, color: const Color(0xFF434654), size: 22),
                      const SizedBox(height: 2),
                      Text(item['label'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? const Color(0xFF003D9B) : const Color(0xFF434654))),
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
    return 'T';
  }
}
