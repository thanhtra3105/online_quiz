// lib/screens/teacher/quiz_bank_question_selector_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/question_image_view.dart';

class QuizBankQuestionSelectorPage extends StatefulWidget {
  final String bankId;
  final String bankTitle;
  final String quizTitle;
  final int duration;
  final int maxViolations;
  final String? targetClassId;
  final String? targetClassName;

  const QuizBankQuestionSelectorPage({
    super.key,
    required this.bankId,
    required this.bankTitle,
    required this.quizTitle,
    required this.duration,
    required this.maxViolations,
    this.targetClassId,
    this.targetClassName,
  });

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP APP BAR ──────────────────────────────────────
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // App Brand
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003D9B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý phòng thi',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'EduQuiz System',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Container(
                    height: 28,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 16),

                  // Breadcrumbs
                  Tooltip(
                    message: 'Quay lại cấu hình đề thi',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Text(
                              'Cấu hình đề',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFF003D9B), width: 2.5)),
                    ),
                    child: const Text(
                      'Tự chọn câu hỏi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D9B),
                      ),
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    tooltip: 'Thông báo',
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF003D9B),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // ─── CONTROL HEADER ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.checklist_rounded,
                          color: Color(0xFF003D9B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đề thi: ${widget.quizTitle}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nguồn: ${widget.bankTitle} • ${_questions?.length ?? 0} câu hỏi khả dụng',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selection badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          'Đã chọn: ${_selectedQuestionIds.length} / ${_questions?.length ?? 0}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D9B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Bulk actions
                      TextButton.icon(
                        onPressed: _selectAll,
                        icon: const Icon(Icons.select_all_rounded, size: 16, color: Color(0xFF003D9B)),
                        label: const Text(
                          'Chọn tất cả',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003D9B),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _deselectAll,
                        icon: const Icon(Icons.deselect_rounded, size: 16, color: Color(0xFF64748B)),
                        label: const Text(
                          'Bỏ chọn',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── QUESTIONS LIST ───────────────────────────────────
            Expanded(
              child: _questions == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B)),
                      ),
                    )
                  : _questions!.isEmpty
                      ? const Center(
                          child: Text(
                            'Ngân hàng này hiện chưa có câu hỏi nào.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 960),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              itemCount: _questions!.length,
                              itemBuilder: (context, index) {
                                final questionDoc = _questions![index];
                                final data = questionDoc.data() as Map<String, dynamic>;
                                final questionId = questionDoc.id;
                                final isSelected = _selectedQuestionIds.contains(questionId);
                                final options = data['options'] as List? ?? [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF003D9B)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        const BoxShadow(
                                          color: Color.fromRGBO(0, 61, 155, 0.06),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        )
                                      else
                                        const BoxShadow(
                                          color: Color(0x04000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _toggleSelection(questionId),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Checkbox box
                                            Container(
                                              width: 24,
                                              height: 24,
                                              margin: const EdgeInsets.only(top: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? const Color(0xFF003D9B)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xFF003D9B)
                                                      : const Color(0xFFCBD5E1),
                                                  width: 1.8,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),

                                            // Content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEFF6FF),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          'Câu ${index + 1}',
                                                          style: const TextStyle(
                                                            fontFamily: 'Inter',
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF003D9B),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          data['question'] ?? '',
                                                          style: const TextStyle(
                                                            fontFamily: 'Inter',
                                                            fontSize: 14.5,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF0F172A),
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  () {
                                                    List<String> imgs = [];
                                                    if (data['imageUrls'] is List) {
                                                      imgs = (data['imageUrls'] as List)
                                                          .map((e) => e.toString().trim())
                                                          .where((e) => e.isNotEmpty)
                                                          .toList();
                                                    } else if (data['imageUrl'] != null &&
                                                        data['imageUrl'].toString().trim().isNotEmpty) {
                                                      imgs = [data['imageUrl'].toString().trim()];
                                                    }
                                                    if (imgs.isNotEmpty) {
                                                      return QuestionImageView(
                                                        imageUrls: imgs,
                                                        maxHeight: 180,
                                                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                                                      );
                                                    }
                                                    return const SizedBox.shrink();
                                                  }(),
                                                  const SizedBox(height: 12),

                                                  // Options Preview
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 6,
                                                    children: List.generate(options.length, (i) {
                                                      final letter = String.fromCharCode(65 + i);
                                                      bool isCorrect = false;
                                                      final rawCorrect = data['correctAnswer'];

                                                      if (rawCorrect is List) {
                                                        isCorrect = rawCorrect
                                                            .map((e) => e.toString())
                                                            .contains(letter);
                                                      } else {
                                                        isCorrect = rawCorrect.toString() == letter;
                                                      }

                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isCorrect
                                                              ? const Color(0xFFDCFCE7)
                                                              : const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: isCorrect
                                                              ? Border.all(color: const Color(0xFF86EFAC))
                                                              : Border.all(color: const Color(0xFFE2E8F0)),
                                                        ),
                                                        child: Text(
                                                          '$letter. ${options[i].toString().length > 30 ? '${options[i].toString().substring(0, 30)}...' : options[i]}',
                                                          style: TextStyle(
                                                            fontFamily: 'Inter',
                                                            fontSize: 12,
                                                            color: isCorrect
                                                                ? const Color(0xFF166534)
                                                                : const Color(0xFF334155),
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
                        ),
            ),

            // ─── BOTTOM ACTION BAR ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isCreating ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Quay lại',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: _selectedQuestionIds.isEmpty || _isCreating ? null : _createQuiz,
                        icon: _isCreating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          _isCreating
                              ? 'Đang tạo đề...'
                              : 'Hoàn tất tạo đề (${_selectedQuestionIds.length} câu)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003D9B),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

      // If targetClassId is provided, also attach to the class!
      if (widget.targetClassId != null && widget.targetClassId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.targetClassId!)
            .collection('quizzes')
            .doc(quizRef.id)
            .set({
              'title': widget.quizTitle,
              'questionCount': _selectedQuestionIds.length,
              'duration': widget.duration,
              'assignedAt': FieldValue.serverTimestamp(),
            });

        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.targetClassId!)
            .get();
        final currentCount = (classDoc.data()?['quizCount'] ?? 0) as int;

        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.targetClassId!)
            .update({'quizCount': currentCount + 1});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.targetClassId != null
                    ? 'Đã tạo đề thi từ ngân hàng và thêm vào lớp thành công!'
                    : 'Đã tạo đề thi thành công với ${_selectedQuestionIds.length} câu hỏi!'),
              ],
            ),
            backgroundColor: const Color(0xFF003D9B),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.targetClassId != null && widget.targetClassId!.isNotEmpty) {
          Navigator.of(context).pop(true);
        } else {
          // Pop back to quiz bank list
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
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
