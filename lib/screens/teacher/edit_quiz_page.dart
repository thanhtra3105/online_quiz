// lib/screens/teacher/edit_quiz_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditQuizPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const EditQuizPage({Key? key, required this.quizId, required this.quizData})
    : super(key: key);

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _maxViolationsController;

  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quizData['title']);
    _durationController = TextEditingController(
      text: widget.quizData['duration'].toString(),
    );
    _maxViolationsController = TextEditingController(
      text: (widget.quizData['maxSuspiciousActions'] ?? 5).toString(),
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _maxViolationsController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      // Sắp xếp câu hỏi (nếu cần, hiện tại lấy theo thứ tự Firebase trả về)
      // Nếu muốn chính xác có thể thêm field 'createdAt' hoặc 'order' lúc lưu

      setState(() {
        _questions = questionsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'question': data['question'] ?? '',
            // Copy sang List mới để có thể chỉnh sửa (mutable)
            'options': List<String>.from(data['options'] ?? []),
            'correctAnswer': data['correctAnswer'] ?? 'A',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải câu hỏi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC THÊM/XÓA ĐÁP ÁN ---
  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex]['options'].add('');
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      final options = _questions[questionIndex]['options'] as List<String>;
      // Giữ lại ít nhất 2 đáp án
      if (options.length > 2) {
        options.removeAt(optionIndex);

        // Reset đáp án đúng về A để tránh lỗi logic nếu đáp án bị xóa đang được chọn
        // (Có thể làm logic thông minh hơn là check xem đáp án bị xóa có phải là đáp án đúng không)
        _questions[questionIndex]['correctAnswer'] = 'A';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Câu hỏi cần ít nhất 2 đáp án')),
        );
      }
    });
  }
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Giữ nguyên UI background gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.white,
              Colors.yellow.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header ---
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chỉnh sửa đề thi',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Cập nhật thông tin và câu hỏi',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Nút Save
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveQuiz,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(_isSaving ? 'Đang lưu' : 'Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Content ---
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Thông tin chung ---
                              _buildInfoCard(),

                              const SizedBox(height: 24),

                              // --- Danh sách câu hỏi ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.quiz,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Câu hỏi (${_questions.length})',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addNewQuestion,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text('Thêm câu hỏi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              ..._questions.asMap().entries.map((entry) {
                                return _buildQuestionCard(
                                  entry.key,
                                  entry.value,
                                );
                              }).toList(),

                              const SizedBox(height: 50),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tên đề thi',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Nhập tên đề thi' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian (phút)',
                    prefixIcon: Icon(Icons.timer),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Nhập thời gian' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _maxViolationsController,
                  decoration: const InputDecoration(
                    labelText: 'Vi phạm tối đa',
                    prefixIcon: Icon(Icons.warning_amber),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Nhập số lần' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final options = question['options'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 24), // Tăng khoảng cách
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  tooltip: 'Xóa câu hỏi',
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Question Input
                TextFormField(
                  initialValue: question['question'],
                  decoration: const InputDecoration(
                    labelText: 'Nội dung câu hỏi',
                    prefixIcon: Icon(Icons.help_outline),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 2,
                  onChanged: (val) => _questions[index]['question'] = val,
                  validator: (val) =>
                      val!.isEmpty ? 'Vui lòng nhập câu hỏi' : null,
                ),

                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Đáp án (Chọn hình tròn để đánh dấu đúng)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Dynamic Options
                ...List.generate(options.length, (optIndex) {
                  final letter = String.fromCharCode(65 + optIndex);
                  final rawCorrect = question['correctAnswer'];

                  // Logic check selection
                  bool isMultiple = rawCorrect is List;
                  bool isSelected = false;
                  if (isMultiple) {
                    isSelected = (rawCorrect as List)
                        .map((e) => e.toString())
                        .contains(letter);
                  } else {
                    isSelected = rawCorrect.toString() == letter;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Selection Bubble (Checkbox logic)
                        InkWell(
                          onTap: () {
                            setState(() {
                              List<String> currentAnswers;
                              if (rawCorrect is List) {
                                currentAnswers = List<String>.from(rawCorrect);
                              } else {
                                currentAnswers = [rawCorrect.toString()];
                              }

                              if (!currentAnswers.contains(letter)) {
                                currentAnswers.add(letter);
                                currentAnswers.sort();
                              } else {
                                currentAnswers.remove(letter);
                              }

                              if (currentAnswers.isEmpty)
                                currentAnswers.add('A'); // Fallback

                              if (currentAnswers.length == 1) {
                                _questions[index]['correctAnswer'] =
                                    currentAnswers.first;
                              } else {
                                _questions[index]['correctAnswer'] =
                                    currentAnswers;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Option Text Input
                        Expanded(
                          child: TextFormField(
                            initialValue: options[optIndex],
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isSelected
                                      ? Colors.green.withOpacity(0.5)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isSelected
                                  ? Colors.green.withOpacity(0.05)
                                  : Colors.white,
                            ),
                            onChanged: (val) =>
                                _questions[index]['options'][optIndex] = val,
                            validator: (val) =>
                                val!.isEmpty ? 'Nhập đáp án' : null,
                          ),
                        ),

                        // Remove Option Button (chỉ hiện khi > 2 đáp án)
                        if (options.length > 2)
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.grey,
                            ),
                            onPressed: () => _removeOption(index, optIndex),
                          ),
                      ],
                    ),
                  );
                }),

                // Add Option Button
                TextButton.icon(
                  onPressed: () => _addOption(index),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Thêm đáp án khác'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add({
        'id': null,
        'question': '',
        'options': ['', '', '', ''], // Mặc định 4 ô
        'correctAnswer': 'A',
      });
    });
    // Scroll xuống dưới cùng (Optional)
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa câu ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _questions.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra lại thông tin')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final quizRef = FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId);

      // 1. Update Quiz Info
      await quizRef.update({
        'title': _titleController.text.trim(),
        'duration': int.parse(_durationController.text),
        'maxSuspiciousActions': int.parse(_maxViolationsController.text),
        'questionCount': _questions.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Questions (Xóa cũ thêm mới để đảm bảo đồng bộ options)
      // Lưu ý: Việc xóa hết subcollection tốn write cost, nhưng đảm bảo sạch data
      final existingQuestions = await quizRef.collection('questions').get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in existingQuestions.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit(); // Commit delete trước

      // Add mới từng câu (không dùng batch cho add nếu list quá dài > 500)
      for (var question in _questions) {
        await quizRef.collection('questions').add({
          'question': question['question'].toString().trim(),
          'options': (question['options'] as List<String>)
              .map((opt) => opt.trim())
              .toList(),
          'correctAnswer': question['correctAnswer'],
          // 'order': ... (nếu muốn lưu thứ tự)
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu thay đổi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Trả về true để reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
