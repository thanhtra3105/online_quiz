// lib/screens/teacher/quiz_create_from_bank_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class QuizCreateFromBankPage extends StatefulWidget {
  final String bankId;
  final String bankTitle;
  final int questionCount;

  const QuizCreateFromBankPage({
    Key? key,
    required this.bankId,
    required this.bankTitle,
    required this.questionCount,
  }) : super(key: key);

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.cyan.shade50],
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
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.create_new_folder_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tạo đề thi mới',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Từ: ${widget.bankTitle}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                        // Bank Info Card
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.folder_special_rounded,
                                  color: Colors.purple.shade700,
                                  size: 32,
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tổng ${widget.questionCount} câu hỏi',
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
                        ),

                        const SizedBox(height: 24),

                        // Mode Selection
                        const Text(
                          'Chọn chế độ tạo đề',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // Random Mode
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedMode = 'random');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _selectedMode == 'random'
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedMode == 'random'
                                          ? Colors.blue.shade400
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (_selectedMode == 'random')
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shuffle_rounded,
                                        size: 40,
                                        color: _selectedMode == 'random'
                                            ? Colors.blue.shade700
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Random',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _selectedMode == 'random'
                                              ? Colors.blue.shade700
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tự động',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Manual Mode
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedMode = 'manual');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _selectedMode == 'manual'
                                        ? Colors.green.shade50
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedMode == 'manual'
                                          ? Colors.green.shade400
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (_selectedMode == 'manual')
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        size: 40,
                                        color: _selectedMode == 'manual'
                                            ? Colors.green.shade700
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tự chọn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _selectedMode == 'manual'
                                              ? Colors.green.shade700
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Chọn câu hỏi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Quiz Info
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
                              const Text(
                                'Thông tin đề thi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Tên đề thi',
                                  prefixIcon: const Icon(Icons.title),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                                  labelText: 'Thời gian (phút)',
                                  prefixIcon: const Icon(Icons.timer),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                                  prefixIcon: const Icon(
                                    Icons.warning_amber_rounded,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập số lần vi phạm';
                                  }
                                  final max = int.tryParse(value);
                                  if (max == null || max < 1) {
                                    return 'Số lần vi phạm phải ≥ 1';
                                  }
                                  return null;
                                },
                              ),

                              if (_selectedMode == 'random') ...[
                                const SizedBox(height: 16),

                                // Question Count for Random Mode
                                TextFormField(
                                  controller: _questionCountController,
                                  decoration: InputDecoration(
                                    labelText: 'Số câu hỏi cần chọn',
                                    prefixIcon: const Icon(
                                      Icons.format_list_numbered,
                                    ),
                                    helperText:
                                        'Tối đa ${widget.questionCount} câu',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập số câu';
                                    }
                                    final count = int.tryParse(value);
                                    if (count == null || count <= 0) {
                                      return 'Số câu phải là số dương';
                                    }
                                    if (count > widget.questionCount) {
                                      return 'Tối đa ${widget.questionCount} câu';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isCreating ? null : _handleCreateQuiz,
                            icon: _isCreating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _selectedMode == 'random'
                                        ? Icons.shuffle_rounded
                                        : Icons.touch_app_rounded,
                                  ),
                            label: Text(
                              _isCreating
                                  ? 'Đang tạo...'
                                  : (_selectedMode == 'random'
                                        ? 'Tạo đề ngay'
                                        : 'Chọn câu hỏi'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedMode == 'random'
                                  ? Colors.blue.shade600
                                  : Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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

  Future<void> _handleCreateQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMode == 'manual') {
      // Navigate to question selector
      Navigator.pushNamed(
        context,
        '/quiz_bank_question_selector',
        arguments: {
          'bankId': widget.bankId,
          'bankTitle': widget.bankTitle,
          'quizTitle': _titleController.text.trim(),
          'duration': int.parse(_durationController.text),
          'maxViolations': int.parse(_maxViolationsController.text),
        },
      );
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

      // Create quiz
      final quizRef = await FirebaseFirestore.instance.collection('quiz').add({
        'title': _titleController.text.trim(),
        'bankId': widget.bankId,
        'selectionMode': 'random',
        'questionCount': questionCount,
        'duration': int.parse(_durationController.text),
        'maxSuspiciousActions': int.parse(_maxViolationsController.text),
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add selected questions to quiz
      for (var questionDoc in selectedQuestions) {
        await quizRef.collection('questions').add(questionDoc.data());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ Đã tạo đề với $questionCount câu hỏi!'),
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
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
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
