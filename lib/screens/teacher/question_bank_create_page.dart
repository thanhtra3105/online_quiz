// lib/screens/teacher/question_bank_create_page.dart (FILE MỚI)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

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
                                  const Text(
                                    'Hướng dẫn định dạng file',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF041B3C),
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: const Text(
                                  'File PDF hoặc TXT phải có định dạng như các câu hỏi sau:\n'
                                  'Câu 1: 2 là số chẵn hay lẻ? (Câu hỏi đúng sai)\n'
                                  'A. Đúng\n'
                                  'B. Sai\n'
                                  'Đáp án: A\n\n'
                                  'Câu 2: Ai là cầu thủ xuất sắc nhất thế giới? (Câu hỏi 3 đáp án)\n'
                                  'A. Ronaldo\n'
                                  'B. Messi\n'
                                  'C. Cả hai\n'
                                  'Đáp án: C\n\n'
                                  'Câu 3: Thủ đô Việt Nam là? (Câu hỏi 4 đáp án)\n'
                                  'A. Hà Nội\n'
                                  'B. Đà Nẵng\n'
                                  'C. TP.HCM\n'
                                  'D. Hải Phòng\n'
                                  'Đáp án: A\n\n'
                                  'Câu 3: Những màu nào sau đây là màu nóng? (Câu hỏi nhiều đáp án)\n'
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
                                  '- Đối với câu hỏi nhiều đáp án, các đáp án đúng cách nhau bằng dấu phẩy.\n',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    fontFamily: 'monospace',
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

                        // Upload button
                        InkWell(
                          onTap: _isUploading ? null : _uploadQuestions,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
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
                                  child: const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF003D9B)),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Kéo thả file vào đây hoặc nhấn để tải lên',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF041B3C)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Hỗ trợ PDF, TXT. AI sẽ tự động trích xuất câu hỏi.',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                                ),
                              ],
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

  Future<void> _uploadQuestions() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: true,
      );

      if (result == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.2;
      });

      final fileName = result.files.single.name;
      final bytes = result.files.single.bytes;

      if (bytes == null) throw Exception('Không thể đọc file');

      String content = '';
      if (fileName.endsWith('.txt')) {
        content = String.fromCharCodes(bytes);
      } else if (fileName.endsWith('.pdf')) {
        content = await _extractTextFromPdf(bytes);
      }

      if (content.isEmpty) throw Exception('File trống');

      setState(() => _uploadProgress = 0.5);

      final parseResult = _parseQuestions(content);
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
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Phát hiện lỗi định dạng'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm thấy ${questions.length} câu hợp lệ, nhưng có ${errors.length} lỗi:',
                    ),
                    SizedBox(height: 12),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: errors.length,
                          separatorBuilder: (ctx, i) => Divider(),
                          itemBuilder: (ctx, i) => Text(
                            '• ${errors[i]}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Vui lòng sửa file và upload lại.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Đóng'),
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

      // ✨ LƯU VÀO QUIZ_BANKS COLLECTION
      final bankRef = await FirebaseFirestore.instance
          .collection('quiz_banks')
          .add({
            'title': _titleController.text.trim(),
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
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Đã thêm ${questions.length} câu hỏi vào ngân hàng!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(context);
      }
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

  Future<String> _extractTextFromPdf(List<int> bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Lỗi khi đọc PDF: $e');
    }
  }
  // --- BẮT ĐẦU PHẦN CODE MỚI ---

  /// Hàm chuẩn hóa nội dung file trước khi xử lý
  String _standardizeQuizContent(String content) {
    // 1. Thêm xuống dòng trước các từ khóa "Câu X:", "Bài X:" để tách khối
    content = content.replaceAllMapped(
      RegExp(
        r'(?:^|\n)\s*(?:Câu|Bài|Question|Q)\s*(\d+)\s*[:.)]?\s*',
        caseSensitive: false,
      ),
      (match) => '\n@@BLOCK_START@@Câu ${match.group(1)}: ',
    );

    // 2. Chuẩn hóa các đáp án (A. B. C. D. ...) thành format "A. "
    // Hỗ trợ: A. | A: | A) | a.
    content = content.replaceAllMapped(
      RegExp(r'(?:^|\n)\s*([A-Z])\s*[:.)]\s+', caseSensitive: false),
      (match) => '\n${match.group(1)!.toUpperCase()}. ',
    );

    // 3. Chuẩn hóa dòng đáp án
    // Hỗ trợ: Đáp án: | DA: | Ans: | Result: | ĐA:
    content = content.replaceAllMapped(
      RegExp(
        r'(?:^|\n)\s*(?:Đáp\s*án|DA|Answer|Result|KQ|ĐA)\s*[:.]?\s*([A-Z0-9\s,]+)',
        caseSensitive: false,
      ),
      (match) => '\nĐáp án: ${match.group(1)!.toUpperCase()}',
    );

    return content;
  }

  /// Hàm phân tích câu hỏi động (Dynamic Parsing)
  Map<String, dynamic> _parseQuestions(String content) {
    List<Map<String, dynamic>> questions = [];
    List<String> errors = [];

    try {
      // BƯỚC 1: Xử lý sơ bộ văn bản (Unicode, Newline)
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      content = unorm.nfc(content); // Chuẩn hóa tiếng Việt

      // BƯỚC 2: Chuẩn hóa format chung
      content = _standardizeQuizContent(content);

      // Xóa các ký tự điều khiển lạ
      content = content.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

      // BƯỚC 3: Tách các câu hỏi dựa trên marker @@BLOCK_START@@ đã thêm ở bước chuẩn hóa
      final blocks = content.split('@@BLOCK_START@@');

      for (var block in blocks) {
        block = block.trim();
        if (block.isEmpty) continue; // Bỏ qua block rỗng đầu tiên

        // -- BẮT ĐẦU XỬ LÝ TỪNG CÂU --

        // 1. Tách nội dung câu hỏi (Từ đầu cho đến khi gặp đáp án A.)
        // Regex tìm điểm bắt đầu của đáp án đầu tiên (A.)
        final questionMatch = RegExp(
          r'^(.*?)(\n[A-Z]\.\s+)',
          dotAll: true,
        ).firstMatch(block);

        if (questionMatch == null) {
          // Nếu không tìm thấy đáp án A nào -> Lỗi định dạng hoặc text rác
          if (block.contains('Câu') && block.length < 50)
            continue; // Bỏ qua header ngắn
          errors.add(
            "Không tìm thấy các lựa chọn (A, B...) cho: \"${block.split('\n')[0]}\"",
          );
          continue;
        }

        String questionText = questionMatch.group(1)!.trim();
        // Loại bỏ prefix "Câu X:" trong nội dung câu hỏi để đẹp hơn
        questionText = questionText.replaceAll(
          RegExp(r'^Câu\s+\d+:\s*', caseSensitive: false),
          '',
        );

        // 2. Tìm tất cả các đáp án (A. ..., B. ...)
        List<String> options = [];
        List<String> optionKeys = []; // Lưu lại A, B, C để đối chiếu

        // Regex này tìm: (Xuống dòng)(Chữ cái)(Chấm)(Nội dung)(Dừng lại trước chữ cái tiếp theo hoặc dòng Đáp án)
        final optionMatches = RegExp(
          r'\n([A-Z])\.\s+(.*?)(?=\n[A-Z]\.\s+|\nĐáp án:|$)',
          dotAll: true,
        ).allMatches(block);

        for (var match in optionMatches) {
          optionKeys.add(match.group(1)!); // A, B, C...
          options.add(match.group(2)!.trim()); // Nội dung đáp án
        }

        if (options.length < 2) {
          errors.add(
            "Câu hỏi \"${questionText.substring(0, 20)}...\" có ít hơn 2 đáp án.",
          );
          continue;
        }

        // 3. Tìm đáp án đúng
        final answerMatch = RegExp(
          r'\nĐáp án:\s*([A-Z\s,]+)',
        ).firstMatch(block);

        if (answerMatch == null) {
          errors.add(
            "Câu hỏi \"${questionText.substring(0, 20)}...\" thiếu dòng 'Đáp án:'.",
          );
          continue;
        }

        // Xử lý chuỗi đáp án (VD: "A, C" hoặc "A C" hoặc "A")
        String rawAnswer = answerMatch.group(1)!;
        List<String> correctAnswers = rawAnswer
            .split(RegExp(r'[,\s]+')) // Tách bằng dấu phẩy hoặc khoảng trắng
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // Validate đáp án có nằm trong danh sách option không
        bool isValidAnswer = true;
        for (var ans in correctAnswers) {
          if (!optionKeys.contains(ans)) {
            errors.add(
              "Câu hỏi \"${questionText.substring(0, 20)}...\" có đáp án '$ans' không nằm trong các lựa chọn (${optionKeys.join(', ')}).",
            );
            isValidAnswer = false;
            break;
          }
        }
        if (!isValidAnswer) continue;

        // 4. Đóng gói kết quả
        questions.add({
          'question': questionText,
          'options': options,
          // Nếu có nhiều đáp án đúng -> lưu List<String>, nếu 1 -> lưu String
          'correctAnswer': correctAnswers.length > 1
              ? correctAnswers
              : correctAnswers.first,
          'type': correctAnswers.length > 1 ? 'multiple' : 'single',
        });
      }
    } catch (e) {
      errors.add("Lỗi hệ thống khi phân tích file: $e");
    }

    return {'questions': questions, 'errors': errors};
  }
}
