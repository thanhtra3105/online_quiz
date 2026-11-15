// lib/screens/teacher/manage_classes_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_detail_page.dart';
import '../../services/course_subject_service.dart';
import '../../utils/constants.dart';

class ManageClassesPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const ManageClassesPage({super.key, this.onNavigate});

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Điều hướng 2 cấp:
  // null = Cấp 1: Danh sách Lớp học phần
  // '_all' = Tất cả lớp học
  // '_uncategorized' = Lớp học chung (chưa phân loại)
  // ID cụ thể = Các lớp của học phần đó
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedSubjectCode;
  String? _selectedSubjectColorHex;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<IconData> _subjectIcons = [
    Icons.school_rounded,
    Icons.computer_outlined,
    Icons.science_outlined,
    Icons.biotech_outlined,
    Icons.calculate_outlined,
    Icons.public_outlined,
    Icons.history_edu_outlined,
    Icons.psychology_outlined,
    Icons.architecture_outlined,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = _auth.currentUser?.uid ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Column(
        children: [
          _buildTopAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedSubjectId == null) ...[
                      // CẤP 1: DANH SÁCH LỚP HỌC PHẦN
                      _buildSubjectsHeader(),
                      const SizedBox(height: 24),
                      _buildOverallStats(teacherId),
                      const SizedBox(height: 28),
                      _buildSubjectsGrid(teacherId),
                    ] else ...[
                      // CẤP 2: DANH SÁCH LỚP HỌC TRONG HỌC PHẦN
                      _buildClassesHeader(),
                      const SizedBox(height: 24),
                      _buildSubjectClassStats(teacherId),
                      const SizedBox(height: 28),
                      _buildClassGrid(teacherId),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TOP APP BAR
  // ============================================
  Widget _buildTopAppBar() {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final searchField = Container(
      width: isMobile ? double.infinity : 300,
      height: 42,
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
        decoration: InputDecoration(
          hintText: _selectedSubjectId == null ? 'Tìm kiếm học phần...' : 'Tìm kiếm lớp, phòng, tiết...',
          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
          prefixIcon: Icon(Icons.search_rounded, color: AppConstants.txtMuted(context), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? searchField
          : Row(
              children: [
                searchField,
                const SizedBox(width: 32),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSubjectId = null;
                        });
                        widget.onNavigate?.call(0);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                        ),
                        child: Text(
                          'Quản lý lớp học',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.brand(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => widget.onNavigate?.call(1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Bài thi',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => widget.onNavigate?.call(2),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Ngân hàng câu hỏi',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Tài khoản',
                  onPressed: () {},
                  icon: Icon(Icons.account_circle_outlined, color: AppConstants.txtMuted(context)),
                ),
              ],
            ),
    );
  }

  // ============================================
  // CẤP 1: HEADER & STATS & GRID LỚP HỌC PHẦN
  // ============================================
  Widget _buildSubjectsHeader() {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final headerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfHigh(context) : const Color(0xFF003D9B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.collections_bookmark_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Danh sách Học phần',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Quản lý các lớp học theo từng học phần giảng dạy. Bạn có thể mở nhiều lớp cho cùng một học phần.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _selectedSubjectId = '_all';
              _selectedSubjectName = 'Tất cả lớp học';
              _selectedSubjectCode = 'ALL';
            });
          },
          icon: const Icon(Icons.list_alt_rounded, size: 18),
          label: const Text('Xem tất cả lớp'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            side: BorderSide(color: AppConstants.border(context)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => _showCreateOrEditSubjectDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Thêm học phần mới',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.brand(context),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerInfo,
          const SizedBox(height: 16),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: headerInfo),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }

  Widget _buildOverallStats(String teacherId) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots(),
      builder: (context, classSnap) {
        final classes = classSnap.data?.docs ?? [];
        int totalStudents = 0;
        for (var c in classes) {
          final data = c.data() as Map<String, dynamic>;
          totalStudents += (data['studentCount'] as num?)?.toInt() ?? 0;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: CourseSubjectService.getSubjectsStream(teacherId),
          builder: (context, subjSnap) {
            final subjectsCount = subjSnap.data?.docs.length ?? 0;

            final card1 = _buildStatCard(
              title: 'Lớp học phần',
              value: '$subjectsCount',
              subtitle: 'Học phần bạn đang giảng dạy',
              icon: Icons.collections_bookmark_rounded,
              accentColor: const Color(0xFF003D9B),
              bgColor: const Color(0xFFEFF6FF),
            );

            final card2 = _buildStatCard(
              title: 'Tổng số lớp học',
              value: '${classes.length}',
              subtitle: 'Lớp học đang hoạt động',
              icon: Icons.school_rounded,
              accentColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
            );

            final card3 = _buildStatCard(
              title: 'Tổng sinh viên',
              value: '$totalStudents',
              subtitle: 'Sinh viên đã tham gia',
              icon: Icons.people_alt_rounded,
              accentColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            );

            if (isMobile) {
              return Column(
                children: [
                  card1,
                  const SizedBox(height: 12),
                  card2,
                  const SizedBox(height: 12),
                  card3,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 16),
                Expanded(child: card2),
                const SizedBox(width: 16),
                Expanded(child: card3),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectsGrid(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: CourseSubjectService.getSubjectsStream(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B))),
            ),
          );
        }

        var subjects = snapshot.data?.docs ?? [];

        if (_searchQuery.isNotEmpty) {
          subjects = subjects.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final code = (data['code'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || code.contains(_searchQuery);
          }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: 220,
                  ),
                  itemCount: subjects.length + 1, // +1 cho thẻ Chưa phân loại / Lớp học chung
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildUncategorizedSubjectCard(teacherId);
                    }
                    final doc = subjects[index - 1];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildSubjectCard(doc.id, data, teacherId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUncategorizedSubjectCard(String teacherId) {
    final isDark = AppConstants.isDarkMode(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubjectId = '_uncategorized';
          _selectedSubjectName = 'Lớp học chung (Chưa phân loại)';
          _selectedSubjectCode = 'CHUNG';
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CHUNG',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.txtMuted(context),
                    ),
                  ),
                ),
                Icon(Icons.folder_open_rounded, color: AppConstants.brand(context), size: 24),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Lớp học chung / Chưa phân loại',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppConstants.txt(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Bao gồm các lớp học chưa được gắn vào học phần cụ thể.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppConstants.txtMuted(context),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Divider(height: 1, thickness: 1, color: AppConstants.border(context)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .where('teacherId', isEqualTo: teacherId)
                      .snapshots(),
                  builder: (context, snap) {
                    final allDocs = snap.data?.docs ?? [];
                    final uncategorizedCount = allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final subId = data['courseSubjectId'];
                      return subId == null || subId.toString().isEmpty;
                    }).length;

                    return Text(
                      '$uncategorizedCount lớp học',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.txtMuted(context),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Text(
                      'Vào xem lớp',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.brand(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: AppConstants.brand(context)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String subjectId, Map<String, dynamic> data, String teacherId) {
    final name = data['name'] ?? 'Lớp học phần';
    final code = data['code'] ?? '';
    final description = (data['description'] ?? '').toString();
    final colorHex = (data['colorHex'] ?? '#003D9B').toString();
    final isDark = AppConstants.isDarkMode(context);

    Color cardColor;
    try {
      cardColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (_) {
      cardColor = const Color(0xFF003D9B);
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubjectId = subjectId;
          _selectedSubjectName = name;
          _selectedSubjectCode = code;
          _selectedSubjectColorHex = colorHex;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppConstants.txtMuted(context), size: 18),
                  color: AppConstants.surf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppConstants.border(context)),
                  ),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showCreateOrEditSubjectDialog(subjectId, data);
                    } else if (action == 'delete') {
                      _confirmDeleteSubject(subjectId, name);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppConstants.brand(context)),
                          const SizedBox(width: 8),
                          Text('Chỉnh sửa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context))),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Text('Xóa học phần', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppConstants.txt(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              description.isNotEmpty ? description : 'Không có mô tả cho học phần này.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppConstants.txtMuted(context),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Divider(height: 1, thickness: 1, color: AppConstants.border(context)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .where('teacherId', isEqualTo: teacherId)
                      .where('courseSubjectId', isEqualTo: subjectId)
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return Text(
                      '$count lớp học',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.txtMuted(context),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Text(
                      'Vào xem lớp',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cardColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: cardColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CẤP 2: HEADER & GRID LỚP HỌC TRONG HỌC PHẦN
  // ============================================
  Widget _buildClassesHeader() {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final headerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NÚT TRỞ LẠI TO VÀ RÕ RÀNG
        InkWell(
          onTap: () {
            setState(() {
              _selectedSubjectId = null;
              _selectedSubjectName = null;
              _selectedSubjectCode = null;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.brand(context).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 20, color: AppConstants.brand(context)),
                const SizedBox(width: 8),
                Text(
                  'Quay lại Danh sách học phần',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.brand(context),
                  ),
                ),
                if (_selectedSubjectCode != null && _selectedSubjectCode!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _selectedSubjectCode!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.brand(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfHigh(context) : const Color(0xFF003D9B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.school_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedSubjectName ?? 'Lớp học phần',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Danh sách các lớp học thuộc học phần ${_selectedSubjectCode ?? ""}. Bạn có thể tạo lớp mới hoặc quản lý sinh viên.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
        ),
      ],
    );

    final actionButton = FilledButton.icon(
      onPressed: _showCreateClassDialog,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Tạo lớp học mới',
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppConstants.brand(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerInfo,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: actionButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: headerInfo),
        const SizedBox(width: 16),
        actionButton,
      ],
    );
  }

  Widget _buildSubjectClassStats(String teacherId) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    Stream<QuerySnapshot> stream;
    if (_selectedSubjectId == '_all') {
      stream = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots();
    } else if (_selectedSubjectId == '_uncategorized') {
      stream = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .where('courseSubjectId', isEqualTo: _selectedSubjectId)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        var classes = snapshot.data?.docs ?? [];
        if (_selectedSubjectId == '_uncategorized') {
          classes = classes.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final subId = data['courseSubjectId'];
            return subId == null || subId.toString().isEmpty;
          }).toList();
        }

        int totalStudents = 0;
        for (var c in classes) {
          final data = c.data() as Map<String, dynamic>;
          totalStudents += (data['studentCount'] as num?)?.toInt() ?? 0;
        }

        final card1 = _buildStatCard(
          title: 'Số lớp học',
          value: '${classes.length}',
          subtitle: 'Lớp học trong học phần này',
          icon: Icons.groups_rounded,
          accentColor: const Color(0xFF003D9B),
          bgColor: const Color(0xFFEFF6FF),
        );

        final card2 = _buildStatCard(
          title: 'Tổng sinh viên',
          value: '$totalStudents',
          subtitle: 'Sinh viên theo học',
          icon: Icons.people_alt_rounded,
          accentColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        );

        final card3 = _buildStatCard(
          title: 'Mã học phần',
          value: _selectedSubjectCode ?? 'TOÀN BỘ',
          subtitle: _selectedSubjectName ?? 'Tất cả lớp học',
          icon: Icons.bookmark_added_rounded,
          accentColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        );

        if (isMobile) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 12),
              card2,
              const SizedBox(height: 12),
              card3,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    final isDark = AppConstants.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.txtMuted(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfHigh(context) : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppConstants.txt(context),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppConstants.txtMuted(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClassGrid(String teacherId) {
    Stream<QuerySnapshot> stream;

    if (_selectedSubjectId == '_all') {
      stream = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (_selectedSubjectId == '_uncategorized') {
      stream = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .where('courseSubjectId', isEqualTo: _selectedSubjectId)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B))),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        var classes = snapshot.data?.docs ?? [];

        if (_selectedSubjectId == '_uncategorized') {
          classes = classes.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final subId = data['courseSubjectId'];
            return subId == null || subId.toString().isEmpty;
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          classes = classes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final className = (data['name'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            final room = (data['room'] ?? '').toString().toLowerCase();
            final period = (data['period'] ?? '').toString().toLowerCase();
            return className.contains(_searchQuery) ||
                description.contains(_searchQuery) ||
                room.contains(_searchQuery) ||
                period.contains(_searchQuery);
          }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;
            final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 1024;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 295,
              ),
              itemCount: classes.length + 1,
              itemBuilder: (context, index) {
                if (index == classes.length) {
                  return _buildCreateNewClassPlaceholder();
                }

                final classDoc = classes[index];
                final data = classDoc.data() as Map<String, dynamic>;
                return _buildClassCard(classDoc.id, data, index);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreateNewClassPlaceholder() {
    final isDark = AppConstants.isDarkMode(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCreateClassDialog,
        borderRadius: BorderRadius.circular(16),
        hoverColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFF1F5F9),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppConstants.border(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            color: AppConstants.surf(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: AppConstants.brand(context), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Tạo lớp học mới',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _selectedSubjectId != null && _selectedSubjectId != '_all' && _selectedSubjectId != '_uncategorized'
                      ? 'Thêm lớp mới cho học phần ${_selectedSubjectCode ?? ""}.'
                      : 'Khởi tạo lớp học phần, phòng học và tiết học mới cho sinh viên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(String classId, Map<String, dynamic> data, int index) {
    final icon = _subjectIcons[index % _subjectIcons.length];
    final className = data['name'] ?? 'Lớp học';
    final description = (data['description'] ?? '').toString().trim();
    final room = (data['room'] ?? '').toString().trim();
    final period = (data['period'] ?? '').toString().trim();
    final studentCount = (data['studentCount'] as num?)?.toInt() ?? 0;
    final quizCount = (data['quizCount'] as num?)?.toInt() ?? 0;
    final subjectCode = data['courseSubjectCode'] as String?;
    final isDark = AppConstants.isDarkMode(context);

    String scheduleText = '';
    if (room.isNotEmpty && period.isNotEmpty) {
      scheduleText = 'Phòng $room • $period';
    } else if (room.isNotEmpty) {
      scheduleText = 'Phòng $room';
    } else if (period.isNotEmpty) {
      scheduleText = period;
    } else {
      scheduleText = 'Chưa có phòng & tiết học';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDetailPage(
                  classId: classId,
                  className: className,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppConstants.brand(context), size: 24),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subjectCode != null && subjectCode.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.brand(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subjectCode,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.brand(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEBECF0),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppConstants.txt(context) : const Color(0xFF42526E),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: AppConstants.surf(context),
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert_rounded, color: AppConstants.txtMuted(context), size: 20),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: AppConstants.brand(context), size: 18),
                                  const SizedBox(width: 10),
                                  Text('Chỉnh sửa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppConstants.txt(context))),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'change_subject',
                              child: Row(
                                children: [
                                  Icon(Icons.drive_file_move_outlined, color: Colors.orange.shade700, size: 18),
                                  const SizedBox(width: 10),
                                  Text('Đổi học phần', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppConstants.txt(context))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                  SizedBox(width: 10),
                                  Text('Xóa lớp', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditClassDialog(classId, data);
                            } else if (value == 'change_subject') {
                              _showChangeClassSubjectDialog(classId, data['courseSubjectId']);
                            } else if (value == 'delete') {
                              _deleteClass(classId, data);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  className,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  description.isNotEmpty ? description : 'Chưa có mô tả',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  scheduleText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: (room.isNotEmpty || period.isNotEmpty) ? FontWeight.w500 : FontWeight.normal,
                    color: AppConstants.txtMuted(context),
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildStatPill(
                      icon: Icons.quiz_outlined,
                      label: '$quizCount bài thi',
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      icon: Icons.group_outlined,
                      label: '$studentCount HS',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailPage(
                            classId: classId,
                            className: className,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.brand(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.txtMuted(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppConstants.txt(context),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIALOGS & ACTIONS
  // ============================================
  void _showCreateClassDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ClassFormDialog(
        title: 'Tạo lớp học mới',
        subtitle: _selectedSubjectId != null && _selectedSubjectId != '_all' && _selectedSubjectId != '_uncategorized'
            ? 'Học phần: ${_selectedSubjectName ?? ""} (${_selectedSubjectCode ?? ""})'
            : 'Điền thông tin lớp học phần và lịch giảng dạy',
        icon: Icons.school_rounded,
        submitText: 'Tạo lớp',
        defaultSubjectId: (_selectedSubjectId == '_all' || _selectedSubjectId == '_uncategorized') ? null : _selectedSubjectId,
        defaultSubjectName: _selectedSubjectName,
        defaultSubjectCode: _selectedSubjectCode,
        onSubmit: (name, description, room, period, subjectId, subjectName, subjectCode) async {
          final teacherId = _auth.currentUser?.uid ?? '';
          final classData = <String, dynamic>{
            'name': name,
            'description': description,
            'room': room,
            'period': period,
            'teacherId': teacherId,
            'studentCount': 0,
            'quizCount': 0,
            'averageScore': 0,
            'createdAt': FieldValue.serverTimestamp(),
          };

          if (subjectId != null && subjectId.isNotEmpty) {
            classData['courseSubjectId'] = subjectId;
            classData['courseSubjectName'] = subjectName;
            classData['courseSubjectCode'] = subjectCode;
          }

          await FirebaseFirestore.instance.collection('classes').add(classData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Tạo lớp học thành công!'),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditClassDialog(String classId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ClassFormDialog(
        title: 'Chỉnh sửa lớp học',
        subtitle: 'Cập nhật thông tin lớp, phòng học và tiết học',
        icon: Icons.edit_note_rounded,
        submitText: 'Lưu thay đổi',
        initialName: data['name'] ?? '',
        initialDescription: data['description'] ?? '',
        initialRoom: data['room'] ?? '',
        initialPeriod: data['period'] ?? '',
        defaultSubjectId: data['courseSubjectId'],
        defaultSubjectName: data['courseSubjectName'],
        defaultSubjectCode: data['courseSubjectCode'],
        onSubmit: (name, description, room, period, subjectId, subjectName, subjectCode) async {
          final updateData = <String, dynamic>{
            'name': name,
            'description': description,
            'room': room,
            'period': period,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (subjectId != null && subjectId.isNotEmpty) {
            updateData['courseSubjectId'] = subjectId;
            updateData['courseSubjectName'] = subjectName;
            updateData['courseSubjectCode'] = subjectCode;
          } else {
            updateData['courseSubjectId'] = FieldValue.delete();
            updateData['courseSubjectName'] = FieldValue.delete();
            updateData['courseSubjectCode'] = FieldValue.delete();
          }

          await FirebaseFirestore.instance.collection('classes').doc(classId).update(updateData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Cập nhật lớp học thành công!'),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  void _showChangeClassSubjectDialog(String classId, String? currentSubjectId) {
    final uid = _auth.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (dialogCtx) => FutureBuilder<List<QueryDocumentSnapshot>>(
        future: CourseSubjectService.getSubjects(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snapshot.data!;

          return AlertDialog(
            backgroundColor: AppConstants.surf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppConstants.border(context)),
            ),
            title: Row(
              children: [
                Icon(Icons.drive_file_move_outlined, color: AppConstants.brand(context)),
                const SizedBox(width: 10),
                Text('Chuyển lớp sang Lớp học phần khác', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppConstants.txt(context), fontSize: 17)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Lớp học chung (Chưa phân loại)'),
                    subtitle: const Text('Gỡ lớp khỏi học phần hiện tại'),
                    leading: const Icon(Icons.folder_off_outlined),
                    selected: currentSubjectId == null || currentSubjectId.isEmpty,
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      await FirebaseFirestore.instance.collection('classes').doc(classId).update({
                        'courseSubjectId': FieldValue.delete(),
                        'courseSubjectName': FieldValue.delete(),
                        'courseSubjectCode': FieldValue.delete(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã chuyển lớp thành lớp chưa phân loại')),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ...subjects.map((subDoc) {
                    final data = subDoc.data() as Map<String, dynamic>;
                    final isCur = subDoc.id == currentSubjectId;
                    return ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text('Mã: ${data['code']}'),
                      leading: Icon(Icons.bookmark_border_rounded, color: isCur ? AppConstants.brand(context) : null),
                      trailing: isCur ? const Icon(Icons.check, color: Color(0xFF16A34A)) : null,
                      onTap: () async {
                        Navigator.pop(dialogCtx);
                        await CourseSubjectService.assignClassToSubject(
                          classId: classId,
                          subjectId: subDoc.id,
                          subjectName: data['name'] ?? '',
                          subjectCode: data['code'] ?? '',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã chuyển lớp sang học phần ${data['name']}')),
                          );
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteClass(String classId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = AppConstants.isDarkMode(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppConstants.surf(context),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppConstants.surf(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Xóa lớp học?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có chắc chắn muốn xóa lớp "${data['name'] ?? 'Lớp học'}" không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lưu ý quan trọng:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Xóa toàn bộ sinh viên đã tham gia lớp\n• Xóa các bài thi thuộc lớp này\n• Hành động này không thể hoàn tác!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isDark ? AppConstants.txtMuted(context) : const Color(0xFF9A3412),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppConstants.border(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Xóa lớp', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      final studentsSnapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('students').get();
      for (var doc in studentsSnapshot.docs) {
        await doc.reference.delete();
      }

      final quizzesSnapshot = await FirebaseFirestore.instance.collection('classes').doc(classId).collection('quizzes').get();
      for (var doc in quizzesSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance.collection('classes').doc(classId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa lớp học thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi khi xóa: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showCreateOrEditSubjectDialog([String? subjectId, Map<String, dynamic>? initialData]) {
    final isEditing = subjectId != null;
    final nameCtrl = TextEditingController(text: initialData?['name'] ?? '');
    final codeCtrl = TextEditingController(text: initialData?['code'] ?? '');
    final descCtrl = TextEditingController(text: initialData?['description'] ?? '');
    String selectedColor = initialData?['colorHex'] ?? '#003D9B';
    final formKey = GlobalKey<FormState>();

    final colors = [
      '#003D9B',
      '#0284C7',
      '#16A34A',
      '#D97706',
      '#9333EA',
      '#E11D48',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppConstants.surf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppConstants.border(context)),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.add_to_photos_rounded,
                color: AppConstants.brand(context),
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Chỉnh sửa Lớp học phần' : 'Thêm Lớp học phần mới',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppConstants.txt(context), fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tên lớp học phần *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Kỹ thuật phần mềm, TOEIC 450+...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên học phần' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Mã học phần *', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: SE101, TOEIC, CS202...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã học phần' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Mô tả (tùy chọn)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Mô tả tóm tắt về học phần...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Màu đại diện', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
                    const SizedBox(height: 10),
                    Row(
                      children: colors.map((hex) {
                        final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setDlgState(() => selectedColor = hex),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppConstants.border(context)),
                foregroundColor: AppConstants.txt(context),
              ),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final uid = _auth.currentUser?.uid ?? '';
                try {
                  if (isEditing) {
                    await CourseSubjectService.updateSubject(
                      subjectId: subjectId,
                      name: nameCtrl.text,
                      code: codeCtrl.text,
                      description: descCtrl.text,
                      colorHex: selectedColor,
                    );
                  } else {
                    await CourseSubjectService.createSubject(
                      teacherId: uid,
                      name: nameCtrl.text,
                      code: codeCtrl.text,
                      description: descCtrl.text,
                      colorHex: selectedColor,
                    );
                  }
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Đã cập nhật học phần thành công' : 'Đã thêm học phần mới thành công'),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.brand(context),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo học phần'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubject(String subjectId, String name) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppConstants.surf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.border(context)),
        ),
        title: Text('Xác nhận xóa học phần', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppConstants.txt(context))),
        content: Text(
          'Bạn có chắc chắn muốn xóa học phần "$name" không?\nCác lớp học, đề thi và ngân hàng câu hỏi thuộc học phần này sẽ được chuyển thành "Chưa phân loại" chứ không bị mất.',
          style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context), height: 1.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.border(context)),
              foregroundColor: AppConstants.txt(context),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await CourseSubjectService.deleteSubject(subjectId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã xóa học phần thành công'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa học phần'),
          ),
        ],
      ),
    );
  }
}

class _ClassFormDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String submitText;
  final String initialName;
  final String initialDescription;
  final String initialRoom;
  final String initialPeriod;
  final String? defaultSubjectId;
  final String? defaultSubjectName;
  final String? defaultSubjectCode;
  final Future<void> Function(
    String name,
    String description,
    String room,
    String period,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
  ) onSubmit;

  const _ClassFormDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.submitText,
    this.initialName = '',
    this.initialDescription = '',
    this.initialRoom = '',
    this.initialPeriod = '',
    this.defaultSubjectId,
    this.defaultSubjectName,
    this.defaultSubjectCode,
    required this.onSubmit,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _classNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _roomController;
  late final TextEditingController _periodController;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedSubjectCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _classNameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _roomController = TextEditingController(text: widget.initialRoom);
    _periodController = TextEditingController(text: widget.initialPeriod);
    _selectedSubjectId = widget.defaultSubjectId;
    _selectedSubjectName = widget.defaultSubjectName;
    _selectedSubjectCode = widget.defaultSubjectCode;
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _descriptionController.dispose();
    _roomController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        _classNameController.text.trim(),
        _descriptionController.text.trim(),
        _roomController.text.trim(),
        _periodController.text.trim(),
        _selectedSubjectId,
        _selectedSubjectName,
        _selectedSubjectCode,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);
    final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppConstants.surf(context),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: AppConstants.brand(context), size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.txt(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // LỰA CHỌN LỚP HỌC PHẦN
                FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: CourseSubjectService.getSubjects(teacherId),
                  builder: (context, snap) {
                    final subjects = snap.data ?? [];
                    final bool isSubjectInList = subjects.any((s) => s.id == _selectedSubjectId);
                    final String? dropdownValue = isSubjectInList ? _selectedSubjectId : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thuộc Lớp học phần',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppConstants.surfLow(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppConstants.border(context)),
                          ),
                          child: snap.connectionState == ConnectionState.waiting
                              ? const SizedBox(
                                  height: 48,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    isExpanded: true,
                                    value: dropdownValue,
                                    hint: Text('Chưa phân loại (Lớp chung)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context))),
                                    dropdownColor: AppConstants.surf(context),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Chưa phân loại (Lớp chung)', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                                      ),
                                      ...subjects.map((s) {
                                        final sData = s.data() as Map<String, dynamic>;
                                        return DropdownMenuItem<String?>(
                                          value: s.id,
                                          child: Text('[${sData['code'] ?? ''}] ${sData['name'] ?? ''}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSubjectId = val;
                                        if (val == null) {
                                          _selectedSubjectName = null;
                                          _selectedSubjectCode = null;
                                        } else {
                                          final found = subjects.firstWhere((s) => s.id == val);
                                          final fData = found.data() as Map<String, dynamic>;
                                          _selectedSubjectName = fData['name'];
                                          _selectedSubjectCode = fData['code'];
                                        }
                                      });
                                    },
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                // Class Name
                TextFormField(
                  controller: _classNameController,
                  style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                  decoration: InputDecoration(
                    labelText: 'Tên lớp học *',
                    labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    hintText: 'VD: 22KTMT1, Lớp Sáng T4, Nhóm 2...',
                    hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    prefixIcon: Icon(Icons.class_rounded, color: AppConstants.txtMuted(context)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                    filled: true,
                    fillColor: AppConstants.surfLow(context),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên lớp học';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description / Class Code
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                  decoration: InputDecoration(
                    labelText: 'Mô tả / Mã lớp',
                    labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    hintText: 'VD: Lớp học phần 22N44, Học kỳ 1...',
                    hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    prefixIcon: Icon(Icons.badge_outlined, color: AppConstants.txtMuted(context)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                    filled: true,
                    fillColor: AppConstants.surfLow(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Room & Period in Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roomController,
                        style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                        decoration: InputDecoration(
                          labelText: 'Phòng học',
                          labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                          hintText: 'VD: F.302, A205...',
                          hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                          prefixIcon: Icon(Icons.meeting_room_outlined, color: AppConstants.txtMuted(context)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                          filled: true,
                          fillColor: AppConstants.surfLow(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _periodController,
                        style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                        decoration: InputDecoration(
                          labelText: 'Tiết học',
                          labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                          hintText: 'VD: T3 8-10, Tiết 1-3...',
                          hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                          prefixIcon: Icon(Icons.schedule_rounded, color: AppConstants.txtMuted(context)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                          filled: true,
                          fillColor: AppConstants.surfLow(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppConstants.border(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Hủy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConstants.brand(context),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(widget.submitText, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
