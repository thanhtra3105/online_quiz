// lib/screens/teacher/question_bank_create_page.dart (FILE MỚI)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/document_parser_service.dart';
import '../../services/gemini_service.dart';
import '../../utils/constants.dart';
import 'gemini_quiz_dialog.dart';

class QuestionBankCreatePage extends StatefulWidget {
  const QuestionBankCreatePage({Key? key}) : super(key: key);

  @override
  State<QuestionBankCreatePage> createState() => _QuestionBankCreatePageState();
}

class _QuestionBankCreatePageState extends State<QuestionBankCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF041B3C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo ngân hàng câu hỏi',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF041B3C),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFC3C6D6), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC3C6D6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EDFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFF003D9B),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Hướng dẫn định dạng file',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF041B3C),
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
                                      foregroundColor: const Color(0xFF003D9B),
                                      side: const BorderSide(color: Color(0xFF003D9B)),
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

                        // Bank Name Input
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC3C6D6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EDFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.folder_outlined,
                                      color: Color(0xFF003D9B),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Thông tin ngân hàng',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF041B3C),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Bank name
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Tên ngân hàng câu hỏi',
                                  labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 2)),
                                  prefixIcon: const Icon(Icons.title, color: Color(0xFF737685)),
                                  hintText: 'VD: Ngân hàng Toán học Lớp 10',
                                  hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF737685)),
                                  filled: true,
                                  fillColor: const Color(0xFFF9F9FF),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tên ngân hàng';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Upload button & Gemini AI option
                        InkWell(
                          onTap: _isUploading ? null : _uploadQuestions,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF003D9B).withValues(alpha: 0.4), style: BorderStyle.solid, width: 2),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8EDFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.cloud_upload_outlined, size: 44, color: Color(0xFF003D9B)),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Kéo thả file Word / PDF vào đây hoặc nhấn để tải lên',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF041B3C)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Hỗ trợ Word (.docx) và PDF (.pdf). Hệ thống tự động trích xuất câu hỏi.',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hoặc tạo đề thi bằng Gemini AI button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _openGeminiGenerator,
                            icon: const Icon(Icons.auto_awesome, size: 22),
                            label: const Text(
                              'Hoặc tạo đề tự động bằng Gemini AI',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        if (_isUploading) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFC3C6D6)),
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
                                          const Text(
                                            'Đang xử lý file...',
                                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF041B3C)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(_uploadProgress * 100).toInt()}% hoàn thành',
                                            style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654), fontSize: 14),
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
                                    backgroundColor: const Color(0xFFE8EDFF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003D9B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Future<void> _uploadQuestions() async {
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
      final bankRef = await FirebaseFirestore.instance
          .collection('quiz_banks')
          .add({
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

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ Đã thêm ${questions.length} câu hỏi vào ngân hàng!'),
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





}
