// lib/screens/teacher/class_create_quiz_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/document_parser_service.dart';
import '../../services/gemini_service.dart';
import '../../utils/constants.dart';
import 'gemini_quiz_dialog.dart';

class ClassCreateQuizPage extends StatefulWidget {
  final String? classId;
  final String? className;
  final bool isQuestionBank;

  const ClassCreateQuizPage({
    super.key,
    this.classId,
    this.className,
    this.isQuestionBank = false,
  });

  @override
  State<ClassCreateQuizPage> createState() => _ClassCreateQuizPageState();
}

class _ClassCreateQuizPageState extends State<ClassCreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _maxViolationsController = TextEditingController(text: '5'); // ADDED
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxViolationsController.dispose(); // ADDED
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasClass = widget.classId != null && widget.classId!.isNotEmpty;

    final bool isDark = AppConstants.isDarkMode(context);
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav / Header đồng bộ breadcrumbs
            Builder(
              builder: (context) {
                final isMobile = MediaQuery.of(context).size.width < 768;
                final breadcrumbs = [
                  if (widget.isQuestionBank) ...[
                    Tooltip(
                      message: 'Quay lại Ngân hàng câu hỏi',
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
                                'Ngân hàng câu hỏi',
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
                        'Thêm ngân hàng mới',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D9B),
                        ),
                      ),
                    ),
                  ] else if (hasClass) ...[
                    Tooltip(
                      message: 'Quay lại Quản lý lớp học',
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context)
                            ..pop()
                            ..pop();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'Quản lý lớp học',
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
                    Tooltip(
                      message: 'Quay lại Chi tiết lớp',
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            widget.className != null && widget.className!.isNotEmpty
                                ? widget.className!
                                : 'Chi tiết lớp',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
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
                  ] else ...[
                    Tooltip(
                      message: 'Quay lại Bài thi',
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
                                'Bài thi',
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
                        'Tạo đề thi mới',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D9B),
                        ),
                      ),
                    ),
                  ],
                ];

                if (isMobile) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: breadcrumbs,
                      ),
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
                  child: Row(
                    children: [
                      ...breadcrumbs,
                      const Spacer(),
                      IconButton(
                        tooltip: 'Thông báo',
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Tài khoản',
                        onPressed: () {},
                        icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions card
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.surf(context) : const Color(0xFFF1F3FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0052CC),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Hướng dẫn định dạng file',
                                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              // Content
                              SelectionArea(
                                child: Padding(
                                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                                  child: isMobile
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _buildGuideExamples(context, isDark),
                                            const SizedBox(height: 20),
                                            _buildGuideRules(context, isDark),
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: _buildGuideExamples(context, isDark)),
                                            const SizedBox(width: 32),
                                            Expanded(child: _buildGuideRules(context, isDark)),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Quiz Info Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppConstants.surf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.border(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.01),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF82F9BE).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(widget.isQuestionBank ? Icons.folder_rounded : Icons.description, color: const Color(0xFF006C47), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.isQuestionBank ? 'Thông tin ngân hàng câu hỏi' : 'Thông tin đề thi',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.txt(context)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Title
                              TextFormField(
                                controller: _titleController,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txt(context)),
                                decoration: InputDecoration(
                                  labelText: widget.isQuestionBank ? 'Tên ngân hàng câu hỏi' : 'Tên đề thi',
                                  labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
                                  floatingLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF003D9B), fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(widget.isQuestionBank ? Icons.folder_outlined : Icons.title, color: AppConstants.txtMuted(context)),
                                  hintText: widget.isQuestionBank ? 'Ví dụ: Ngân hàng trắc nghiệm Lịch sử 12' : 'Ví dụ: Kiểm tra cuối kỳ - Môn Toán 12',
                                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txtMuted(context).withValues(alpha: 0.6)),
                                  filled: true,
                                  fillColor: AppConstants.surfLow(context),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF003D9B), width: 1.5)),
                                ),
                                validator: (value) => (value == null || value.isEmpty)
                                    ? (widget.isQuestionBank ? 'Vui lòng nhập tên ngân hàng' : 'Vui lòng nhập tên đề thi')
                                    : null,
                              ),
                              if (!widget.isQuestionBank) ...[
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 500;
                                    final durationField = TextFormField(
                                      controller: _durationController,
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txt(context)),
                                      decoration: InputDecoration(
                                        labelText: 'Thời gian làm bài (phút)',
                                        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
                                        floatingLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF003D9B), fontWeight: FontWeight.bold),
                                        prefixIcon: Icon(Icons.schedule, color: AppConstants.txtMuted(context)),
                                        filled: true,
                                        fillColor: AppConstants.surfLow(context),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF003D9B), width: 1.5)),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Vui lòng nhập thời gian';
                                        if ((int.tryParse(value) ?? 0) <= 0) return 'Phải là số dương';
                                        return null;
                                      },
                                    );
                                    final violationsField = Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _maxViolationsController,
                                          style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txt(context)),
                                          decoration: InputDecoration(
                                            labelText: 'Số lần vi phạm tối đa',
                                            labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
                                            floatingLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF003D9B), fontWeight: FontWeight.bold),
                                            prefixIcon: Icon(Icons.warning_amber_rounded, color: AppConstants.txtMuted(context)),
                                            filled: true,
                                            fillColor: AppConstants.surfLow(context),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF003D9B), width: 1.5)),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) return 'Vui lòng nhập';
                                            final max = int.tryParse(value) ?? 0;
                                            if (max < 1) return 'Phải ≥ 1';
                                            if (max > 20) return 'Không nên > 20';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4),
                                          child: Text(
                                            'Học sinh sẽ tự động nộp bài sau khi vi phạm đủ số lần',
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontStyle: FontStyle.italic, color: AppConstants.txtMuted(context)),
                                          ),
                                        ),
                                      ],
                                    );

                                    if (isNarrow) {
                                      return Column(
                                        children: [
                                          durationField,
                                          const SizedBox(height: 16),
                                          violationsField,
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: durationField),
                                        const SizedBox(width: 16),
                                        Expanded(child: violationsField),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action buttons: Upload Word/PDF or Generate with Gemini AI
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 550;
                            final uploadBtn = ElevatedButton.icon(
                              onPressed: _isUploading ? null : _uploadQuiz,
                              icon: const Icon(Icons.cloud_upload_outlined, size: 22),
                              label: const Text(
                                'Tải lên file Word / PDF',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003D9B),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );

                            final geminiBtn = ElevatedButton.icon(
                              onPressed: _isUploading ? null : _openGeminiGenerator,
                              icon: const Icon(Icons.auto_awesome, size: 22),
                              label: const Text(
                                'Tạo đề bằng Gemini AI',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  uploadBtn,
                                  const SizedBox(height: 12),
                                  geminiBtn,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: uploadBtn),
                                const SizedBox(width: 16),
                                Expanded(child: geminiBtn),
                              ],
                            );
                          },
                        ),

                        if (_isUploading) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppConstants.surf(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppConstants.border(context)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B)),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Đang xử lý file...', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.txt(context))),
                                          const SizedBox(height: 4),
                                          Text('${(_uploadProgress * 100).toInt()}% hoàn thành', style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context), fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _uploadProgress,
                                    minHeight: 8,
                                    backgroundColor: isDark ? AppConstants.surfLow(context) : const Color(0xFFD7E2FF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003D9B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 64),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF381515) : const Color(0xFFFFDAD2).withValues(alpha: 0.3),
                            border: Border.all(color: isDark ? const Color(0xFF6B2424) : const Color(0xFFFFDAD2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF5C1D1D) : const Color(0xFFFFDAD2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lightbulb, color: isDark ? Colors.white : const Color(0xFF851800), size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Đề thi sẽ được tạo và tự động gán vào lớp này sau khi file được xử lý thành công.',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? const Color(0xFFFFB4A9) : const Color(0xFF8B1A00), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Future<void> _openGeminiGenerator() async {
    showDialog(
      context: context,
      builder: (context) => GeminiQuizDialog(
        onQuizGenerated: (questions, suggestedTopic) async {
          if (questions.isNotEmpty) {
            if (_titleController.text.trim().isEmpty && suggestedTopic != null) {
              _titleController.text = suggestedTopic;
            }
            await _saveQuestions(questions);
          }
        },
      ),
    );
  }

  Future<void> _uploadQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );

      if (result == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.2;
      });

      final fileName = result.files.single.name;
      final bytes = result.files.single.bytes;

      if (bytes == null) throw Exception('Không thể đọc dữ liệu file');

      String content = '';
      if (fileName.toLowerCase().endsWith('.docx')) {
        content = await DocumentParserService.extractTextFromDocx(bytes);
      } else if (fileName.toLowerCase().endsWith('.pdf')) {
        content = await DocumentParserService.extractTextFromPdf(bytes);
      } else {
        throw Exception('Chỉ hỗ trợ file Word (.docx) hoặc PDF (.pdf)');
      }

      if (content.trim().isEmpty) throw Exception('File không có nội dung văn bản');

      setState(() => _uploadProgress = 0.5);

      final parseResult = DocumentParserService.parseQuestions(content);
      final List<Map<String, dynamic>> questions = parseResult['questions'];
      final List<String> errors = parseResult['errors'];

      setState(() => _uploadProgress = 0.7);

      if (errors.isNotEmpty) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppConstants.surf(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppConstants.border(context)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Phát hiện lỗi định dạng',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppConstants.txt(context),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm thấy ${questions.length} câu hợp lệ, nhưng có ${errors.length} lỗi:',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: AppConstants.txt(context)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.isDarkMode(context)
                            ? const Color(0xFF450A0A).withValues(alpha: 0.3)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppConstants.isDarkMode(context)
                              ? const Color(0xFF7F1D1D)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < errors.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  color: AppConstants.isDarkMode(context)
                                      ? const Color(0xFF7F1D1D)
                                      : const Color(0xFFFEE2E2),
                                  height: 12,
                                ),
                              Text(
                                '• ${errors[i]}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppConstants.isDarkMode(context)
                                      ? const Color(0xFFFFB4A9)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn có thể để Gemini AI tự động chuẩn hóa lại cấu trúc của đề thi này.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontStyle: FontStyle.italic,
                        fontSize: 12.5,
                        color: AppConstants.txtMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppConstants.border(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Đóng',
                    style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _autoFixWithGemini(content);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text(
                    'Sửa tự động bằng AI Gemini',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.brand(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (questions.isEmpty) {
        throw Exception('Không tìm thấy câu hỏi nào hợp lệ trong file.');
      }

      await _saveQuestions(questions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _autoFixWithGemini(String originalContent) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Gemini AI đang phân tích và chuẩn hóa đề thi...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      final fixedContent = await GeminiService.fixUnformattedContent(originalContent);
      setState(() => _uploadProgress = 0.6);

      final parseResult = DocumentParserService.parseQuestions(fixedContent);
      final List<Map<String, dynamic>> questions = parseResult['questions'];
      final List<String> errors = parseResult['errors'];

      if (questions.isEmpty) {
        throw Exception('Gemini AI không trích xuất được câu hỏi nào từ nội dung này.');
      }

      if (errors.isNotEmpty && questions.isEmpty) {
        throw Exception('Lỗi sau khi AI chuẩn hóa: ${errors.first}');
      }

      setState(() => _uploadProgress = 0.8);
      await _saveQuestions(questions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi sửa bằng Gemini: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _saveQuestions(List<Map<String, dynamic>> questions) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.85;
    });

    try {
      if (widget.isQuestionBank) {
        final bankRef = await FirebaseFirestore.instance.collection('quiz_banks').add({
          'title': _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : 'Ngân hàng câu hỏi mới',
          'description': 'Ngân hàng câu hỏi',
          'questionCount': questions.length,
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (var question in questions) {
          await bankRef.collection('questions').add(question);
        }
      } else {
        final duration = int.tryParse(_durationController.text) ?? 30;
        final maxViolations = int.tryParse(_maxViolationsController.text) ?? 5;
        final title = _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Đề thi mới';

        final quizRef = await FirebaseFirestore.instance.collection('quiz').add({
          'title': title,
          'questionCount': questions.length,
          'duration': duration,
          'maxSuspiciousActions': maxViolations,
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (var question in questions) {
          await quizRef.collection('questions').add(question);
        }

        if (widget.classId != null && widget.classId!.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId!)
              .collection('quizzes')
              .doc(quizRef.id)
              .set({
                'title': title,
                'questionCount': questions.length,
                'duration': duration,
                'assignedAt': FieldValue.serverTimestamp(),
              });

          final classDoc = await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId!)
              .get();
          final currentCount = (classDoc.data()?['quizCount'] ?? 0) as int;

          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId!)
              .update({'quizCount': currentCount + 1});
        }
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.isQuestionBank
                    ? 'Thành công! Đã thêm ${questions.length} câu hỏi vào ngân hàng.'
                    : 'Thành công! Đã tạo đề với ${questions.length} câu hỏi.'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }



  static const String _sampleQuizText = 'Câu 1: 2 là số chẵn hay lẻ?\n'
      'A. Đúng\n'
      'B. Sai\n'
      'Đáp án: A\n\n'
      'Câu 2: Ai là cầu thủ xuất sắc nhất thế giới?\n'
      'A. Ronaldo\n'
      'B. Messi\n'
      'C. Cả hai\n'
      'Đáp án: C\n\n'
      'Câu 3: Thủ đô Việt Nam là?\n'
      'A. Hà Nội\n'
      'B. Đà Nẵng\n'
      'C. TP.HCM\n'
      'D. Hải Phòng\n'
      'Đáp án: A\n\n'
      'Câu 4: Những màu nào sau đây là màu nóng? (Chọn nhiều đáp án)\n'
      'A. Đỏ\n'
      'B. Xanh lá\n'
      'C. Vàng\n'
      'D. Xanh dương\n'
      'E. Cam\n'
      'F. Tím\n'
      'Đáp án: A, C, E';

  Widget _buildGuideExamples(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'File Word (.docx) hoặc PDF (.pdf) có định dạng như sau:',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _sampleQuizText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text('Đã sao chép mẫu câu hỏi! Bạn có thể dán (Ctrl+V) vào Word.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Sao chép mẫu', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0052CC),
                side: const BorderSide(color: Color(0xFF0052CC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppConstants.surfLow(context) : const Color(0xFFF9F9FF),
            border: Border.all(color: AppConstants.border(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),
              children: [
                const TextSpan(text: 'Câu 1: 2 là số chẵn hay lẻ?\n', style: TextStyle(color: Color(0xFF388BFD), fontWeight: FontWeight.bold)),
                TextSpan(text: 'A. Đúng\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'B. Sai\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                const TextSpan(text: 'Đáp án: A\n\n', style: TextStyle(color: Color(0xFF2EA043), fontWeight: FontWeight.bold)),

                const TextSpan(text: 'Câu 2: Ai là cầu thủ xuất sắc nhất thế giới?\n', style: TextStyle(color: Color(0xFF388BFD), fontWeight: FontWeight.bold)),
                TextSpan(text: 'A. Ronaldo\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'B. Messi\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'C. Cả hai\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                const TextSpan(text: 'Đáp án: C\n\n', style: TextStyle(color: Color(0xFF2EA043), fontWeight: FontWeight.bold)),

                const TextSpan(text: 'Câu 3: Thủ đô Việt Nam là?\n', style: TextStyle(color: Color(0xFF388BFD), fontWeight: FontWeight.bold)),
                TextSpan(text: 'A. Hà Nội\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'B. Đà Nẵng\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'C. TP.HCM\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'D. Hải Phòng\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                const TextSpan(text: 'Đáp án: A\n\n', style: TextStyle(color: Color(0xFF2EA043), fontWeight: FontWeight.bold)),

                const TextSpan(text: 'Câu 4: Những màu nào sau đây là màu nóng? (Chọn nhiều đáp án)\n', style: TextStyle(color: Color(0xFF388BFD), fontWeight: FontWeight.bold)),
                TextSpan(text: 'A. Đỏ\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'B. Xanh lá\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'C. Vàng\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'D. Xanh dương\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'E. Cam\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                TextSpan(text: 'F. Tím\n', style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF041B3C))),
                const TextSpan(text: 'Đáp án: A, C, E', style: TextStyle(color: Color(0xFF2EA043), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideRules(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, color: Color(0xFF388BFD), size: 20), const SizedBox(width: 8), Expanded(child: Text('Mỗi câu hỏi bắt đầu bằng "Câu X:"', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context))))]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, color: Color(0xFF388BFD), size: 20), const SizedBox(width: 8), Expanded(child: Text('Đáp án đúng bắt đầu bằng "Đáp án:"', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context))))]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, color: Color(0xFF388BFD), size: 20), const SizedBox(width: 8), Expanded(child: Text('Hỗ trợ dấu chấm (.) và dấu hai chấm (:) sau số câu và đáp án', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context))))]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, color: Color(0xFF388BFD), size: 20), const SizedBox(width: 8), Expanded(child: Text('Đối với câu nhiều đáp án, các đáp án cách nhau bằng dấu phẩy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context))))]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, color: Color(0xFF388BFD), size: 20), const SizedBox(width: 8), Expanded(child: Text('Câu hỏi 1 đáp án không cần ghi chú thích; câu nhiều đáp án ghi thêm "(Chọn nhiều đáp án)" để học sinh dễ nhận biết', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context))))]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF381515) : const Color(0xFFFFDAD2).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF6B2424) : const Color(0xFFFFDAD2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF5C1D1D) : const Color(0xFFFFDAD2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb, color: isDark ? Colors.white : const Color(0xFF851800), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Mẹo: Bạn có thể nhấn "Tạo đề bằng Gemini AI" để sinh câu hỏi theo chủ đề nhanh chóng, hoặc bấm "Sửa tự động bằng AI Gemini" nếu file tải lên chưa đúng định dạng chuẩn.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? const Color(0xFFFFB4A9) : const Color(0xFF8B1A00)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
