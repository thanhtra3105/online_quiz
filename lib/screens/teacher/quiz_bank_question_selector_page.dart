// lib/screens/teacher/quiz_bank_question_selector_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizBankQuestionSelectorPage extends StatefulWidget {
  final String bankId;
  final String bankTitle;
  final String quizTitle;
  final int duration;
  final int maxViolations;

  const QuizBankQuestionSelectorPage({
    Key? key,
    required this.bankId,
    required this.bankTitle,
    required this.quizTitle,
    required this.duration,
    required this.maxViolations,
  }) : super(key: key);

  @override
  State<QuizBankQuestionSelectorPage> createState() =>
      _QuizBankQuestionSelectorPageState();
}

class _QuizBankQuestionSelectorPageState
    extends State<QuizBankQuestionSelectorPage> {
  final Set<String> _selectedQuestionIds = {};
  bool _isCreating = false;
  List<QueryDocumentSnapshot>? _questions;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quiz_banks')
        .doc(widget.bankId)
        .collection('questions')
        .get();

    setState(() {
      _questions = snapshot.docs;
    });
  }

  void _toggleSelection(String questionId) {
    setState(() {
      if (_selectedQuestionIds.contains(questionId)) {
        _selectedQuestionIds.remove(questionId);
      } else {
        _selectedQuestionIds.add(questionId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_questions != null) {
        _selectedQuestionIds.addAll(_questions!.map((q) => q.id));
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedQuestionIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white, Colors.teal.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn câu hỏi',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.bankTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selection counter & actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Đã chọn: ${_selectedQuestionIds.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                if (_questions != null)
                                  Text(
                                    ' / ${_questions!.length}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _selectAll,
                            child: const Text('Chọn tất cả'),
                          ),
                          TextButton(
                            onPressed: _deselectAll,
                            child: const Text('Bỏ chọn'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Questions List
              Expanded(
                child: _questions == null
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade600,
                          ),
                        ),
                      )
                    : _questions!.isEmpty
                    ? const Center(child: Text('Không có câu hỏi nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _questions!.length,
                        itemBuilder: (context, index) {
                          final questionDoc = _questions![index];
                          final data =
                              questionDoc.data() as Map<String, dynamic>;
                          final questionId = questionDoc.id;
                          final isSelected = _selectedQuestionIds.contains(
                            questionId,
                          );
                          final options = data['options'] as List;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green.shade400
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _toggleSelection(questionId),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.green.shade600
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.green.shade600
                                                : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 18,
                                              )
                                            : null,
                                      ),

                                      const SizedBox(width: 16),

                                      // Question content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Question number & text
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Câu ${index + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    data['question'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            // Options preview
                                            // 1. Lấy danh sách options ra biến riêng để đếm số lượng
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              // 2. SỬA QUAN TRỌNG: Dùng options.length thay vì số 4 cố định
                                              children: List.generate(options.length, (
                                                i,
                                              ) {
                                                final letter =
                                                    String.fromCharCode(65 + i);

                                                // 3. SỬA QUAN TRỌNG: Logic kiểm tra đáp án đúng (Hỗ trợ cả List và String)
                                                bool isCorrect = false;
                                                final rawCorrect =
                                                    data['correctAnswer'];

                                                if (rawCorrect is List) {
                                                  // Nếu đáp án là danh sách (ví dụ ['A', 'C'])
                                                  isCorrect = rawCorrect
                                                      .map((e) => e.toString())
                                                      .contains(letter);
                                                } else {
                                                  // Nếu đáp án là đơn (ví dụ 'A')
                                                  isCorrect =
                                                      rawCorrect.toString() ==
                                                      letter;
                                                }

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isCorrect
                                                        ? Colors.green.shade100
                                                        : Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    // Thêm viền xanh nếu đúng để dễ nhìn hơn
                                                    border: isCorrect
                                                        ? Border.all(
                                                            color: Colors
                                                                .green
                                                                .shade300,
                                                            width: 1,
                                                          )
                                                        : null,
                                                  ),
                                                  child: Text(
                                                    // Cắt bớt nội dung nếu quá dài (trên 20 ký tự)
                                                    '$letter. ${options[i].toString().length > 20 ? options[i].toString().substring(0, 20) + "..." : options[i]}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isCorrect
                                                          ? Colors
                                                                .green
                                                                .shade800
                                                          : Colors.grey[700],
                                                      fontWeight: isCorrect
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _selectedQuestionIds.isEmpty || _isCreating
                          ? null
                          : _createQuiz,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isCreating
                            ? 'Đang tạo...'
                            : 'Tạo đề thi (${_selectedQuestionIds.length} câu)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createQuiz() async {
    setState(() => _isCreating = true);

    try {
      // Create quiz
      final quizRef = await FirebaseFirestore.instance.collection('quiz').add({
        'title': widget.quizTitle,
        'bankId': widget.bankId,
        'selectionMode': 'manual',
        'questionCount': _selectedQuestionIds.length,
        'duration': widget.duration,
        'maxSuspiciousActions': widget.maxViolations,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add selected questions to quiz
      for (var questionId in _selectedQuestionIds) {
        final questionDoc = _questions!.firstWhere((q) => q.id == questionId);
        await quizRef
            .collection('questions')
            .add(questionDoc.data() as Map<String, dynamic>);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ Đã tạo đề với ${_selectedQuestionIds.length} câu hỏi!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );

        // Pop back to quiz bank list
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
