// lib/screens/teacher/quiz_bank_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'class_create_quiz_page.dart';
import 'quiz_create_from_bank_page.dart';
import 'edit_quiz_bank_page.dart';
import '../../services/course_subject_service.dart';
import '../../utils/constants.dart';

class QuizBankListPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const QuizBankListPage({super.key, this.onNavigate});

  @override
  State<QuizBankListPage> createState() => _QuizBankListPageState();
}

class _QuizBankListPageState extends State<QuizBankListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  // Điều hướng 2 cấp:
  // null = Danh sách Lớp học phần
  // '_all' = Tất cả ngân hàng câu hỏi
  // '_uncategorized' = Ngân hàng câu hỏi chưa phân loại
  // ID cụ thể = Ngân hàng của học phần đó
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _selectedSubjectCode;
  String? _selectedSubjectColorHex;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      _buildOverallStats(),
                      const SizedBox(height: 28),
                      _buildSubjectsGrid(),
                    ] else ...[
                      // CẤP 2: DANH SÁCH NGÂN HÀNG CÂU HỎI THEO HỌC PHẦN
                      _buildBanksHeader(),
                      const SizedBox(height: 24),
                      _buildSubjectBankStats(),
                      const SizedBox(height: 20),
                      _buildFilterRow(),
                      const SizedBox(height: 24),
                      _buildBankGrid(),
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
          hintText: _selectedSubjectId == null ? 'Tìm kiếm học phần...' : 'Tìm kiếm ngân hàng câu hỏi...',
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
                      onTap: () => widget.onNavigate?.call(0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Quản lý lớp học',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.txtMuted(context),
                          ),
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
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.txtMuted(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSubjectId = null;
                        });
                        widget.onNavigate?.call(2);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                        ),
                        child: Text(
                          'Ngân hàng câu hỏi',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.brand(context),
                          ),
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
          'Quản lý ngân hàng câu hỏi theo từng học phần. Dễ dàng tạo đề thi và dùng chung cho các lớp.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppConstants.txtMuted(context),
          ),
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
              _selectedSubjectName = 'Tất cả ngân hàng câu hỏi';
              _selectedSubjectCode = 'ALL';
            });
          },
          icon: const Icon(Icons.list_alt_rounded, size: 18),
          label: const Text('Xem tất cả ngân hàng'),
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

  Widget _buildOverallStats() {
    final uid = _auth.currentUser?.uid ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quiz_banks').snapshots(),
      builder: (context, bankSnap) {
        final banks = bankSnap.data?.docs ?? [];
        int totalQuestions = 0;
        for (var b in banks) {
          final data = b.data() as Map<String, dynamic>;
          totalQuestions += (data['questionCount'] as num?)?.toInt() ?? 0;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: CourseSubjectService.getSubjectsStream(uid),
          builder: (context, subjSnap) {
            final subjectsCount = subjSnap.data?.docs.length ?? 0;

            final card1 = _buildBentoStatCard(
              title: 'Lớp học phần',
              value: '$subjectsCount',
              icon: Icons.collections_bookmark_rounded,
              iconColor: const Color(0xFF003D9B),
              iconBg: const Color(0xFFEFF6FF),
            );

            final card2 = _buildBentoStatCard(
              title: 'Tổng số ngân hàng',
              value: '${banks.length}',
              icon: Icons.storage_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFF0F9FF),
            );

            final card3 = _buildBentoStatCard(
              title: 'Tổng số câu hỏi',
              value: '$totalQuestions',
              icon: Icons.quiz_outlined,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFECFDF5),
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

  Widget _buildSubjectsGrid() {
    final uid = _auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: CourseSubjectService.getSubjectsStream(uid),
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
                    mainAxisExtent: 210,
                  ),
                  itemCount: subjects.length + 1, // +1 cho thẻ Chưa phân loại / Ngân hàng chung
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildUncategorizedSubjectCard();
                    }
                    final doc = subjects[index - 1];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildSubjectCard(doc.id, data);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUncategorizedSubjectCard() {
    final isDark = AppConstants.isDarkMode(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubjectId = '_uncategorized';
          _selectedSubjectName = 'Ngân hàng chung (Chưa phân loại)';
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
              'Ngân hàng chung / Chưa phân loại',
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
              'Bao gồm các ngân hàng câu hỏi chưa được gán vào học phần cụ thể.',
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
                  stream: FirebaseFirestore.instance.collection('quiz_banks').snapshots(),
                  builder: (context, snap) {
                    final allDocs = snap.data?.docs ?? [];
                    final uncategorizedCount = allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final subId = data['courseSubjectId'];
                      return subId == null || subId.toString().isEmpty;
                    }).length;

                    return Text(
                      '$uncategorizedCount ngân hàng',
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
                      'Mở xem',
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

  Widget _buildSubjectCard(String subjectId, Map<String, dynamic> data) {
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
                      .collection('quiz_banks')
                      .where('courseSubjectId', isEqualTo: subjectId)
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    return Text(
                      '$count ngân hàng câu hỏi',
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
                      'Vào xem',
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
  // CẤP 2: HEADER & STATS & GRID NGÂN HÀNG CÂU HỎI
  // ============================================
  Widget _buildBanksHeader() {
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
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfHigh(context) : const Color(0xFF003D9B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.storage_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedSubjectName ?? 'Ngân hàng câu hỏi',
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
          'Quản lý và tổ chức kho câu hỏi trắc nghiệm của học phần này.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppConstants.txtMuted(context),
          ),
        ),
      ],
    );

    final actionButton = FilledButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassCreateQuizPage(
              isQuestionBank: true,
              courseSubjectId: (_selectedSubjectId == '_all' || _selectedSubjectId == '_uncategorized')
                  ? null
                  : _selectedSubjectId,
              courseSubjectName: _selectedSubjectName,
              courseSubjectCode: _selectedSubjectCode,
            ),
          ),
        );
      },
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Thêm ngân hàng mới',
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

  Widget _buildSubjectBankStats() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    Stream<QuerySnapshot> stream;
    if (_selectedSubjectId == '_all') {
      stream = FirebaseFirestore.instance.collection('quiz_banks').snapshots();
    } else if (_selectedSubjectId == '_uncategorized') {
      stream = FirebaseFirestore.instance.collection('quiz_banks').snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .where('courseSubjectId', isEqualTo: _selectedSubjectId)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        var banks = snapshot.data?.docs ?? [];
        if (_selectedSubjectId == '_uncategorized') {
          banks = banks.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final subId = data['courseSubjectId'];
            return subId == null || subId.toString().isEmpty;
          }).toList();
        }

        int totalQuestions = 0;
        for (var b in banks) {
          final data = b.data() as Map<String, dynamic>;
          totalQuestions += (data['questionCount'] as num?)?.toInt() ?? 0;
        }

        final card1 = _buildBentoStatCard(
          title: 'Số lượng ngân hàng',
          value: '${banks.length}',
          icon: Icons.storage_rounded,
          iconColor: const Color(0xFF003D9B),
          iconBg: const Color(0xFFEFF6FF),
        );

        final card2 = _buildBentoStatCard(
          title: 'Tổng số câu hỏi',
          value: '$totalQuestions',
          icon: Icons.quiz_outlined,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFF0F9FF),
        );

        final card3 = _buildBentoStatCard(
          title: 'Học phần',
          value: _selectedSubjectCode ?? 'TOÀN BỘ',
          icon: Icons.bookmark_added_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFECFDF5),
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

  Widget _buildBentoStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfHigh(context) : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
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

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusChip('Tất cả', _statusFilter == 'all', 'all'),
          const SizedBox(width: 8),
          _buildStatusChip('Đang mở', _statusFilter == 'available', 'available'),
          const SizedBox(width: 8),
          _buildStatusChip('Đã lưu trữ', _statusFilter == 'archived', 'archived'),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isSelected, String value) {
    final isDark = AppConstants.isDarkMode(context);
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF))
              : AppConstants.surf(context),
          border: Border.all(color: isSelected ? AppConstants.brand(context) : AppConstants.border(context)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppConstants.brand(context) : AppConstants.txtMuted(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBankGrid() {
    Stream<QuerySnapshot> stream;

    if (_selectedSubjectId == '_all') {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (_selectedSubjectId == '_uncategorized') {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .where('courseSubjectId', isEqualTo: _selectedSubjectId)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context))),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: TextStyle(color: AppConstants.txt(context))));
        }

        var banks = snapshot.data?.docs ?? [];

        if (_selectedSubjectId == '_uncategorized') {
          banks = banks.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final subId = data['courseSubjectId'];
            return subId == null || subId.toString().isEmpty;
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          banks = banks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery);
          }).toList();
        }

        if (_statusFilter != 'all') {
          banks = banks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'available';
            return status == _statusFilter;
          }).toList();
        }

        if (banks.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.border(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storage_outlined, size: 48, color: AppConstants.txtMuted(context)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ngân hàng câu hỏi nào trong mục này',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txtMuted(context), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1100;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                mainAxisExtent: 230,
              ),
              itemCount: banks.length,
              itemBuilder: (context, index) {
                final bank = banks[index];
                final data = bank.data() as Map<String, dynamic>;
                return _buildBankCard(context, bank.id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBankCard(BuildContext context, String id, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Ngân hàng câu hỏi';
    final questionCount = (data['questionCount'] as num?)?.toInt() ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final subjectCode = data['courseSubjectCode'] as String?;
    final isDark = AppConstants.isDarkMode(context);
    final status = data['status'] ?? 'available';
    final isAvailable = status == 'available';

    final Color statusBgColor = isAvailable
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
        : AppConstants.surfLow(context);
    final Color statusTextColor = isAvailable
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
        : AppConstants.txtMuted(context);
    final String statusText = isAvailable ? 'Đang mở' : 'Đã lưu trữ';

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  if (subjectCode != null && subjectCode.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                  ],
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppConstants.txtMuted(context), size: 20),
                color: AppConstants.surf(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppConstants.border(context)),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditQuizBankPage(bankId: id, bankTitle: title)),
                    );
                  } else if (value == 'toggle_status') {
                    _toggleBankStatus(context, id, data);
                  } else if (value == 'change_subject') {
                    _showChangeSubjectDialog(context, id, data['courseSubjectId']);
                  } else if (value == 'delete') {
                    _deleteBank(context, id, title);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: AppConstants.brand(context), size: 18),
                        const SizedBox(width: 10),
                        Text('Chỉnh sửa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          isAvailable ? Icons.archive_outlined : Icons.unarchive_outlined,
                          color: isAvailable ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isAvailable ? 'Đóng ngân hàng (Lưu trữ)' : 'Mở lại ngân hàng',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: isAvailable ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'change_subject',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_move_outlined, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 10),
                        Text('Đổi học phần', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context))),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 10),
                        Text('Xóa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppConstants.txt(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.quiz_outlined, size: 16, color: AppConstants.txtMuted(context)),
              const SizedBox(width: 6),
              Text(
                '$questionCount câu hỏi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppConstants.txtMuted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text('•', style: TextStyle(color: AppConstants.border(context))),
              const SizedBox(width: 12),
              Text(
                'Tạo: ${createdAt != null ? createdAt.toDate().toString().split(' ')[0] : 'N/A'}',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppConstants.txtMuted(context)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: AppConstants.border(context)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizCreateFromBankPage(
                        bankId: id,
                        bankTitle: title,
                        questionCount: questionCount,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.add_task_rounded, size: 15, color: AppConstants.brand(context)),
                label: Text(
                  'Tạo đề thi',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.brand(context)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE)),
                  backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditQuizBankPage(bankId: id, bankTitle: title)),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: AppConstants.txtMuted(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIALOGS: HỌC PHẦN & ĐỔI HỌC PHẦN
  // ============================================
  void _showCreateOrEditSubjectDialog([String? subjectId, Map<String, dynamic>? initialData]) {
    final isEditing = subjectId != null;
    final nameCtrl = TextEditingController(text: initialData?['name'] ?? '');
    final codeCtrl = TextEditingController(text: initialData?['code'] ?? '');
    final descCtrl = TextEditingController(text: initialData?['description'] ?? '');
    String selectedColor = initialData?['colorHex'] ?? '#003D9B';
    final formKey = GlobalKey<FormState>();

    final colors = [
      '#003D9B', // Brand blue
      '#0284C7', // Sky
      '#16A34A', // Green
      '#D97706', // Amber
      '#9333EA', // Purple
      '#E11D48', // Rose
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
                    Text(
                      'Tên lớp học phần *',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
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
                    Text(
                      'Mã học phần *',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
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
                    Text(
                      'Mô tả (tùy chọn)',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
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
                    Text(
                      'Màu đại diện',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
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
          'Bạn có chắc chắn muốn xóa học phần "$name" không?\nCác đề thi và ngân hàng câu hỏi thuộc học phần này sẽ được chuyển thành "Chưa phân loại" chứ không bị mất.',
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

  void _showChangeSubjectDialog(BuildContext context, String bankId, String? currentSubjectId) {
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
                Text('Chuyển sang Lớp học phần khác', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppConstants.txt(context), fontSize: 17)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Chưa phân loại (Ngân hàng chung)'),
                    subtitle: const Text('Gỡ khỏi học phần hiện tại'),
                    leading: const Icon(Icons.folder_off_outlined),
                    selected: currentSubjectId == null || currentSubjectId.isEmpty,
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      await FirebaseFirestore.instance.collection('quiz_banks').doc(bankId).update({
                        'courseSubjectId': FieldValue.delete(),
                        'courseSubjectName': FieldValue.delete(),
                        'courseSubjectCode': FieldValue.delete(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã chuyển thành ngân hàng chưa phân loại')),
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
                        await CourseSubjectService.assignBankToSubject(
                          bankId: bankId,
                          subjectId: subDoc.id,
                          subjectName: data['name'] ?? '',
                          subjectCode: data['code'] ?? '',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã chuyển sang học phần ${data['name']}')),
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

  void _deleteBank(BuildContext context, String bankId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.border(context)),
        ),
        title: Text('Xác nhận xóa', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppConstants.txt(context))),
        content: Text(
          'Bạn có chắc muốn xóa ngân hàng "$title" và tất cả câu hỏi trong đó không?\nHành động này không thể hoàn tác.',
          style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context), height: 1.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.border(context)),
              foregroundColor: AppConstants.txt(context),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final qs = await FirebaseFirestore.instance.collection('quiz_banks').doc(bankId).collection('questions').get();
                for (var doc in qs.docs) {
                  await doc.reference.delete();
                }
                await FirebaseFirestore.instance.collection('quiz_banks').doc(bankId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã xóa ngân hàng câu hỏi thành công'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBankStatus(
    BuildContext context,
    String bankId,
    Map<String, dynamic> bankData,
  ) async {
    final currentStatus = bankData['status'] ?? 'available';
    final newStatus = currentStatus == 'available' ? 'archived' : 'available';

    try {
      await FirebaseFirestore.instance.collection('quiz_banks').doc(bankId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'available' ? Icons.check_circle : Icons.archive,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  newStatus == 'available'
                      ? 'Đã mở lại ngân hàng câu hỏi'
                      : 'Đã đóng ngân hàng câu hỏi và chuyển vào lưu trữ',
                ),
              ],
            ),
            backgroundColor: newStatus == 'available' ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
