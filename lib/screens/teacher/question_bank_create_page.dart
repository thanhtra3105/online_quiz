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
                            'Tạo ngân hàng câu hỏi',
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
                                  Text(
                                    'Hướng dẫn định dạng file',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
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
                                      Icons.folder_special_rounded,
                                      color: Colors.blue.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Thông tin ngân hàng',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.title),
                                  hintText: 'VD: Ngân hàng Toán học Lớp 10',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
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
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadQuestions,
                            icon: const Icon(Icons.upload_file, size: 28),
                            label: const Text(
                              'Upload File PDF/TXT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
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
                                  'Ngân hàng câu hỏi sẽ được lưu và có thể tạo nhiều đề thi khác nhau từ đây.',
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
