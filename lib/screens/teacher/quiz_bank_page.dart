// lib/screens/teacher/quiz_bank_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_bank_create_page.dart';
import 'edit_quiz_page.dart';

class QuizBankPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const QuizBankPage({Key? key, this.onNavigate}) : super(key: key);

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
                    _buildPageHeader(),
                    const SizedBox(height: 32),
                    _buildFilterRow(),
                    const SizedBox(height: 24),
                    _buildQuizGrid(),
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
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search exams...',
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
              InkWell(
                onTap: () => widget.onNavigate?.call(0),
                child: const Text('Class Management', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () => widget.onNavigate?.call(1),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF003D9B), width: 2))),
                  child: const Text('Exam Library', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003D9B))),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Actions
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizBankCreatePage()));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF003D9B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Upload Exam', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 32, color: const Color(0xFFC3C6D6)),
              const SizedBox(width: 16),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF434654))),
              IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF434654))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Exam Library', style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF041B3C), letterSpacing: -0.5)),
        SizedBox(height: 8),
        Text('Manage and organize your assessment materials efficiently.', style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: Color(0xFF434654))),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3FF),
                border: Border.all(color: const Color(0xFFC3C6D6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: const Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF003D9B)),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.list_rounded, size: 20, color: Color(0xFF434654)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC3C6D6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text('Newest First', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF434654))),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF434654)),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildStatusChip('All', _statusFilter == 'all', 'all'),
            const SizedBox(width: 8),
            _buildStatusChip('Available', _statusFilter == 'available', 'available'),
            const SizedBox(width: 8),
            _buildStatusChip('Archived', _statusFilter == 'archived', 'archived'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isSelected, String value) {
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0E8FF) : Colors.transparent,
          border: isSelected ? Border.all(color: const Color(0xFF003D9B)) : Border.all(color: Colors.transparent),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không tìm thấy đề thi', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final crossAxisCount = isMobile ? 1 : 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: isMobile ? 1.5 : 1.1,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, color: Color(0xFF003D9B), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF041B3C)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tạo ngày: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF434654)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF434654)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [Icon(Icons.visibility_rounded, color: Color(0xFF003D9B), size: 20), SizedBox(width: 12), Text('Xem chi tiết')]),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_rounded, color: Color(0xFF003D9B), size: 20), SizedBox(width: 12), Text('Chỉnh sửa')]),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(isAvailable ? Icons.lock_rounded : Icons.lock_open_rounded, size: 20, color: const Color(0xFF006C47)),
                        const SizedBox(width: 12),
                        Text(isAvailable ? 'Đóng đề thi' : 'Mở đề thi'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_rounded, color: Color(0xFFBA1A1A), size: 20), SizedBox(width: 12), Text('Xóa', style: TextStyle(color: Color(0xFFBA1A1A)))]),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? const Color(0xFF82F9BE) : const Color(0xFFF1F3FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAvailable ? 'AVAILABLE' : 'DRAFT',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: isAvailable ? const Color(0xFF006C47) : const Color(0xFF434654)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(4)),
                child: Text('${data['questionCount'] ?? 0} Qs', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF434654))),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(4)),
                child: Text('${data['duration'] ?? 0} mins', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF434654))),
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: Color(0xFFC3C6D6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: const Color(0xFF003D9B), child: const Text('T', style: TextStyle(color: Colors.white, fontSize: 10))),
                  const SizedBox(width: 8),
                  const Text('Giáo viên', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF041B3C), fontWeight: FontWeight.w500)),
                ],
              ),
              TextButton(
                onPressed: () {
                  _editQuiz(quizId, data);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF003D9B),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Edit Exam', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _viewQuizDetails(
    String quizId,
    Map<String, dynamic> quizData,
  ) async {
    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quizData['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quizData['questionCount']} câu hỏi',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quizData['duration']} phút',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: questionsSnapshot.docs.length,
                  itemBuilder: (context, index) {
                    final question = questionsSnapshot.docs[index].data();
                    final options = List<String>.from(
                      question['options'] ?? [],
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.purple.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Câu ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              question['question'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...options.asMap().entries.map((entry) {
                              final letter = String.fromCharCode(
                                65 + entry.key,
                              );
                              // Logic MỚI: Hỗ trợ cả String và List
                              bool isCorrect = false;
                              final rawCorrect = question['correctAnswer'];
                              if (rawCorrect is List) {
                                // Nếu là danh sách (VD: ['A', 'B'])
                                isCorrect = rawCorrect
                                    .map((e) => e.toString())
                                    .contains(letter);
                              } else {
                                // Nếu là đơn (VD: 'A')
                                isCorrect = rawCorrect.toString() == letter;
                              }
                              // ---------------------------------------

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.shade50
                                      : Colors.grey.shade50,
                                  border: Border.all(
                                    color: isCorrect
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    width: isCorrect ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.grey.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(entry.value)),
                                    if (isCorrect)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade700,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác nhận xóa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc muốn xóa đề thi "${data['title']}"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hành động này sẽ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Xóa đề thi\n'
                      '• Xóa tất cả câu hỏi\n'
                      '• Không thể hoàn tác!',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        height: 1.6,
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontSize: 16,
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
      ),
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
