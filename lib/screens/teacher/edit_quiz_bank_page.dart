// lib/screens/teacher/edit_quiz_bank_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditQuizBankPage extends StatefulWidget {
  final String bankId;
  final String bankTitle;

  const EditQuizBankPage({
    Key? key,
    required this.bankId,
    required this.bankTitle,
  }) : super(key: key);

  @override
  State<EditQuizBankPage> createState() => _EditQuizBankPageState();
}

class _EditQuizBankPageState extends State<EditQuizBankPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;

  // Danh sách câu hỏi local
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bankTitle);
    _loadQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_banks')
          .doc(widget.bankId)
          .collection('questions')
          .get();

      // Sort theo thứ tự nếu có field order (tùy chọn)
      final sortedDocs = questionsSnapshot.docs;

      setState(() {
        _questions = sortedDocs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'question': data['question'] ?? '',
            // Copy list options để có thể chỉnh sửa
            'options': List<String>.from(data['options'] ?? []),
            'correctAnswer': data['correctAnswer'] ?? 'A',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi tải câu hỏi: $e', isError: true);
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

        // Reset đáp án đúng về A nếu đáp án bị xóa gây lỗi logic
        // (Đây là xử lý đơn giản, thực tế có thể phức tạp hơn)
        _questions[questionIndex]['correctAnswer'] = 'A';
      } else {
        _showSnackBar('Câu hỏi cần ít nhất 2 đáp án', isError: true);
      }
    });
  }
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Chỉnh sửa Ngân hàng'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveBank,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Card Thông tin ngân hàng ---
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tên Ngân hàng',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Nhập tên ngân hàng câu hỏi',
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Không được để trống' : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách câu hỏi (${_questions.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNewQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm câu hỏi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // --- List Câu hỏi ---
                  ..._questions.asMap().entries.map((entry) {
                    return _buildQuestionCard(entry.key, entry.value);
                  }).toList(),

                  const SizedBox(height: 50), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final options = question['options'] as List<String>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Số câu + Nút xóa
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nội dung câu hỏi
            TextFormField(
              initialValue: question['question'],
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              onChanged: (val) => _questions[index]['question'] = val,
              validator: (val) => val!.isEmpty ? 'Nhập nội dung câu hỏi' : null,
            ),

            const SizedBox(height: 16),
            const Text(
              'Đáp án:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // --- Dynamic Options List ---
            ...List.generate(options.length, (optIndex) {
              final letter = String.fromCharCode(65 + optIndex); // A, B, C...
              final rawCorrect = question['correctAnswer'];

              // Check selection logic
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Checkbox/Radio Logic
                    InkWell(
                      onTap: () {
                        setState(() {
                          // Logic chọn đáp án đúng
                          List<String> currentAnswers;
                          if (rawCorrect is List) {
                            currentAnswers = List<String>.from(rawCorrect);
                          } else {
                            currentAnswers = [rawCorrect.toString()];
                          }

                          // Nếu đang click vào cái đã chọn -> Bỏ chọn (nếu là multiple)
                          // Ở đây ta làm logic đơn giản: Click để toggle
                          // Để chuyển single <-> multiple tự động:

                          // Nếu click vào cái chưa chọn:
                          if (!currentAnswers.contains(letter)) {
                            // Nếu muốn hỗ trợ chọn nhiều, ta add vào
                            // Nhưng để UI đơn giản giống Radio, ta check logic:
                            // User phải giữ 1 phím chức năng hoặc ta đổi UI?
                            // Giải pháp tốt nhất: Luôn dùng logic Multiple, nếu list.length == 1 thì là single

                            // Tuy nhiên để giống file cũ:
                            // Ta dùng logic Checkbox cho tất cả.
                            currentAnswers.add(letter);
                            currentAnswers.sort();
                          } else {
                            // Bỏ chọn
                            currentAnswers.remove(letter);
                          }

                          // Nếu list rỗng, mặc định chọn A
                          if (currentAnswers.isEmpty) currentAnswers.add('A');

                          // Cập nhật lại data
                          if (currentAnswers.length == 1) {
                            _questions[index]['correctAnswer'] =
                                currentAnswers.first;
                          } else {
                            _questions[index]['correctAnswer'] = currentAnswers;
                          }
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Input đáp án
                    Expanded(
                      child: TextFormField(
                        initialValue: options[optIndex],
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        onChanged: (val) =>
                            _questions[index]['options'][optIndex] = val,
                        validator: (val) => val!.isEmpty ? 'Nhập đáp án' : null,
                      ),
                    ),

                    // Nút xóa option (chỉ hiện nếu có > 2 options)
                    if (options.length > 2)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => _removeOption(index, optIndex),
                      ),
                  ],
                ),
              );
            }),

            // Nút thêm đáp án
            Center(
              child: TextButton.icon(
                onPressed: () => _addOption(index),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Thêm đáp án'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS ---

  void _addNewQuestion() {
    setState(() {
      _questions.add({
        'id': null,
        'question': '',
        'options': ['', '', '', ''], // Mặc định 4 ô
        'correctAnswer': 'A',
      });
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveBank() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final bankRef = FirebaseFirestore.instance
          .collection('quiz_banks')
          .doc(widget.bankId);

      // 1. Update Bank Info
      await bankRef.update({
        'title': _titleController.text.trim(),
        'questionCount': _questions.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Questions (Delete old & Re-add approach)
      // Lưu ý: Cách này dễ code nhưng sẽ đổi ID của câu hỏi.
      // Nếu muốn giữ ID, logic sẽ phức tạp hơn. Với quy mô nhỏ, cách này OK.
      final oldQuestions = await bankRef.collection('questions').get();
      for (var doc in oldQuestions.docs) {
        await doc.reference.delete();
      }

      for (var q in _questions) {
        await bankRef.collection('questions').add({
          'question': q['question'],
          'options': q['options'],
          'correctAnswer': q['correctAnswer'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu ngân hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Lỗi khi lưu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
