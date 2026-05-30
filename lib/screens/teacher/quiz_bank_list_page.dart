// lib/screens/teacher/quiz_bank_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_quiz_bank_page.dart';

class QuizBankListPage extends StatelessWidget {
  const QuizBankListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          _buildTopAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(context),
                    const SizedBox(height: 32),
                    _buildQuickFilters(),
                    const SizedBox(height: 24),
                    _buildDashboardStats(),
                    const SizedBox(height: 32),
                    _buildBankGrid(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF).withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: Color(0xFFC3C6D6))),
      ),
      child: Row(
        children: [
          // Search Bar
          Container(
            width: 256,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search question banks...',
                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF434654), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Nav links
          Row(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF003D9B), width: 2))),
                child: const Text('Question Bank', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003D9B))),
              ),
            ],
          ),
          const Spacer(),
          // Actions
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF434654))),
              IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF434654))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Question Bank Central', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF041B3C), letterSpacing: -0.5)),
            SizedBox(height: 8),
            Text('Organize and curate your repository of quiz questions.', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
          ],
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/question_bank_create'),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text('Add New Bank', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF003D9B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Row(
      children: [
        _buildFilterChip('All Topics', true),
        const SizedBox(width: 12),
        _buildFilterChip('Science', false),
        const SizedBox(width: 12),
        _buildFilterChip('Math', false),
        const SizedBox(width: 12),
        _buildFilterChip('History', false),
        const SizedBox(width: 12),
        _buildFilterChip('Literature', false),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE0E8FF) : Colors.white,
        border: Border.all(color: isSelected ? const Color(0xFF003D9B) : const Color(0xFFC3C6D6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF003D9B) : const Color(0xFF434654),
        ),
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Banks', '14'),
          Container(width: 1, height: 40, color: const Color(0xFFC3C6D6)),
          _buildStatItem('Total Questions', '1,248'),
          Container(width: 1, height: 40, color: const Color(0xFFC3C6D6)),
          _buildStatItem('Recent Adds', '50 (This week)'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003D9B))),
      ],
    );
  }

  Widget _buildBankGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_banks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B))));
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi tải dữ liệu'));
        }

        final banks = snapshot.data?.docs ?? [];

        if (banks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Chưa có ngân hàng câu hỏi nào', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: isMobile ? 1.5 : 1.3,
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
    final title = data['title'] ?? 'Ngân hàng';
    final questionCount = data['questionCount'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_rounded, color: Color(0xFF003D9B), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF041B3C)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF434654)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditQuizBankPage(bankId: id, bankTitle: title)));
                  } else if (value == 'delete') {
                    _deleteBank(context, id, title);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_rounded, color: Color(0xFF003D9B), size: 20), SizedBox(width: 12), Text('Chỉnh sửa')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_rounded, color: Color(0xFFBA1A1A), size: 20), SizedBox(width: 12), Text('Xóa', style: TextStyle(color: Color(0xFFBA1A1A)))]),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text('$questionCount Questions', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF041B3C))),
          const SizedBox(height: 4),
          Text(
            'Created: ${createdAt != null ? createdAt.toDate().toString().split(' ')[0] : 'N/A'}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF434654)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/quiz_create_from_bank',
                    arguments: {
                      'bankId': id,
                      'bankTitle': title,
                      'questionCount': questionCount,
                    },
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF003D9B)),
                  foregroundColor: const Color(0xFF003D9B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Browse', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditQuizBankPage(bankId: id, bankTitle: title)));
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF003D9B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit Bank', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold)),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: Color(0xFF041B3C))),
        content: Text('Bạn có chắc muốn xóa ngân hàng "$title" và tất cả câu hỏi trong đó không?\nHành động này không thể hoàn tác.', style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF434654)),
            child: const Text('Hủy', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete questions
                final qs = await FirebaseFirestore.instance.collection('quiz_banks').doc(bankId).collection('questions').get();
                for (var doc in qs.docs) {
                  await doc.reference.delete();
                }
                // Delete bank
                await FirebaseFirestore.instance.collection('quiz_banks').doc(bankId).delete();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa ngân hàng câu hỏi')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
            child: const Text('Xóa', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
