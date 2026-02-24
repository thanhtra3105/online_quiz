// lib/screens/student/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatefulWidget {
  final String studentId;
  final String classId;

  const HistoryPage({Key? key, required this.studentId, required this.classId})
    : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_edu_rounded,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch sử bài thi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Xem lại điểm số và chi tiết bài làm',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('classId', isEqualTo: widget.classId)
                .where('studentId', isEqualTo: widget.studentId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                // print(snapshot.error); // Debug lỗi nếu cần
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 60,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đã xảy ra lỗi tải dữ liệu',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final submissions = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final doc = submissions[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final score = data['score'] ?? 0;
                  final total = data['totalQuestions'] ?? 1;
                  final percentage = (score / total * 100);
                  final scoreColor = _getScoreColor(percentage);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () =>
                            _showSubmissionDetail(context, doc.id, data),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Score Circle
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      scoreColor.withOpacity(0.8),
                                      scoreColor,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scoreColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${score is double ? score.toStringAsFixed(1) : score}/$total',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['quizTitle'] ?? 'Bài thi',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(data['timestamp']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Thời gian làm: ${_formatDuration(data['timeSpent'] ?? 0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action Button
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa làm bài thi nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green.shade600;
    if (percentage >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}p ${secs}s';
  }

  Future<void> _showSubmissionDetail(
    BuildContext context,
    String submissionId,
    Map<String, dynamic> submission,
  ) async {
    final quizId = submission['quizId'] as String?;

    if (quizId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Lấy danh sách câu hỏi
      final questionsFuture = FirebaseFirestore.instance
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      // 2. Lấy thông tin bài thi để check 'allowViewDetail'
      // Sử dụng widget.classId vì submission nằm trong class đó
      final quizInfoFuture = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .get();

      final results = await Future.wait([questionsFuture, quizInfoFuture]);

      final questionsSnapshot = results[0] as QuerySnapshot;
      final quizDoc = results[1] as DocumentSnapshot;

      // Lấy trạng thái cho phép xem (Mặc định là false)
      final bool allowViewDetail =
          (quizDoc.data() as Map<String, dynamic>?)?['allowViewDetail'] ??
          false;

      if (!context.mounted) return;
      Navigator.pop(context); // Hide loading

      final studentAnswers =
          submission['answers'] as Map<String, dynamic>? ?? {};

      showDialog(
        context: context,
        builder: (context) => _DetailDialog(
          submission: submission,
          questions: questionsSnapshot.docs,
          studentAnswers: studentAnswers,
          allowViewDetail: allowViewDetail, // Truyền biến này vào Dialog
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Hide loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải đề thi: $e')));
    }
  }
}

// Dialog chi tiết bài làm
class _DetailDialog extends StatelessWidget {
  final Map<String, dynamic> submission;
  final List<QueryDocumentSnapshot> questions;
  final Map<String, dynamic> studentAnswers;
  final bool allowViewDetail; // Biến mới để check quyền xem

  const _DetailDialog({
    required this.submission,
    required this.questions,
    required this.studentAnswers,
    required this.allowViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final score = submission['score'] ?? 0;
    final total = submission['totalQuestions'] ?? 1;
    final percentage = (score / total * 100);
    final timeSpent = submission['timeSpent'] ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết bài làm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          submission['quizTitle'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats Bar (Luôn hiển thị điểm)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.grade_rounded,
                    score is double
                        ? score.toStringAsFixed(1)
                        : score.toString(),
                    'Số câu đúng',
                    Colors.blue,
                  ),
                  _buildStatItem(
                    Icons.timer_rounded,
                    _formatTime(timeSpent),
                    'Thời gian',
                    Colors.orange,
                  ),
                  _buildStatItem(
                    Icons.percent_rounded,
                    '${percentage.toStringAsFixed(1)}%',
                    'Phần trăm',
                    Colors.green,
                  ),
                ],
              ),
            ),

            // Questions List OR Hidden Message
            Expanded(
              child: allowViewDetail
                  ? _buildQuestionsList() // Nếu được phép xem -> Hiện danh sách
                  : _buildHiddenMessage(), // Nếu không -> Hiện thông báo ẩn
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị khi bị ẩn
  Widget _buildHiddenMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_off_rounded,
                size: 50,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chi tiết chưa được công bố',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Giáo viên đã ẩn đáp án chi tiết của bài thi này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị danh sách câu hỏi (Logic cũ tách ra)
  Widget _buildQuestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final questionDoc = questions[index];
        final questionData = questionDoc.data() as Map<String, dynamic>;
        final questionId = questionDoc.id;
        final rawCorrect = questionData['correctAnswer'];
        final rawStudent = studentAnswers[questionId];

        bool isCorrect = _checkAnswerCorrect(rawCorrect, rawStudent);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCorrect ? Colors.green : Colors.red).withOpacity(
                  0.05,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Câu ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        questionData['question'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Options
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: () {
                    final options = questionData['options'] as List;
                    return List.generate(options.length, (i) {
                      final letter = String.fromCharCode(65 + i);

                      bool isCorrectOption = _isCorrectOption(
                        rawCorrect,
                        letter,
                      );
                      bool isStudentSelected = _isStudentSelected(
                        rawStudent,
                        letter,
                      );

                      Color bgColor = Colors.white;
                      Color borderColor = Colors.grey.shade200;
                      Color textColor = Colors.black87;
                      IconData? icon;

                      if (isCorrectOption) {
                        bgColor = Colors.green.shade50;
                        borderColor = Colors.green.shade400;
                        textColor = Colors.green.shade800;
                        icon = Icons.check_circle_rounded;
                      } else if (isStudentSelected) {
                        bgColor = Colors.red.shade50;
                        borderColor = Colors.red.shade400;
                        textColor = Colors.red.shade800;
                        icon = Icons.cancel_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCorrectOption
                                    ? Colors.green
                                    : (isStudentSelected
                                          ? Colors.red
                                          : Colors.grey.shade300),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    color: isStudentSelected || isCorrectOption
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[i],
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (icon != null)
                              Icon(icon, color: borderColor, size: 20),
                          ],
                        ),
                      );
                    });
                  }(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ HELPER FUNCTIONS (Giữ nguyên)
  bool _checkAnswerCorrect(dynamic correct, dynamic student) {
    if (student == null) return false;
    if (correct is List) {
      if (student is! List) return false;
      final correctSet = Set.from(correct.map((e) => e.toString()));
      final studentSet = Set.from(student.map((e) => e.toString()));
      return correctSet.length == studentSet.length &&
          correctSet.containsAll(studentSet);
    } else {
      return student.toString() == correct.toString();
    }
  }

  bool _isCorrectOption(dynamic correct, String letter) {
    if (correct is List) {
      return correct.map((e) => e.toString()).contains(letter);
    } else {
      return correct.toString() == letter;
    }
  }

  bool _isStudentSelected(dynamic student, String letter) {
    if (student == null) return false;
    if (student is List) {
      return student.map((e) => e.toString()).contains(letter);
    } else {
      return student.toString() == letter;
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
