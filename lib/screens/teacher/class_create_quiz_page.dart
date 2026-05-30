// lib/screens/teacher/class_create_quiz_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

class ClassCreateQuizPage extends StatefulWidget {
  final String classId;

  const ClassCreateQuizPage({Key? key, required this.classId})
    : super(key: key);

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav / Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF434654)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Quản lí lớp học',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B57D0)),
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    'Chi tiết lớp học',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B57D0)),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Tạo đề thi mới',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF737685)),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF434654))),
                  const SizedBox(width: 8),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF434654), size: 28)),
                ],
              ),
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
                            color: const Color(0xFFF1F3FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7E2FF)),
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
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'File PDF hoặc TXT phải có định dạng như các câu hỏi sau:',
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654)),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9F9FF),
                                              border: Border.all(color: const Color(0xFFC3C6D6)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text.rich(
                                              TextSpan(
                                                style: TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.6),
                                                children: [
                                                  TextSpan(text: 'Câu 1: 2 là số chẵn hay lẻ? (Câu hỏi đúng sai)\n', style: TextStyle(color: Color(0xFF003D9B), fontWeight: FontWeight.bold)),
                                                  TextSpan(text: 'A. Đúng\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'B. Sai\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'Đáp án: A\n\n', style: TextStyle(color: Color(0xFF006C47), fontWeight: FontWeight.bold)),
                                                  
                                                  TextSpan(text: 'Câu 2: Ai là cầu thủ xuất sắc nhất thế giới? (Câu hỏi 3 đáp án)\n', style: TextStyle(color: Color(0xFF003D9B), fontWeight: FontWeight.bold)),
                                                  TextSpan(text: 'A. Ronaldo\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'B. Messi\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'C. Cả hai\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'Đáp án: C\n\n', style: TextStyle(color: Color(0xFF006C47), fontWeight: FontWeight.bold)),

                                                  TextSpan(text: 'Câu 3: Thủ đô Việt Nam là? (Câu hỏi 4 đáp án)\n', style: TextStyle(color: Color(0xFF003D9B), fontWeight: FontWeight.bold)),
                                                  TextSpan(text: 'A. Hà Nội\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'B. Đà Nẵng\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'C. TP.HCM\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'D. Hải Phòng\n', style: TextStyle(color: Color(0xFF041B3C))),
                                                  TextSpan(text: 'Đáp án: A', style: TextStyle(color: Color(0xFF006C47), fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    // Right Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Icon(Icons.check_circle, color: Color(0xFF003D9B), size: 20), SizedBox(width: 8), Expanded(child: Text('Mỗi câu hỏi bắt đầu bằng "Câu X:"', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))))]),
                                          const SizedBox(height: 12),
                                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Icon(Icons.check_circle, color: Color(0xFF003D9B), size: 20), SizedBox(width: 8), Expanded(child: Text('Đáp án đúng bắt đầu bằng "Đáp án:"', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))))]),
                                          const SizedBox(height: 12),
                                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Icon(Icons.check_circle, color: Color(0xFF003D9B), size: 20), SizedBox(width: 8), Expanded(child: Text('Hỗ trợ dấu chấm (.) và dấu hai chấm (:) sau số câu', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))))]),
                                          const SizedBox(height: 12),
                                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Icon(Icons.check_circle, color: Color(0xFF003D9B), size: 20), SizedBox(width: 8), Expanded(child: Text('Đối với câu nhiều đáp án, các đáp án cách nhau bằng dấu phẩy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))))]),
                                          const SizedBox(height: 24),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFDAD2).withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFFFDAD2)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFFFDAD2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.lightbulb, color: Color(0xFF851800), size: 20),
                                                ),
                                                const SizedBox(width: 16),
                                                const Expanded(
                                                  child: Text(
                                                    'Mẹo: Sử dụng cấu trúc rõ ràng giúp AI của chúng tôi nhận diện câu hỏi chính xác 100%.',
                                                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF8B1A00)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                            color: const Color(0xFFF9F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC3C6D6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 2,
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
                                      color: const Color(0xFF82F9BE).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.description, color: Color(0xFF006C47), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Thông tin đề thi',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF041B3C)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Quiz title
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF041B3C)),
                                decoration: InputDecoration(
                                  labelText: 'Tên đề thi',
                                  labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                                  floatingLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF003D9B), fontWeight: FontWeight.bold),
                                  prefixIcon: const Icon(Icons.title, color: Color(0xFFC3C6D6)),
                                  hintText: 'Ví dụ: Kiểm tra cuối kỳ - Môn Toán 12',
                                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: const Color(0xFFC3C6D6).withOpacity(0.6)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF737685))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF737685))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 1)),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập tên đề thi' : null,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _durationController,
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF041B3C)),
                                      decoration: InputDecoration(
                                        labelText: 'Thời gian làm bài (phút)',
                                        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                                        floatingLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF003D9B), fontWeight: FontWeight.bold),
                                        prefixIcon: const Icon(Icons.schedule, color: Color(0xFFC3C6D6)),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF737685))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF737685))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 1)),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Vui lòng nhập thời gian';
                                        if ((int.tryParse(value) ?? 0) <= 0) return 'Phải là số dương';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _maxViolationsController,
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF041B3C)),
                                          decoration: InputDecoration(
                                            labelText: 'Số lần vi phạm tối đa',
                                            labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                                            floatingLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF003D9B), fontWeight: FontWeight.bold),
                                            prefixIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFC3C6D6)),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF737685))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF737685))),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 1)),
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
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontStyle: FontStyle.italic, color: const Color(0xFF434654).withOpacity(0.6)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Upload button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadQuiz,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 24),
                            label: const Text(
                              'Upload File PDF/TXT',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003D9B),
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
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD7E2FF)),
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
                                          const Text('Đang xử lý file...', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF041B3C))),
                                          const SizedBox(height: 4),
                                          Text('${(_uploadProgress * 100).toInt()}% hoàn thành', style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF737685), fontSize: 14)),
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
                                    backgroundColor: const Color(0xFFD7E2FF),
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
                            color: const Color(0xFFFFDAD2).withOpacity(0.3),
                            border: Border.all(color: const Color(0xFFFFDAD2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFDAD2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lightbulb, color: Color(0xFF851800), size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Đề thi sẽ được tạo và tự động gán vào lớp này sau khi file được xử lý thành công.',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF8B1A00), fontWeight: FontWeight.w500),
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

  Future<void> _uploadQuiz() async {
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

      // --- GỌI HÀM PARSE MỚI ---
      final parseResult = _parseQuestions(content);
      final List<Map<String, dynamic>> questions = parseResult['questions'];
      final List<String> errors = parseResult['errors'];

      setState(() => _uploadProgress = 0.7);

      // --- NẾU CÓ LỖI: HIỆN THÔNG BÁO VÀ DỪNG ---
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
        return; // Dừng upload
      }

      // --- NẾU KHÔNG CÓ CÂU HỎI NÀO ---
      if (questions.isEmpty) {
        throw Exception('Không tìm thấy câu hỏi nào hợp lệ.');
      }

      // --- TIẾP TỤC UPLOAD NHƯ CŨ ---
      // (Phần code bên dưới giữ nguyên logic cũ của bạn, chỉ thay đổi biến questions)

      // ... Logic tạo Quiz trên Firebase ...
      // --- TẠO QUIZ VÀ GÁN VÀO LỚP ---
      final quizRef = await FirebaseFirestore.instance.collection('quiz').add({
        'title': _titleController.text.trim(),
        'questionCount': questions.length,
        'duration': int.parse(_durationController.text),
        'maxSuspiciousActions': int.parse(_maxViolationsController.text),
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var question in questions) {
        await quizRef.collection('questions').add(question);
      }

      // ✨ GÁN VÀO LỚP HỌC
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizRef.id)
          .set({
            'title': _titleController.text.trim(),
            'questionCount': questions.length,
            'duration': int.parse(_durationController.text),
            'assignedAt': FieldValue.serverTimestamp(),
          });

      // ✨ CẬP NHẬT SỐ LƯỢNG ĐỀ THI TRONG LỚP
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 0) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'quizCount': currentCount + 1});

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Thành công! Đã thêm ${questions.length} câu hỏi.'),
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
