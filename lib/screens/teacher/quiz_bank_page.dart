// lib/screens/teacher/quiz_bank_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_create_quiz_page.dart';
import 'quiz_create_from_bank_page.dart';
import 'edit_quiz_page.dart';
import 'class_quiz_detail_page.dart';
import '../../services/course_subject_service.dart';
import '../../utils/constants.dart';

class QuizBankPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const QuizBankPage({super.key, this.onNavigate});

  @override
  State<QuizBankPage> createState() => _QuizBankPageState();
}

class _QuizBankPageState extends State<QuizBankPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  // Điều hướng 2 cấp: null = Danh sách Lớp học phần; '_all' = Tất cả đề thi; ID cụ thể = Đề thi của học phần đó
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
                      const SizedBox(height: 28),
                      _buildSubjectsGrid(),
                    ] else ...[
                      // CẤP 2: DANH SÁCH ĐỀ THI CỦA HỌC PHẦN ĐÃ CHỌN
                      _buildQuizPageHeader(),
                      const SizedBox(height: 24),
                      _buildFilterRow(),
                      const SizedBox(height: 24),
                      _buildQuizGrid(),
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
          hintText: _selectedSubjectId == null ? 'Tìm kiếm học phần...' : 'Tìm kiếm đề thi...',
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
                      onTap: () {
                        setState(() {
                          _selectedSubjectId = null;
                        });
                        widget.onNavigate?.call(1);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                        ),
                        child: Text(
                          'Bài thi',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.brand(context),
                          ),
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
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.txtMuted(context),
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
  // CẤP 1: HEADER & GRID LỚP HỌC PHẦN
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
          'Quản lý đề thi theo từng học phần giảng dạy. Bạn có thể dùng chung đề thi này cho nhiều lớp học.',
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
              _selectedSubjectName = 'Tất cả đề thi';
              _selectedSubjectCode = 'ALL';
            });
          },
          icon: const Icon(Icons.list_alt_rounded, size: 18),
          label: const Text('Xem tất cả đề thi'),
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
                  itemCount: subjects.length + 1, // +1 cho thẻ Chưa phân loại / Đề thi chung
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
          _selectedSubjectName = 'Đề thi chung (Chưa phân loại)';
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
              'Đề thi chung / Chưa phân loại',
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
              'Bao gồm các đề thi chưa được gắn vào học phần cụ thể nào.',
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
                  stream: FirebaseFirestore.instance.collection('quiz').snapshots(),
                  builder: (context, snap) {
                    final allDocs = snap.data?.docs ?? [];
                    final uncategorizedCount = allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final subId = data['courseSubjectId'];
                      return subId == null || subId.toString().isEmpty;
                    }).length;

                    return Text(
                      '$uncategorizedCount đề thi',
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
    final isDark = AppConstants.isDarkMode(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubjectId = subjectId;
          _selectedSubjectName = name;
          _selectedSubjectCode = code;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
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
                    color: AppConstants.brand(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.brand(context).withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.brand(context),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppConstants.txtMuted(context), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD97706)),
                          const SizedBox(width: 10),
                          Text('Chỉnh sửa học phần', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context))),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 10),
                          Text('Xóa học phần', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showCreateOrEditSubjectDialog(
                        subjectId: subjectId,
                        initialName: name,
                        initialCode: code,
                        initialDescription: description,
                      );
                    } else if (val == 'delete') {
                      _confirmDeleteSubject(subjectId, name);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              description.isNotEmpty ? description : 'Học phần giảng dạy và kiểm tra',
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
                      .collection('quiz')
                      .where('courseSubjectId', isEqualTo: subjectId)
                      .snapshots(),
                  builder: (context, snap) {
                    final qCount = snap.data?.docs.length ?? 0;
                    return Text(
                      '$qCount đề thi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.brand(context),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Text(
                      'Xem đề thi',
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

  // ============================================
  // CẤP 2: HEADER & GRID ĐỀ THI TRONG HỌC PHẦN
  // ============================================
  Widget _buildQuizPageHeader() {
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
              child: Icon(Icons.library_books_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedSubjectName ?? 'Đề thi học phần',
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
          'Danh sách các đề thi thuộc học phần ${_selectedSubjectCode ?? ""}. Bạn có thể tạo mới hoặc chỉnh sửa.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppConstants.txtMuted(context),
          ),
        ),
      ],
    );

    final actionButton = FilledButton.icon(
      onPressed: () => _showCreateQuizOptionsDialog(),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Tạo đề thi mới',
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

  /// Dialog chọn phương thức tạo bài thi trong học phần
  void _showCreateQuizOptionsDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.border(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_circle_outline_rounded, color: AppConstants.brand(context), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo bài thi mới',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Học phần: ${_selectedSubjectName ?? "Chung"} (${_selectedSubjectCode ?? "ALL"})',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppConstants.txtMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppConstants.txtMuted(context)),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // TÙY CHỌN 1: TẠO TRỰC TIẾP TỪ FILE / THỦ CÔNG
              InkWell(
                onTap: () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassCreateQuizPage(
                        courseSubjectId: _selectedSubjectId == '_all' || _selectedSubjectId == '_uncategorized'
                            ? null
                            : _selectedSubjectId,
                        courseSubjectName: _selectedSubjectName,
                        courseSubjectCode: _selectedSubjectCode,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: Color(0xFF16A34A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm bài thi trực tiếp từ file / thủ công',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tải lên file câu hỏi (Word, Text) hoặc nhập trực tiếp',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppConstants.txtMuted(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // TÙY CHỌN 2: TẠO TỪ NGÂN HÀNG CÂU HỎI
              InkWell(
                onTap: () {
                  Navigator.pop(dialogCtx);
                  _showSelectBankForSubjectDialog();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xFF7C3AED),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo bài thi từ ngân hàng câu hỏi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sinh đề ngẫu nhiên hoặc chọn câu hỏi từ kho ngân hàng',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppConstants.txtMuted(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hộp thoại chọn ngân hàng câu hỏi để tạo bài thi cho học phần
  void _showSelectBankForSubjectDialog() {
    final searchCtrl = TextEditingController();
    String searchQuery = '';
    bool showOnlyCurrentSubject = _selectedSubjectId != null &&
        _selectedSubjectId != '_all' &&
        _selectedSubjectId != '_uncategorized';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = AppConstants.isDarkMode(context);

          Stream<QuerySnapshot> stream;
          if (showOnlyCurrentSubject) {
            stream = FirebaseFirestore.instance
                .collection('quiz_banks')
                .where('courseSubjectId', isEqualTo: _selectedSubjectId)
                .snapshots();
          } else {
            stream = FirebaseFirestore.instance
                .collection('quiz_banks')
                .orderBy('createdAt', descending: true)
                .snapshots();
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 800,
              height: 620,
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppConstants.border(context)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.surf(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF7C3AED), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chọn ngân hàng câu hỏi',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.txt(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tạo đề thi mới cho học phần ${_selectedSubjectName ?? "Chung"}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppConstants.txtMuted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: AppConstants.txtMuted(context)),
                              onPressed: () => Navigator.pop(dialogCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppConstants.surfLow(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppConstants.border(context)),
                                ),
                                child: TextField(
                                  controller: searchCtrl,
                                  onChanged: (val) {
                                    setDlgState(() {
                                      searchQuery = val.trim().toLowerCase();
                                    });
                                  },
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm theo tên ngân hàng...',
                                    hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                                    prefixIcon: Icon(Icons.search, color: AppConstants.txtMuted(context), size: 20),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedSubjectId != null &&
                                _selectedSubjectId != '_all' &&
                                _selectedSubjectId != '_uncategorized') ...[
                              const SizedBox(width: 12),
                              FilterChip(
                                label: Text(
                                  showOnlyCurrentSubject ? 'Học phần này' : 'Tất cả ngân hàng',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: showOnlyCurrentSubject ? const Color(0xFF7C3AED) : AppConstants.txt(context),
                                  ),
                                ),
                                selected: showOnlyCurrentSubject,
                                onSelected: (val) {
                                  setDlgState(() => showOnlyCurrentSubject = val);
                                },
                                selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // DANH SÁCH NGÂN HÀNG CÂU HỎI
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
                            ),
                          );
                        }

                        var banks = snapshot.data?.docs ?? [];

                        if (searchQuery.isNotEmpty) {
                          banks = banks.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final title = (data['title'] ?? '').toString().toLowerCase();
                            final desc = (data['description'] ?? '').toString().toLowerCase();
                            return title.contains(searchQuery) || desc.contains(searchQuery);
                          }).toList();
                        }

                        if (banks.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open_rounded, size: 48, color: AppConstants.txtMuted(context)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy ngân hàng câu hỏi nào',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.txtMuted(context),
                                    ),
                                  ),
                                  if (showOnlyCurrentSubject) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => setDlgState(() => showOnlyCurrentSubject = false),
                                      child: const Text('Xem tất cả ngân hàng câu hỏi'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: banks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bank = banks[index];
                            final data = bank.data() as Map<String, dynamic>;
                            final title = data['title'] ?? 'Ngân hàng câu hỏi';
                            final count = (data['questionCount'] ?? 0) as int;
                            final desc = data['description'] ?? '';
                            final subjectCode = data['courseSubjectCode'] as String?;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.surfLow(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppConstants.border(context)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.folder_special_rounded,
                                        color: Color(0xFF7C3AED),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.txt(context),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$count câu hỏi',
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF7C3AED),
                                                ),
                                              ),
                                            ),
                                            if (subjectCode != null && subjectCode.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                            if (desc.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  desc,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    color: AppConstants.txtMuted(context),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QuizCreateFromBankPage(
                                            bankId: bank.id,
                                            bankTitle: title,
                                            questionCount: count,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.bolt_rounded, size: 16),
                                    label: const Text(
                                      'Tạo đề',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final sortBtn = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border.all(color: AppConstants.border(context)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sort_rounded, size: 18, color: AppConstants.txtMuted(context)),
          const SizedBox(width: 8),
          Text(
            'Mới nhất',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppConstants.txt(context),
            ),
          ),
        ],
      ),
    );

    final statusChips = SingleChildScrollView(
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

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sortBtn,
          const SizedBox(height: 12),
          statusChips,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        sortBtn,
        statusChips,
      ],
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

  Widget _buildQuizGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B))));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        var quizzes = snapshot.data?.docs ?? [];

        // Lọc theo Lớp học phần đang chọn
        if (_selectedSubjectId != null && _selectedSubjectId != '_all') {
          if (_selectedSubjectId == '_uncategorized') {
            quizzes = quizzes.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final subId = data['courseSubjectId'];
              return subId == null || subId.toString().isEmpty;
            }).toList();
          } else {
            quizzes = quizzes.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['courseSubjectId'] == _selectedSubjectId;
            }).toList();
          }
        }

        if (_searchQuery.isNotEmpty) {
          quizzes = quizzes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery);
          }).toList();
        }

        if (_statusFilter != 'all') {
          quizzes = quizzes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _statusFilter;
          }).toList();
        }

        if (quizzes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: AppConstants.txtMuted(context)),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có đề thi nào trong học phần này',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bấm nút "Tạo đề thi mới" ở trên để thêm đề thi đầu tiên cho học phần.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
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
                mainAxisExtent: 235,
              ),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                final data = quiz.data() as Map<String, dynamic>;
                return _buildQuizCard(quiz.id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuizCard(String quizId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'available';
    final isAvailable = status == 'available';
    final isDark = AppConstants.isDarkMode(context);
    final subjectCode = data['courseSubjectCode']?.toString();

    final Color statusBgColor = isAvailable
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
        : AppConstants.surfLow(context);
    final Color statusTextColor = isAvailable
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
        : AppConstants.txtMuted(context);
    final String statusText = isAvailable ? 'Đang mở' : 'Đã lưu trữ';

    return InkWell(
      onTap: () => _viewQuizDetails(quizId, data),
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: AppConstants.surf(context),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, color: AppConstants.brand(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Xem chi tiết', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context))),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 10),
                          Text('Chỉnh sửa', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'change_subject',
                      child: const Row(
                        children: [
                          Icon(Icons.drive_file_move_outlined, color: Color(0xFF0284C7), size: 18),
                          SizedBox(width: 10),
                          Text('Chuyển Lớp học phần', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 10),
                          Text('Xóa đề thi', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    switch (val) {
                      case 'view':
                        _viewQuizDetails(quizId, data);
                        break;
                      case 'edit':
                        _editQuiz(quizId, data);
                        break;
                      case 'change_subject':
                        _showChangeQuizSubjectDialog(quizId, data);
                        break;
                      case 'delete':
                        _deleteQuiz(quizId, data);
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                data['title'] ?? 'Bài thi',
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: AppConstants.txtMuted(context)),
                const SizedBox(width: 6),
                Text(
                  '${data['duration'] ?? 0} phút • ${data['questionCount'] ?? 0} câu hỏi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppConstants.txtMuted(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: AppConstants.border(context)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tạo: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Chi tiết',
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

  void _viewQuizDetails(
    String quizId,
    Map<String, dynamic> quizData,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassQuizDetailPage(
          quizId: quizId,
          quizData: quizData,
        ),
      ),
    );
  }

  Future<void> _editQuiz(String quizId, Map<String, dynamic> quizData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuizPage(quizId: quizId, quizData: quizData),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Đã cập nhật đề thi thành công'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ============================================
  // DIALOG TẠO / SỬA LỚP HỌC PHẦN
  // ============================================
  Future<void> _showCreateOrEditSubjectDialog({
    String? subjectId,
    String? initialName,
    String? initialCode,
    String? initialDescription,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final codeCtrl = TextEditingController(text: initialCode ?? '');
    final descCtrl = TextEditingController(text: initialDescription ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = subjectId != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surf(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded, color: AppConstants.brand(ctx)),
            const SizedBox(width: 10),
            Text(
              isEdit ? 'Chỉnh sửa Lớp học phần' : 'Thêm Lớp học phần mới',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: AppConstants.txt(ctx), fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên Lớp học phần *',
                    hintText: 'Ví dụ: Kỹ thuật phần mềm, TOEIC, Cơ sở dữ liệu...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên học phần' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mã học phần *',
                    hintText: 'Ví dụ: SE301, ENG102, CS202...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã học phần' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    hintText: 'Ghi chú về học phần...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.brand(ctx)),
            child: Text(isEdit ? 'Lưu thay đổi' : 'Tạo học phần'),
          ),
        ],
      ),
    );

    if (result == true) {
      final uid = _auth.currentUser?.uid ?? '';
      if (isEdit) {
        await CourseSubjectService.updateSubject(
          subjectId: subjectId,
          name: nameCtrl.text,
          code: codeCtrl.text,
          description: descCtrl.text,
        );
      } else {
        await CourseSubjectService.createSubject(
          teacherId: uid,
          name: nameCtrl.text,
          code: codeCtrl.text,
          description: descCtrl.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Đã cập nhật học phần thành công!' : 'Đã tạo Lớp học phần mới thành công!'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    }
  }

  // ============================================
  // XÓA LỚP HỌC PHẦN
  // ============================================
  Future<void> _confirmDeleteSubject(String subjectId, String subjectName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa Lớp học phần?'),
        content: Text(
          'Bạn có chắc muốn xóa học phần "$subjectName"?\n'
          'Các đề thi và ngân hàng câu hỏi thuộc học phần này sẽ chuyển về mục "Chưa phân loại" chứ không bị mất.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Xóa học phần'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CourseSubjectService.deleteSubject(subjectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa Lớp học phần thành công!'),
            backgroundColor: Color(0xFF047857),
          ),
        );
      }
    }
  }

  // ============================================
  // DIALOG CHUYỂN ĐỀ THI SANG HỌC PHẦN KHÁC
  // ============================================
  Future<void> _showChangeQuizSubjectDialog(String quizId, Map<String, dynamic> quizData) async {
    final uid = _auth.currentUser?.uid ?? '';
    final subjects = await CourseSubjectService.getSubjects(uid);

    if (!mounted) return;

    final selected = await showDialog<QueryDocumentSnapshot?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surf(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chuyển đề thi sang Lớp học phần khác', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open_rounded, color: Colors.grey),
                title: const Text('Không gán (Chưa phân loại)'),
                onTap: () => Navigator.pop(ctx, null),
              ),
              const Divider(),
              if (subjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có Lớp học phần nào. Hãy tạo học phần trước.'),
                )
              else
                ...subjects.map((s) {
                  final sData = s.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.school_outlined, color: Color(0xFF003D9B)),
                    title: Text(sData['name'] ?? ''),
                    subtitle: Text('Mã: ${sData['code'] ?? ""}'),
                    onTap: () => Navigator.pop(ctx, s),
                  );
                }),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      final sData = selected.data() as Map<String, dynamic>;
      await CourseSubjectService.assignQuizToSubject(
        quizId: quizId,
        subjectId: selected.id,
        subjectName: sData['name'] ?? '',
        subjectCode: sData['code'] ?? '',
      );
    } else {
      await FirebaseFirestore.instance.collection('quiz').doc(quizId).update({
        'courseSubjectId': FieldValue.delete(),
        'courseSubjectName': FieldValue.delete(),
        'courseSubjectCode': FieldValue.delete(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật Lớp học phần cho đề thi!'), backgroundColor: Color(0xFF047857)),
      );
    }
  }

  // ============================================
  // XÓA ĐỀ THI
  // ============================================
  Future<void> _deleteQuiz(String quizId, Map<String, dynamic> data) async {
    final isDark = AppConstants.isDarkMode(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppConstants.surf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Xác nhận xóa',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.txt(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Bạn có chắc chắn muốn xóa đề thi "${data['title'] ?? 'Bài thi'}"?',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                        child: const Text('Xóa'),
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
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance.collection('quiz').doc(quizId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa đề thi thành công'),
              ],
            ),
            backgroundColor: Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}
