// lib/screens/teacher/quiz_bank_create_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/document_parser_service.dart';
import '../../services/gemini_service.dart';
import '../../utils/constants.dart';
import 'gemini_quiz_dialog.dart';

class QuizBankCreatePage extends StatefulWidget {
  const QuizBankCreatePage({Key? key}) : super(key: key);

  @override
  State<QuizBankCreatePage> createState() => _QuizBankCreatePageState();
}

class _QuizBankCreatePageState extends State<QuizBankCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _maxViolationsController = TextEditingController(text: '5');
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxViolationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.white, Colors.pink.shade50],
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
                child: Row(
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
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_circle_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo đề thi mới',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Upload file PDF/TXT',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.purple.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_rounded,
                                      color: Colors.purple.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Hướng dẫn định dạng file',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
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
                                      foregroundColor: Colors.purple.shade700,
                                      side: BorderSide(color: Colors.purple.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SelectionArea(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: const Text(
                                    'File Word (.docx) hoặc PDF (.pdf) có định dạng như các câu hỏi sau (hoặc dùng AI tạo đề/sửa tự động):\n'
                                    'Câu 1: 2 là số chẵn hay lẻ?\n'
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
                                    'Đáp án: A, C, E\n\n'
                                    'Lưu ý:\n'
                                    '- Mỗi câu hỏi bắt đầu bằng "Câu X:"\n'
                                    '- Đáp án đúng bắt đầu bằng "Đáp án:"\n'
                                    '- Hỗ trợ cả dấu chấm (.) và dấu hai chấm (:) sau số câu và chữ đáp án.\n'
                                    '- Đối với câu hỏi nhiều đáp án, các đáp án đúng cách nhau bằng dấu phẩy.\n'
                                    '- Câu hỏi 1 đáp án không cần ghi chú thích; câu nhiều đáp án ghi thêm "(Chọn nhiều đáp án)" để học sinh dễ nhận biết.\n',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quiz Info Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit_document,
                                      color: Colors.blue.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Thông tin đề thi',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Quiz title
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Tên đề thi',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.title),
                                  hintText: 'VD: Kiểm tra Toán học Lớp 10',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tên đề thi';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Duration
                              TextFormField(
                                controller: _durationController,
                                decoration: InputDecoration(
                                  labelText: 'Thời gian làm bài (phút)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.timer),
                                  hintText: '30',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
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

                              const SizedBox(height: 16),

                              // Max Violations
                              TextFormField(
                                controller: _maxViolationsController,
                                decoration: InputDecoration(
                                  labelText: 'Số lần vi phạm tối đa',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.warning_amber_rounded,
                                  ),
                                  hintText: '5',
                                  helperText:
                                      'Học sinh sẽ tự động nộp bài sau khi vi phạm đủ số lần',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập số lần vi phạm';
                                  }
                                  final maxViolations = int.tryParse(value);
                                  if (maxViolations == null ||
                                      maxViolations < 1) {
                                    return 'Số lần vi phạm phải ≥ 1';
                                  }
                                  if (maxViolations > 20) {
                                    return 'Số lần vi phạm không nên > 20';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Upload and Gemini AI buttons
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 550;
                            final uploadBtn = ElevatedButton.icon(
                              onPressed: _isUploading ? null : _uploadQuiz,
                              icon: const Icon(Icons.cloud_upload_outlined, size: 24),
                              label: const Text(
                                'Tải lên Word / PDF',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );

                            final geminiBtn = ElevatedButton.icon(
                              onPressed: _isUploading ? null : _openGeminiGenerator,
                              icon: const Icon(Icons.auto_awesome, size: 24),
                              label: const Text(
                                'Tạo đề bằng Gemini AI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.purple.shade600,
                                            ),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Đang xử lý file...',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(_uploadProgress * 100).toInt()}% hoàn thành',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _uploadProgress,
                                    minHeight: 8,
                                    backgroundColor: Colors.purple.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.purple.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_rounded,
                                color: Colors.blue.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Đề thi sẽ được lưu vào kho và có thể gán cho nhiều lớp khác nhau.',
                                  style: TextStyle(fontSize: 15, height: 1.5),
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
            ],
          ),
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
                                      ? const Color(0xFFFCA5A5)
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
        throw Exception('Không tìm thấy câu hỏi nào hợp lệ.');
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
      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Đề thi mới';
      final duration = int.tryParse(_durationController.text) ?? 30;
      final maxViolations = int.tryParse(_maxViolationsController.text) ?? 5;

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

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Thành công! Đã thêm ${questions.length} câu hỏi vào ngân hàng.',
                ),
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



  // List<Map<String, dynamic>> _parseQuestions(String content) {
  //   List<Map<String, dynamic>> questions = [];

  //   // Step 1: Replace newlines with placeholder to preserve intentional spaces
  //   content = content.replaceAll('\r\n', '@@NEWLINE@@');
  //   content = content.replaceAll('\r', '@@NEWLINE@@');
  //   content = content.replaceAll('\n', '@@NEWLINE@@');

  //   // Step 2: Remove newlines that break Vietnamese characters
  //   // Remove newlines NOT preceded by space or letter (breaking chars)
  //   content = content.replaceAll(RegExp(r'(?<![a-zA-Z\s])@@NEWLINE@@'), '');
  //   // Remove newlines NOT followed by space or letter (breaking chars)
  //   content = content.replaceAll(RegExp(r'@@NEWLINE@@(?![a-zA-Z\s])'), '');
  //   // Convert remaining newlines back to spaces
  //   content = content.replaceAll('@@NEWLINE@@', ' ');

  //   // Step 3: Normalize to NFC to combine Vietnamese characters properly
  //   content = unorm.nfc(content);

  //   // Step 4: Remove zero-width spaces
  //   content = content.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

  //   // Step 5: Add spaces around markers for proper parsing
  //   content = content.replaceAll('Câu', ' Câu ');
  //   content = content.replaceAll('A.', ' A. ');
  //   content = content.replaceAll('B.', ' B. ');
  //   content = content.replaceAll('C.', ' C. ');
  //   content = content.replaceAll('D.', ' D. ');
  //   content = content.replaceAll('Đápán:', ' Đáp án: ');
  //   content = content.replaceAll('?', '? ');

  //   // Step 6: Clean up multiple spaces
  //   content = content.replaceAll(RegExp(r'\s+'), ' ');
  //   content = content.trim();

  //   // Step 7: Split by "Câu X:" pattern to get individual question blocks
  //   final parts = content.split(RegExp(r'Câu\s+\d+:'));

  //   // Step 8: Parse each block (skip first empty element)
  //   for (int i = 1; i < parts.length; i++) {
  //     final block = parts[i].trim();

  //     final match = RegExp(
  //       r'^\s*(.+?)\s+A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+Đáp\s*án:\s*([A-D])',
  //     ).firstMatch(block);

  //     if (match != null) {
  //       questions.add({
  //         'question': match.group(1)!.trim(),
  //         'options': [
  //           match.group(2)!.trim(),
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //         ],
  //         'correctAnswer': match.group(6)!.trim(),
  //       });
  //     }
  //   }

  //   return questions;
  // }

  // --- BẮT ĐẦU: XÓA hàm _parseQuestions CŨ và DÁN 2 hàm MỚI vào đây ---

  // 1. Hàm mới: Tự động sửa lỗi format
  // String _standardizeQuizContent(String content) {
  //   // Chuẩn hóa tiêu đề
  //   content = content.replaceAllMapped(
  //     RegExp(
  //       r'(?:^|\n)\s*(?:Câu|Bài|Question|Q)\s*(\d+)\s*[:.)]?\s*',
  //       caseSensitive: false,
  //     ),
  //     (match) => '\nCâu ${match.group(1)}: ',
  //   );

  //   // ✨ HỖ TRỢ A-J (10 đáp án)
  //   content = content.replaceAllMapped(
  //     RegExp(r'(?:^|\n)\s*([a-jA-J])\s*[:.)]\s+', caseSensitive: false),
  //     (match) => '\n${match.group(1)!.toUpperCase()}. ',
  //   );

  //   // ✨ HỖ TRỢ ĐÁP ÁN A-J và nhiều đáp án (A, C, E)
  //   content = content.replaceAllMapped(
  //     RegExp(
  //       r'(?:^|\n)\s*(?:Đáp\s*án|DA|Answer|Result|KQ|ĐA)\s*[:.]?\s*([A-J,\s]+)',
  //       caseSensitive: false,
  //     ),
  //     (match) => '\nĐáp án: ${match.group(1)!.toUpperCase()}',
  //   );

  //   return content;
  // }

  // // 2. Hàm Parse: Chấp nhận đáp án thứ 4 là D hoặc E
  // // Hàm này trả về Map gồm: 'questions' (list data) và 'errors' (list string)
  // Map<String, dynamic> _parseQuestions(String content) {
  //   List<Map<String, dynamic>> questions = [];
  //   List<String> errors = [];

  //   // Xử lý xuống dòng & Unicode
  //   content = content.replaceAll('\r\n', '@@NEWLINE@@');
  //   content = content.replaceAll('\r', '@@NEWLINE@@');
  //   content = content.replaceAll('\n', '@@NEWLINE@@');
  //   content = content.replaceAll(RegExp(r'(?<![a-zA-Z\s])@@NEWLINE@@'), '');
  //   content = content.replaceAll(RegExp(r'@@NEWLINE@@(?![a-zA-Z\s])'), '');
  //   content = content.replaceAll('@@NEWLINE@@', '\n');
  //   content = unorm.nfc(content);
  //   content = content.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

  //   // Chuẩn hóa
  //   content = _standardizeQuizContent(content);
  //   content = content.replaceAll(RegExp(r'[ \t]+'), ' ');
  //   content = content.trim();

  //   // Tách khối câu hỏi
  //   final parts = content.split(RegExp(r'(?=Câu\s+\d+:)'));

  //   for (var block in parts) {
  //     block = block.trim();
  //     if (block.isEmpty) continue;

  //     bool matched = false;

  //     // ✨ THỬ CÁC PATTERN TỪ 10 -> 4 ĐÁP ÁN

  //     // 10 đáp án (A-J)
  //     var match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+'
  //       r'E\.\s+(.+?)\s+F\.\s+(.+?)\s+G\.\s+(.+?)\s+H\.\s+(.+?)\s+'
  //       r'I\.\s+(.+?)\s+J\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-J,\s]+)',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       final answerStr = match.group(13)!.trim().toUpperCase();
  //       final answerList = answerStr
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList();

  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //           match.group(7)!.trim(),
  //           match.group(8)!.trim(),
  //           match.group(9)!.trim(),
  //           match.group(10)!.trim(),
  //           match.group(11)!.trim(),
  //           match.group(12)!.trim(),
  //         ],
  //         'correctAnswer': answerList.length > 1 ? answerList : answerList[0],
  //         'type': answerList.length > 1 ? 'multiple' : 'single',
  //       });
  //       continue;
  //     }

  //     // 9 đáp án (A-I)
  //     match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+'
  //       r'E\.\s+(.+?)\s+F\.\s+(.+?)\s+G\.\s+(.+?)\s+H\.\s+(.+?)\s+'
  //       r'I\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-I,\s]+)',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       final answerStr = match.group(11)!.trim().toUpperCase();
  //       final answerList = answerStr
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList();

  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //           match.group(7)!.trim(),
  //           match.group(8)!.trim(),
  //           match.group(9)!.trim(),
  //           match.group(10)!.trim(),
  //         ],
  //         'correctAnswer': answerList.length > 1 ? answerList : answerList[0],
  //         'type': answerList.length > 1 ? 'multiple' : 'single',
  //       });
  //       continue;
  //     }

  //     // 8 đáp án (A-H)
  //     match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+'
  //       r'E\.\s+(.+?)\s+F\.\s+(.+?)\s+G\.\s+(.+?)\s+H\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-H,\s]+)',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       final answerStr = match.group(10)!.trim().toUpperCase();
  //       final answerList = answerStr
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList();

  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //           match.group(7)!.trim(),
  //           match.group(8)!.trim(),
  //           match.group(9)!.trim(),
  //         ],
  //         'correctAnswer': answerList.length > 1 ? answerList : answerList[0],
  //         'type': answerList.length > 1 ? 'multiple' : 'single',
  //       });
  //       continue;
  //     }

  //     // 7 đáp án (A-G)
  //     match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+'
  //       r'E\.\s+(.+?)\s+F\.\s+(.+?)\s+G\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-G,\s]+)',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       final answerStr = match.group(9)!.trim().toUpperCase();
  //       final answerList = answerStr
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList();

  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //           match.group(7)!.trim(),
  //           match.group(8)!.trim(),
  //         ],
  //         'correctAnswer': answerList.length > 1 ? answerList : answerList[0],
  //         'type': answerList.length > 1 ? 'multiple' : 'single',
  //       });
  //       continue;
  //     }

  //     // 6 đáp án (A-F)
  //     match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+'
  //       r'E\.\s+(.+?)\s+F\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-F,\s]+)',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       final answerStr = match.group(8)!.trim().toUpperCase();
  //       final answerList = answerStr
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList();

  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //           match.group(7)!.trim(),
  //         ],
  //         'correctAnswer': answerList.length > 1 ? answerList : answerList[0],
  //         'type': answerList.length > 1 ? 'multiple' : 'single',
  //       });
  //       continue;
  //     }

  //     // 5 đáp án (A-E)
  //     match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+E\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-E,\s]+)',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       final answerStr = match.group(8)!.trim().toUpperCase();
  //       final answerList = answerStr
  //           .split(',')
  //           .map((e) => e.trim())
  //           .where((e) => e.isNotEmpty)
  //           .toList();

  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //           match.group(7)!.trim(),
  //         ],
  //         'correctAnswer': answerList.length > 1 ? answerList : answerList[0],
  //         'type': answerList.length > 1 ? 'multiple' : 'single',
  //       });
  //       continue;
  //     }

  //     // ✅ 4 đáp án (A-D) - TRẮC NGHIỆM CỨNG
  //     match = RegExp(
  //       r'Câu\s+(\d+):\s*(.+?)\s+'
  //       r'A\.\s+(.+?)\s+B\.\s+(.+?)\s+C\.\s+(.+?)\s+D\.\s+(.+?)\s+'
  //       r'Đáp\s*án:\s*([A-D])',
  //       caseSensitive: false,
  //       dotAll: true,
  //     ).firstMatch(block);

  //     if (match != null) {
  //       questions.add({
  //         'question': match.group(2)!.trim(),
  //         'options': [
  //           match.group(3)!.trim(),
  //           match.group(4)!.trim(),
  //           match.group(5)!.trim(),
  //           match.group(6)!.trim(),
  //         ],
  //         'correctAnswer': match.group(7)!.trim().toUpperCase(),
  //         'type': 'single',
  //       });
  //       continue;
  //     }

  //     // ❌ Không match được -> Báo lỗi
  //     final cauMatch = RegExp(r'Câu\s+(\d+):').firstMatch(block);
  //     String prefix = cauMatch != null
  //         ? "Câu ${cauMatch.group(1)}"
  //         : "Một câu hỏi";

  //     List<String> missingParts = [];
  //     if (!block.contains(RegExp(r'A\.', caseSensitive: false)))
  //       missingParts.add("A");
  //     if (!block.contains(RegExp(r'B\.', caseSensitive: false)))
  //       missingParts.add("B");
  //     if (!block.contains(RegExp(r'C\.', caseSensitive: false)))
  //       missingParts.add("C");
  //     if (!block.contains(RegExp(r'D\.', caseSensitive: false)))
  //       missingParts.add("D");
  //     if (!block.contains(RegExp(r'Đáp\s*án:', caseSensitive: false)))
  //       missingParts.add("Đáp án");

  //     String errorMsg = missingParts.isNotEmpty
  //         ? "$prefix bị lỗi định dạng. Thiếu: ${missingParts.join(', ')}."
  //         : "$prefix bị lỗi định dạng. Kiểm tra lại xuống dòng hoặc thứ tự đáp án.";

  //     String snippet = block.length > 80
  //         ? block.substring(0, 80).replaceAll('\n', ' ') + "..."
  //         : block.replaceAll('\n', ' ');
  //     errors.add("$errorMsg\n(Nội dung: $snippet)");
  //   }

  //   return {'questions': questions, 'errors': errors};
  // }




} // <--- Dấu ngoặc đó
