// lib/screens/teacher/quiz_create_from_bank_page.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'quiz_bank_question_selector_page.dart';

class QuizCreateFromBankPage extends StatefulWidget {
  final String bankId;
  final String bankTitle;
  final int questionCount;
  final String? targetClassId;
  final String? targetClassName;

  const QuizCreateFromBankPage({
    super.key,
    required this.bankId,
    required this.bankTitle,
    required this.questionCount,
    this.targetClassId,
    this.targetClassName,
  });

  @override
  State<QuizCreateFromBankPage> createState() => _QuizCreateFromBankPageState();
}

class _QuizCreateFromBankPageState extends State<QuizCreateFromBankPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _maxViolationsController = TextEditingController(text: '5');
  final _questionCountController = TextEditingController();

  String _selectedMode = 'random'; // 'random' or 'manual'
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Default question count: 10 or bank size
    if (widget.questionCount > 0) {
      _questionCountController.text = min(10, widget.questionCount).toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxViolationsController.dispose();
    _questionCountController.dispose();
    super.dispose();
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
                    message: widget.targetClassName != null ? 'Quay lại lớp học' : 'Quay lại Ngân hàng câu hỏi',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              widget.targetClassName ?? 'Ngân hàng câu hỏi',
                              style: const TextStyle(
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
                      'Tạo đề thi mới',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D9B),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Actions on right
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

            // ─── MAIN CONTENT ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page Header Banner
                          _buildPageHeader(),
                          const SizedBox(height: 20),

                          // Bank Info Card
                          _buildBankInfoCard(),
                          const SizedBox(height: 24),

                          // Mode Selector
                          _buildModeSelector(),
                          const SizedBox(height: 24),

                          // Form Configuration Card
                          _buildConfigCard(),
                          const SizedBox(height: 32),

                          // Action Buttons
                          _buildActionButtons(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF003D9B),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo đề thi mới từ ngân hàng',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nguồn: ${widget.bankTitle} • Có sẵn ${widget.questionCount} câu hỏi',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              if (widget.targetClassName != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      Text(
                        'Thêm trực tiếp vào lớp: ${widget.targetClassName}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF003D9B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bankTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kho ngân hàng câu hỏi trắc nghiệm đã được kiểm duyệt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline_rounded, size: 15, color: Color(0xFF003D9B)),
                const SizedBox(width: 6),
                Text(
                  '${widget.questionCount} câu hỏi',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF003D9B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn chế độ tạo đề',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Lựa chọn cách thức trích xuất câu hỏi từ ngân hàng để đưa vào đề thi',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Mode 1: Random
            Expanded(
              child: _buildModeOption(
                mode: 'random',
                icon: Icons.shuffle_rounded,
                title: 'Trích xuất ngẫu nhiên',
                subtitle: 'Hệ thống tự động xáo trộn và lấy đủ số lượng câu hỏi bạn yêu cầu.',
              ),
            ),
            const SizedBox(width: 16),
            // Mode 2: Manual
            Expanded(
              child: _buildModeOption(
                mode: 'manual',
                icon: Icons.checklist_rounded,
                title: 'Tự chọn câu hỏi',
                subtitle: 'Duyệt danh sách và chủ động tích chọn từng câu hỏi đưa vào bài thi.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _selectedMode = mode);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF003D9B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              const BoxShadow(
                color: Color.fromRGBO(0, 61, 155, 0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              )
            else
              const BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF003D9B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF003D9B) : const Color(0xFFCBD5E1),
                      width: isSelected ? 6 : 1.5,
                    ),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF003D9B) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đề thi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thiết lập các thông số cơ bản cho bài thi mới',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Tên đề thi
          _buildFieldLabel('Tên đề thi', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            decoration: _buildInputDecoration(
              hint: 'Ví dụ: Kiểm tra 45 phút - Đại số & Giải tích',
              prefixIcon: Icons.title_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên đề thi';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Thời gian & Số lần vi phạm
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Thời gian làm bài (phút)', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: '30',
                        prefixIcon: Icons.timer_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập thời gian';
                        }
                        final duration = int.tryParse(value);
                        if (duration == null || duration <= 0) {
                          return 'Thời gian phải là số dương';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Số lần vi phạm tối đa', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _maxViolationsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: '5',
                        prefixIcon: Icons.warning_amber_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số lần';
                        }
                        final max = int.tryParse(value);
                        if (max == null || max < 1) {
                          return 'Số lần vi phạm phải ≥ 1';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Random mode: Số lượng câu hỏi cần chọn
          if (_selectedMode == 'random') ...[
            const SizedBox(height: 20),
            _buildFieldLabel('Số câu hỏi cần trích xuất', isRequired: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _questionCountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: _buildInputDecoration(
                hint: 'Ví dụ: 20',
                prefixIcon: Icons.format_list_numbered_rounded,
                helperText: 'Tối đa ${widget.questionCount} câu hỏi có sẵn trong ngân hàng',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số câu hỏi';
                }
                final count = int.tryParse(value);
                if (count == null || count <= 0) {
                  return 'Số câu phải lớn hơn 0';
                }
                if (count > widget.questionCount) {
                  return 'Tối đa chỉ có ${widget.questionCount} câu trong ngân hàng';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      helperStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF64748B)),
      hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF003D9B), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            'Hủy bỏ',
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
          onPressed: _isCreating ? null : _handleCreateQuiz,
          icon: _isCreating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _selectedMode == 'random'
                      ? Icons.bolt_rounded
                      : Icons.arrow_forward_rounded,
                  size: 20,
                ),
          label: Text(
            _isCreating
                ? 'Đang xử lý...'
                : (_selectedMode == 'random'
                    ? 'Tạo đề ngay'
                    : 'Tiếp tục: Chọn câu hỏi'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003D9B),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCreateQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra trạng thái ngân hàng
    final bankSnap = await FirebaseFirestore.instance.collection('quiz_banks').doc(widget.bankId).get();
    final bankData = bankSnap.data() ?? {};
    if (bankData['status'] == 'archived') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ngân hàng câu hỏi này đã bị đóng (lưu trữ), không thể tạo bài thi!'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

    if (_selectedMode == 'manual') {
      // Navigate to question selector directly using MaterialPageRoute
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizBankQuestionSelectorPage(
            bankId: widget.bankId,
            bankTitle: widget.bankTitle,
            quizTitle: _titleController.text.trim(),
            duration: int.parse(_durationController.text),
            maxViolations: int.parse(_maxViolationsController.text),
            targetClassId: widget.targetClassId,
            targetClassName: widget.targetClassName,
          ),
        ),
      );
      if (res == true && mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    // Random mode - create quiz now
    setState(() => _isCreating = true);

    try {
      final questionCount = int.parse(_questionCountController.text);

      // Get all questions from bank
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_banks')
          .doc(widget.bankId)
          .collection('questions')
          .get();

      if (questionsSnapshot.docs.length < questionCount) {
        throw Exception('Không đủ câu hỏi trong ngân hàng');
      }

      // Random select questions
      final allQuestions = questionsSnapshot.docs;
      allQuestions.shuffle(Random());
      final selectedQuestions = allQuestions.take(questionCount).toList();

      // Lấy thông tin học phần từ ngân hàng nếu có
      final bankSnap = await FirebaseFirestore.instance.collection('quiz_banks').doc(widget.bankId).get();
      final bankData = bankSnap.data() ?? {};
      final subjectId = bankData['courseSubjectId'];
      final subjectName = bankData['courseSubjectName'];
      final subjectCode = bankData['courseSubjectCode'];

      // Create quiz
      final Map<String, dynamic> quizPayload = {
        'title': _titleController.text.trim(),
        'bankId': widget.bankId,
        'selectionMode': 'random',
        'questionCount': questionCount,
        'duration': int.parse(_durationController.text),
        'maxSuspiciousActions': int.parse(_maxViolationsController.text),
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (subjectId != null) {
        quizPayload['courseSubjectId'] = subjectId;
        quizPayload['courseSubjectName'] = subjectName;
        quizPayload['courseSubjectCode'] = subjectCode;
      }

      final quizRef = await FirebaseFirestore.instance.collection('quiz').add(quizPayload);

      // Add selected questions to quiz
      for (var questionDoc in selectedQuestions) {
        await quizRef.collection('questions').add(questionDoc.data());
      }

      // If targetClassId is provided, also attach to the class!
      if (widget.targetClassId != null && widget.targetClassId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.targetClassId!)
            .collection('quizzes')
            .doc(quizRef.id)
            .set({
              'title': _titleController.text.trim(),
              'questionCount': questionCount,
              'duration': int.parse(_durationController.text),
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
                    : 'Đã tạo đề thi thành công với $questionCount câu hỏi!'),
              ],
            ),
            backgroundColor: const Color(0xFF003D9B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
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
