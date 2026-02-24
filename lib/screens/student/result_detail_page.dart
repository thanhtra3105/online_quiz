// lib/screens/student/result_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';

class ResultDetailPage extends StatelessWidget {
  final String submissionId;

  const ResultDetailPage({Key? key, required this.submissionId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Chi tiết kết quả'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseService.getSubmissionById(submissionId),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final answers = Map<String, dynamic>.from(data['answers'] ?? {});
          final quizId = data['quizId'] ?? '';
          final classId =
              data['classId'] ?? ''; // Cần lấy classId để truy vấn Quiz Setting

          // --- SỬA ĐỔI CHÍNH Ở ĐÂY ---
          // Sử dụng Future.wait để lấy song song:
          // 1. Danh sách câu hỏi (để tính điểm)
          // 2. Thông tin bài thi (để check quyền xem chi tiết)
          return FutureBuilder<List<dynamic>>(
            future: Future.wait([
              FirebaseService.getQuizQuestionsOnce(quizId),
              FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .collection('quizzes')
                  .doc(quizId)
                  .get(),
            ]),
            builder: (context, compositeSnapshot) {
              if (!compositeSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              // Lấy dữ liệu từ kết quả Future.wait
              final questionSnapshot =
                  compositeSnapshot.data![0] as QuerySnapshot;
              final quizDocSnapshot =
                  compositeSnapshot.data![1] as DocumentSnapshot;

              // Check quyền xem chi tiết (Mặc định là FALSE nếu chưa setup)
              final quizData = quizDocSnapshot.data() as Map<String, dynamic>?;
              final bool allowViewDetail =
                  quizData?['allowViewDetail'] ?? false;

              final questions = questionSnapshot.docs;

              // --- TÍNH TOÁN LẠI (Giữ nguyên logic tính điểm) ---
              double calculatedTotalScore = 0.0;
              int correctQuestionsCount = 0;
              Map<String, double> questionScores = {};

              for (var doc in questions) {
                final qData = doc.data() as Map<String, dynamic>;
                final rawCorrect = qData['correctAnswer'];
                final rawUser = answers[doc.id];

                double points = _calculateQuestionScore(rawCorrect, rawUser);
                questionScores[doc.id] = points;
                calculatedTotalScore += points;

                if (points >= 0.99) {
                  correctQuestionsCount++;
                }
              }

              double maxPossibleScore = questions.length.toDouble();
              String percentage = maxPossibleScore > 0
                  ? ((calculatedTotalScore / maxPossibleScore) * 100)
                        .toStringAsFixed(0)
                  : '0';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Luôn hiển thị bảng điểm tổng quát
                    _buildScoreCard(
                      context,
                      data,
                      correctQuestionsCount,
                      questions.length,
                      percentage,
                    ),
                    const SizedBox(height: 24),

                    // --- ĐIỀU KIỆN HIỂN THỊ CHI TIẾT ---
                    if (allowViewDetail) ...[
                      const Text(
                        'Chi tiết bài làm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: questions.asMap().entries.map((entry) {
                          return _buildQuestionDetail(
                            entry.key,
                            entry.value,
                            answers[entry.value.id],
                            questionScores[entry.value.id] ?? 0.0,
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      // UI khi bị ẩn chi tiết
                      _buildHiddenDetailMessage(),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget hiển thị thông báo khi giáo viên ẩn kết quả
  Widget _buildHiddenDetailMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_off_rounded,
                size: 40,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chi tiết chưa được công bố',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Giáo viên tạm thời ẩn đáp án chi tiết của bài thi này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM LOGIC CŨ (GIỮ NGUYÊN) ---

  // Logic tính điểm giữ nguyên
  double _calculateQuestionScore(dynamic rawCorrect, dynamic rawUser) {
    if (rawUser == null) return 0.0;
    List<String> correctList = _normalizeToList(rawCorrect);
    List<String> userList = _normalizeToList(rawUser);

    if (correctList.isEmpty) return 0.0;

    if (correctList.length > 1 || rawCorrect is List) {
      double unitScore = 1.0 / correctList.length;
      double penaltyScore = 2.0 * unitScore;
      double currentScore = 0.0;
      for (var ans in userList) {
        if (correctList.contains(ans))
          currentScore += unitScore;
        else
          currentScore -= penaltyScore;
      }
      if (currentScore < 0) return 0.0;
      if (currentScore > 1.0) return 1.0;
      return currentScore;
    } else {
      if (userList.isNotEmpty && correctList.contains(userList.first))
        return 1.0;
      return 0.0;
    }
  }

  List<String> _normalizeToList(dynamic input) {
    if (input == null) return [];
    if (input is List) return input.map((e) => e.toString().trim()).toList();
    return [input.toString().trim()];
  }

  // --- UI THẺ ĐIỂM (Giữ nguyên) ---
  Widget _buildScoreCard(
    BuildContext context,
    Map<String, dynamic> data,
    int correctCount,
    int totalCount,
    String scorePoints,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            data['quizTitle'] ?? 'Kết quả',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Câu đúng', '$correctCount/$totalCount'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatColumn('Điểm số', '$scorePoints/100'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Nộp bài: ${_formatTimestamp(data['timestamp'])}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  // --- UI CHI TIẾT CÂU HỎI (Giữ nguyên) ---
  Widget _buildQuestionDetail(
    int index,
    DocumentSnapshot questionDoc,
    dynamic userAnswer,
    double earnedScore,
  ) {
    final data = questionDoc.data() as Map<String, dynamic>;
    final questionText = data['question'] ?? '';
    final options = List<String>.from(data['options'] ?? []);
    final List<String> correctList = _normalizeToList(data['correctAnswer']);
    final List<String> userList = _normalizeToList(userAnswer);

    Color statusColor = earnedScore >= 0.99
        ? Colors.green
        : (earnedScore > 0 ? Colors.orange : Colors.red);
    IconData statusIcon = earnedScore >= 0.99
        ? Icons.check_circle
        : (earnedScore > 0 ? Icons.warning_rounded : Icons.cancel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    Text(
                      '${_formatScore(earnedScore)}đ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: options.asMap().entries.map((optEntry) {
                final letter = String.fromCharCode(65 + optEntry.key);
                final text = optEntry.value;
                bool isCorrectOption = correctList.contains(letter);
                bool isUserSelected = userList.contains(letter);

                Color bgColor = Colors.transparent;
                Color borderColor = Colors.grey.shade200;
                IconData? icon;

                if (isCorrectOption) {
                  borderColor = Colors.green.shade300;
                  bgColor = Colors.green.shade50;
                  icon = Icons.check_circle_outline;
                }
                if (isUserSelected) {
                  if (isCorrectOption) {
                    bgColor = Colors.green.shade100;
                    borderColor = Colors.green;
                    icon = Icons.check_circle;
                  } else {
                    bgColor = Colors.red.shade50;
                    borderColor = Colors.red.shade300;
                    icon = Icons.cancel;
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: isUserSelected || isCorrectOption
                                ? borderColor
                                : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isUserSelected && !isCorrectOption
                                ? Colors.red.shade900
                                : Colors.black87,
                            fontWeight: isUserSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (icon != null)
                        Icon(
                          icon,
                          color: isUserSelected && !isCorrectOption
                              ? Colors.red
                              : Colors.green,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(double score) =>
      score.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp)
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    return 'N/A';
  }
}
