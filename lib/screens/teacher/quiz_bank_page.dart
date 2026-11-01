// lib/screens/teacher/quiz_bank_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'class_create_quiz_page.dart';
import 'edit_quiz_page.dart';
import 'class_quiz_detail_page.dart';
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
                    _buildPageHeader(),
                    const SizedBox(height: 28),
                    _buildFilterRow(),
                    const SizedBox(height: 24),
                    _buildQuizGrid(),
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
          hintText: 'Tìm kiếm đề thi...',
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
                // Nav links
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
                // Actions
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Thông báo',
                      onPressed: () {},
                      icon: Icon(Icons.notifications_none_rounded, color: AppConstants.txtMuted(context)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Tài khoản',
                      onPressed: () {},
                      icon: Icon(Icons.account_circle_outlined, color: AppConstants.txtMuted(context)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageHeader() {
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
              child: Icon(Icons.library_books_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kho đề thi',
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
          'Quản lý và tổ chức kho đề thi trực tuyến một cách hiệu quả.',
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
          MaterialPageRoute(builder: (context) => const ClassCreateQuizPage()),
        );
      },
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
              padding: const EdgeInsets.all(32),
              child: Text('Không tìm thấy đề thi', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txtMuted(context))),
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
                mainAxisExtent: 220,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusTextColor,
                    ),
                  ),
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
                            isAvailable ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                            size: 18,
                            color: const Color(0xFF006C47),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAvailable ? 'Đóng đề thi' : 'Mở đề thi',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
                          ),
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
                  onSelected: (value) async {
                    switch (value) {
                      case 'view':
                        _viewQuizDetails(quizId, data);
                        break;
                      case 'edit':
                        _editQuiz(quizId, data);
                        break;
                      case 'toggle_status':
                        _toggleQuizStatus(quizId, data);
                        break;
                      case 'delete':
                        _deleteQuiz(quizId, data);
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Text(
                data['title'] ?? 'Bài thi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
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
                Icon(Icons.schedule_rounded, size: 16, color: AppConstants.txtMuted(context)),
                const SizedBox(width: 6),
                Text(
                  '${data['duration'] ?? 0} phút • ${data['questionCount'] ?? 0} câu hỏi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.txtMuted(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: AppConstants.border(context)),
            const SizedBox(height: 12),
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
              Text('Đề thi đã được cập nhật'),
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

  Future<void> _toggleQuizStatus(
    String quizId,
    Map<String, dynamic> quizData,
  ) async {
    final currentStatus = quizData['status'] ?? 'available';
    final newStatus = currentStatus == 'available' ? 'archived' : 'available';

    try {
      await FirebaseFirestore.instance.collection('quiz').doc(quizId).update({
        'status': newStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'available' ? Icons.lock_open : Icons.lock,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  newStatus == 'available' ? 'Đã mở đề thi' : 'Đã đóng đề thi',
                ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteQuiz(String quizId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = AppConstants.isDarkMode(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppConstants.surf(context),
          child: Container(
            width: 440,
            constraints: const BoxConstraints(maxWidth: 440),
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
                    color: isDark ? const Color(0xFF4A1010) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xác nhận xóa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn có chắc muốn xóa đề thi "${data['title']}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppConstants.border(context) : const Color(0xFFFFEDD5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hành động này sẽ:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Xóa đề thi vĩnh viễn\n• Xóa tất cả câu hỏi thuộc đề này\n• Không thể hoàn tác!',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      // Delete all questions
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the quiz
      await FirebaseFirestore.instance.collection('quiz').doc(quizId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa đề thi'),
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
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
