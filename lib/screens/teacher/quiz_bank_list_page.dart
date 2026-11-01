// lib/screens/teacher/quiz_bank_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'class_create_quiz_page.dart';
import 'quiz_create_from_bank_page.dart';
import 'edit_quiz_bank_page.dart';
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quiz_banks')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final banks = snapshot.data?.docs ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(context),
                        const SizedBox(height: 24),
                        _buildBentoStats(banks),
                        const SizedBox(height: 28),
                        _buildBankGrid(snapshot),
                        const SizedBox(height: 48),
                      ],
                    );
                  },
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
          hintText: 'Tìm kiếm ngân hàng câu hỏi...',
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
                      onTap: () => widget.onNavigate?.call(2),
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

  Widget _buildPageHeader(BuildContext context) {
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
              child: Icon(Icons.storage_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ngân hàng câu hỏi',
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
          'Quản lý và tổ chức kho câu hỏi trắc nghiệm của bạn một cách hiệu quả.',
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
            builder: (context) => const ClassCreateQuizPage(isQuestionBank: true),
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

  Widget _buildBentoStats(List<QueryDocumentSnapshot> banks) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    int totalQuestions = 0;
    for (var b in banks) {
      final data = b.data() as Map<String, dynamic>;
      totalQuestions += (data['questionCount'] as num?)?.toInt() ?? 0;
    }

    final card1 = _buildBentoStatCard(
      title: 'Tổng số ngân hàng',
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
      title: 'Trạng thái kho',
      value: 'Khả dụng',
      icon: Icons.check_circle_outline_rounded,
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

  Widget _buildBankGrid(AsyncSnapshot<QuerySnapshot> snapshot) {
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

    if (_searchQuery.isNotEmpty) {
      banks = banks.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery);
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
                'Chưa có ngân hàng câu hỏi nào',
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
            mainAxisExtent: 220,
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
  }

  Widget _buildBankCard(BuildContext context, String id, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Ngân hàng câu hỏi';
    final questionCount = (data['questionCount'] as num?)?.toInt() ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.folder_rounded, color: AppConstants.brand(context), size: 24),
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
}
