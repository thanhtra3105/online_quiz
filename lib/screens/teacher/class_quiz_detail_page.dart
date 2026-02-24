// lib/screens/teacher/class_quiz_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_quiz_page.dart';
import 'quiz_schedule_dialog.dart';
import '../../services/quiz_schedule_service.dart';
import '../../models/quiz_schedule_model.dart';

class ClassQuizDetailPage extends StatefulWidget {
  final String classId;
  final String quizId;
  final Map<String, dynamic> quizData;

  const ClassQuizDetailPage({
    Key? key,
    required this.classId,
    required this.quizId,
    required this.quizData,
  }) : super(key: key);

  @override
  State<ClassQuizDetailPage> createState() => _ClassQuizDetailPageState();
}

class _ClassQuizDetailPageState extends State<ClassQuizDetailPage> {
  QuizSchedule? _currentSchedule;
  bool _isLoadingSchedule = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await QuizScheduleService.getSchedule(
        widget.classId,
        widget.quizId,
      );
      if (mounted) {
        setState(() {
          _currentSchedule = schedule;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      print('Error loading schedule: $e');
      if (mounted) {
        setState(() => _isLoadingSchedule = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white, Colors.teal.shade50],
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
                child: Column(
                  children: [
                    Row(
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
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.quiz_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.quizData['title'] ?? 'Chi tiết bài thi',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.quizData['questionCount']} câu hỏi • ${widget.quizData['duration']} phút',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Schedule Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.schedule_rounded,
                              color: Colors.blue.shade700,
                            ),
                            tooltip: 'Lên lịch',
                            onPressed: () => _manageSchedule(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Edit Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: Colors.orange.shade700,
                            ),
                            tooltip: 'Chỉnh sửa',
                            onPressed: () => _editQuiz(context),
                          ),
                        ),
                      ],
                    ),

                    // Schedule Status Banner
                    if (!_isLoadingSchedule && _currentSchedule != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildScheduleBanner(_currentSchedule!),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('quiz')
                      .doc(widget.quizId)
                      .collection('questions')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Đang tải câu hỏi...'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Có lỗi xảy ra',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(color: Colors.red.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.quiz_outlined,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Không có câu hỏi nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final questions = snapshot.data!.docs;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quiz info card
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
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Thông tin đề thi',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        Icons.quiz,
                                        'Số câu hỏi',
                                        '${widget.quizData['questionCount']}',
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInfoItem(
                                        Icons.timer,
                                        'Thời gian',
                                        '${widget.quizData['duration']} phút',
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Questions header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.format_list_numbered,
                                  color: Colors.green.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Danh sách câu hỏi',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Questions list
                          ...questions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final questionData =
                                entry.value.data() as Map<String, dynamic>;
                            final options = List<String>.from(
                              questionData['options'] ?? [],
                            );
                            final correctAnswer = questionData['correctAnswer'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
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
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.green.shade400,
                                                Colors.green.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Câu ${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      questionData['question'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Tìm đoạn code map options và thay bằng:
                                    ...options.asMap().entries.map((optEntry) {
                                      final letter = String.fromCharCode(
                                        65 + optEntry.key,
                                      );

                                      // // ✨ Kiểm tra type
                                      // final questionType =
                                      //     questionData['type'] ?? 'single';
                                      // bool isCorrect;

                                      // if (questionType == 'multiple') {
                                      //   final correctAnswers =
                                      //       questionData['correctAnswer']
                                      //           is List
                                      //       ? List<String>.from(
                                      //           questionData['correctAnswer'],
                                      //         )
                                      //       : [
                                      //           questionData['correctAnswer']
                                      //               .toString(),
                                      //         ];
                                      //   isCorrect = correctAnswers.contains(
                                      //     letter,
                                      //   );
                                      // } else {
                                      //   isCorrect =
                                      //       letter ==
                                      //       questionData['correctAnswer'];
                                      // }
                                      // --- CẬP NHẬT LOGIC CHECK ---
                                      bool isCorrect = false;
                                      final rawCorrect =
                                          questionData['correctAnswer'];

                                      if (rawCorrect is List) {
                                        isCorrect = rawCorrect
                                            .map((e) => e.toString())
                                            .contains(letter);
                                      } else {
                                        isCorrect =
                                            rawCorrect.toString() == letter;
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCorrect
                                              ? Colors.green.shade50
                                              : Colors.grey.shade50,
                                          border: Border.all(
                                            color: isCorrect
                                                ? Colors.green
                                                : Colors.grey.shade300,
                                            width: isCorrect ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isCorrect
                                                    ? Colors.green
                                                    : Colors.grey.shade400,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  letter,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(optEntry.value),
                                            ),
                                            if (isCorrect)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.green,
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleBanner(QuizSchedule schedule) {
    Color bannerColor;
    IconData bannerIcon;
    String bannerText;
    List<String> details = [];

    if (schedule.isClosed) {
      bannerColor = Colors.red;
      bannerIcon = Icons.lock;
      bannerText = 'Đề thi đã đóng';
      if (schedule.closeTime != null) {
        details.add('Đóng lúc: ${_formatDateTime(schedule.closeTime!)}');
      }
    } else if (schedule.isOpen) {
      bannerColor = Colors.green;
      bannerIcon = Icons.lock_open;
      bannerText = 'Đề thi đang mở';
      if (schedule.closeTime != null) {
        details.add('Đóng lúc: ${_formatDateTime(schedule.closeTime!)}');
      }
    } else {
      bannerColor = Colors.orange;
      bannerIcon = Icons.schedule;
      bannerText = 'Đề thi đã lên lịch';
      if (schedule.openTime != null) {
        details.add('Mở lúc: ${_formatDateTime(schedule.openTime!)}');
      }
      if (schedule.closeTime != null) {
        details.add('Đóng lúc: ${_formatDateTime(schedule.closeTime!)}');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 20),
              const SizedBox(width: 8),
              Text(
                bannerText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: bannerColor,
                ),
              ),
              const Spacer(),
              // Quick actions
              if (schedule.isScheduled)
                TextButton.icon(
                  onPressed: () => _openQuizNow(schedule),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Mở ngay', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              if (schedule.isOpen)
                TextButton.icon(
                  onPressed: () => _closeQuizNow(schedule),
                  icon: const Icon(Icons.lock, size: 16),
                  label: const Text(
                    'Đóng ngay',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: bannerColor),
                        const SizedBox(width: 6),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 13,
                            color: bannerColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _manageSchedule(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => QuizScheduleDialog(
        classId: widget.classId,
        quizId: widget.quizId,
        quizTitle: widget.quizData['title'] ?? 'Đề thi',
        existingSchedule: _currentSchedule,
      ),
    );

    if (result == true) {
      // Reload schedule
      await _loadSchedule();
    }
  }

  Future<void> _openQuizNow(QuizSchedule schedule) async {
    try {
      await QuizScheduleService.openQuizNow(widget.classId, widget.quizId);
      await _loadSchedule();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã mở đề thi'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _closeQuizNow(QuizSchedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đóng'),
        content: const Text('Bạn có chắc muốn đóng đề thi này ngay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await QuizScheduleService.closeQuizNow(widget.classId, widget.quizId);
      await _loadSchedule();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã đóng đề thi'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editQuiz(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditQuizPage(quizId: widget.quizId, quizData: widget.quizData),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Đề thi đã được cập nhật'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      // Refresh page
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClassQuizDetailPage(
            classId: widget.classId,
            quizId: widget.quizId,
            quizData: widget.quizData,
          ),
        ),
      );
    }
  }
}
