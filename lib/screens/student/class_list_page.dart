// lib/screens/student/class_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import 'student_panel.dart';
import '../auth/login_page.dart';
import '../teacher/class_detail_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _selectedAssistantClass;

  List<Map<String, dynamic>> _studentClasses = [];
  List<Map<String, dynamic>> _assistantClasses = [];
  bool _isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _studentSub;
  StreamSubscription<List<Map<String, dynamic>>>? _assistantSub;

  @override
  void initState() {
    super.initState();
    _subscribeClasses();
  }

  void _subscribeClasses() {
    _assistantSub?.cancel();
    _studentSub?.cancel();

    _assistantSub = FirebaseService.getAssistantClasses(
      widget.studentId,
      email: _auth.currentUser?.email,
    ).listen((classes) {
      if (mounted) {
        setState(() {
          _assistantClasses = classes;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoading = false);
    });

    _studentSub = FirebaseService.getStudentClasses(widget.studentId).listen((classes) {
      if (mounted) {
        setState(() {
          _studentClasses = classes;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _assistantSub?.cancel();
    _studentSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

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
          backgroundColor: AppConstants.bg(context),
          body: isDesktop
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
          bottomNavigationBar: isDesktop
              ? null
              : (_selectedAssistantClass != null ? null : _buildBottomNav()),
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
                  'DUT QuizMaster',
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
          // User Info Profile Chip
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
                          widget.studentId,
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
                children: [
                  _buildNavItem(
                    icon: _selectedIndex == 0 ? Icons.school : Icons.school_outlined,
                    label: 'Lớp của tôi',
                    isActive: _selectedIndex == 0 && _selectedAssistantClass == null,
                    onTap: () => setState(() {
                      _selectedIndex = 0;
                      _selectedAssistantClass = null;
                    }),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 1 ? Icons.emoji_events : Icons.emoji_events_outlined,
                    label: 'Thành tích',
                    isActive: _selectedIndex == 1,
                    onTap: () => setState(() {
                      _selectedIndex = 1;
                      _selectedAssistantClass = null;
                    }),
                  ),
                  _buildNavItem(
                    icon: _selectedIndex == 2 ? Icons.calendar_month : Icons.calendar_month_outlined,
                    label: 'Lịch trình',
                    isActive: _selectedIndex == 2,
                    onTap: () => setState(() {
                      _selectedIndex = 2;
                      _selectedAssistantClass = null;
                    }),
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
                Divider(color: AppConstants.outlineVariant),
                _buildNavItem(
                  icon: _selectedIndex == 3 ? Icons.settings : Icons.settings_outlined,
                  label: 'Cài đặt',
                  isActive: _selectedIndex == 3,
                  onTap: () => setState(() {
                    _selectedIndex = 3;
                    _selectedAssistantClass = null;
                  }),
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
    final itemColor = color ??
        (isActive
            ? AppConstants.brand(context)
            : AppConstants.txtMuted(context));
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
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
    if (_selectedAssistantClass != null) {
      return _buildMainContent(context, isDesktop: false);
    }
    final user = _auth.currentUser;
    return Column(
      children: [
        // Mobile Top Nav
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
                    Icon(Icons.school,
                        color: AppConstants.brand(context), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'DUT QuizMaster',
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
                    GestureDetector(
                      onTap: () => _handleLogout(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.errorContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppConstants.error, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
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
                icon: Icons.school_outlined,
                iconFill: Icons.school,
                label: 'Lớp học',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.emoji_events_outlined,
                iconFill: Icons.emoji_events,
                label: 'Thành tích',
                index: 1,
              ),
              _buildBottomNavItem(
                icon: Icons.calendar_month_outlined,
                iconFill: Icons.calendar_month,
                label: 'Lịch trình',
                index: 2,
              ),
              _buildBottomNavItem(
                icon: Icons.settings_outlined,
                iconFill: Icons.settings,
                label: 'Cài đặt',
                index: 3,
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
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? AppConstants.primary
        : AppConstants.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedIndex = index;
            _selectedAssistantClass = null;
          }),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primary.withValues(alpha: 0.12),
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

  // ===================== MAIN CONTENT SWITCHER =====================
  Widget _buildMainContent(BuildContext context, {required bool isDesktop}) {
    switch (_selectedIndex) {
      case 0:
        if (_selectedAssistantClass != null) {
          return ClassDetailPage(
            classId: _selectedAssistantClass!['id'] as String,
            className: _selectedAssistantClass!['name'] as String,
            isAssistant: true,
            onBack: () => setState(() => _selectedAssistantClass = null),
          );
        }
        return _buildClassGrid(context, isDesktop: isDesktop);
      case 1:
        return AchievementPage(
          studentId: widget.studentId,
          showTopBar: isDesktop,
        );
      case 2:
        return SchedulePage(
          studentId: widget.studentId,
          showTopBar: isDesktop,
        );
      case 3:
        return SettingPage(
          studentId: widget.studentId,
          showTopBar: isDesktop,
        );
      default:
        if (_selectedAssistantClass != null) {
          return ClassDetailPage(
            classId: _selectedAssistantClass!['id'] as String,
            className: _selectedAssistantClass!['name'] as String,
            isAssistant: true,
            onBack: () => setState(() => _selectedAssistantClass = null),
          );
        }
        return _buildClassGrid(context, isDesktop: isDesktop);
    }
  }

  // ===================== CLASS GRID CONTENT =====================
  Widget _buildClassGrid(BuildContext context, {required bool isDesktop}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primary),
      );
    }

    if (_assistantClasses.isEmpty && _studentClasses.isEmpty) {
      return _buildEmptyState(context);
    }

    final query = _searchQuery.toLowerCase().trim();
    final filteredAssistantClasses = _assistantClasses.where((classData) {
      if (query.isEmpty) return true;
      final name = (classData['name'] ?? '').toString().toLowerCase();
      final desc = (classData['description'] ?? '').toString().toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();

    final filteredStudentClasses = _studentClasses.where((classData) {
      if (query.isEmpty) return true;
      final name = (classData['name'] ?? '').toString().toLowerCase();
      final desc = (classData['description'] ?? '').toString().toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header & Search Bar
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
                        color: AppConstants.txt(context),
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chọn một lớp học để bắt đầu ôn tập, làm bài kiểm tra hoặc quản lý trợ giảng.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: AppConstants.txtMuted(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Thanh tìm kiếm lớp học
                    Container(
                      decoration: BoxDecoration(
                        color: AppConstants.surf(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.border(context)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppConstants.txt(context),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm lớp học theo tên hoặc mô tả...',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppConstants.txtMuted(context),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppConstants.txtMuted(context),
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Nội dung danh sách lớp hoặc thông báo rỗng khi tìm kiếm
              if (filteredAssistantClasses.isEmpty && filteredStudentClasses.isEmpty)
                _buildSearchEmptyState(context)
              else ...[
                // SECTION 1: LỚP HỌC TRỢ GIẢNG (Nếu có)
                if (filteredAssistantClasses.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Lớp học phụ trách Trợ giảng',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppConstants.txt(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${filteredAssistantClasses.length}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bạn có quyền hỗ trợ tạo/sửa đề thi, thêm & quản lý sinh viên, xem thống kê điểm.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppConstants.txtMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 520 ? 2 : 1;
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: filteredAssistantClasses.asMap().entries.map((entry) {
                          final i = entry.key;
                          final classData = entry.value;
                          final classId = classData['id'] as String;
                          return SizedBox(
                            width: cols == 2
                                ? (constraints.maxWidth - 24) / 2
                                : constraints.maxWidth,
                            child: _buildClassCard(
                              context,
                              classId,
                              classData,
                              i,
                              isAssistant: true,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                // SECTION 2: LỚP HỌC ĐANG THEO HỌC (Nếu có)
                if (filteredStudentClasses.isNotEmpty) ...[
                  if (filteredAssistantClasses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Lớp học đang theo học (${filteredStudentClasses.length})',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.txt(context),
                        ),
                      ),
                    ),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 520 ? 2 : 1;
                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: filteredStudentClasses.asMap().entries.map((entry) {
                          final i = entry.key;
                          final classData = entry.value;
                          final classId = classData['id'] as String;
                          return SizedBox(
                            width: cols == 2
                                ? (constraints.maxWidth - 24) / 2
                                : constraints.maxWidth,
                            child: _buildClassCard(
                              context,
                              classId,
                              classData,
                              i,
                              isAssistant: false,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    String classId,
    Map<String, dynamic> data,
    int index, {
    bool isAssistant = false,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    final icon = isAssistant ? Icons.school_outlined : _subjectIcons[index % _subjectIcons.length];
    final className = data['name'] ?? 'Lớp học';
    final description = data['description'] ?? 'Không có mô tả';

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAssistant
                ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                : AppConstants.border(context),
            width: isAssistant ? 1.5 : 1,
          ),
          boxShadow: isAssistant
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: isAssistant
              ? const Color(0xFF7C3AED).withValues(alpha: 0.05)
              : AppConstants.surfLow(context),
          onTap: () {
            if (isAssistant) {
              setState(() {
                _selectedAssistantClass = {
                  'id': classId,
                  'name': className,
                };
              });
            } else {
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
            }
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
                        color: isAssistant
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
                            : (isDark
                                ? AppConstants.surfHigh(context)
                                : AppConstants.surfaceContainerHigh),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isAssistant ? const Color(0xFF7C3AED) : AppConstants.brand(context),
                        size: 24,
                      ),
                    ),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAssistant
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                            : (isDark
                                ? AppConstants.surfHigh(context)
                                : const Color(0xFFEBECF0)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isAssistant ? 'Trợ giảng (TA)' : _getClassBadge(index),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isAssistant
                              ? const Color(0xFF7C3AED)
                              : (isDark
                                  ? AppConstants.txt(context)
                                  : const Color(0xFF42526E)),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.txt(context),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
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
                      if (isAssistant) {
                        setState(() {
                          _selectedAssistantClass = {
                            'id': classId,
                            'name': className,
                          };
                        });
                      } else {
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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAssistant
                          ? const Color(0xFF7C3AED)
                          : (isDark
                              ? const Color(0xFF2563EB)
                              : AppConstants.primary),
                      foregroundColor: Colors.white,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isAssistant) ...[
                          const Icon(Icons.tune_rounded, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(isAssistant ? 'Quản lý lớp học (Trợ giảng)' : 'Truy cập lớp học'),
                      ],
                    ),
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
    final isDark = AppConstants.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.surfHigh(context)
            : AppConstants.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppConstants.txtMuted(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppConstants.txt(context),
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
              decoration: BoxDecoration(
                color: AppConstants.surfHigh(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 56,
                color: AppConstants.txtMuted(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa tham gia lớp học nào',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.txt(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Liên hệ giáo viên để được thêm vào lớp học.',
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

  Widget _buildSearchEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surfHigh(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppConstants.txtMuted(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy lớp học',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.txt(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Không có lớp học nào phù hợp với từ khóa "$_searchQuery".',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppConstants.txtMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Xem tất cả lớp học'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    final isDark = AppConstants.isDarkMode(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7F1D1D) : AppConstants.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppConstants.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.txt(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppConstants.txtMuted(context),
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