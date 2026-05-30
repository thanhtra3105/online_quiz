// lib/screens/teacher/class_results_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
// import 'package:file_picker/file_picker.dart'; // Có thể bỏ nếu không dùng
import 'dart:typed_data';

class ClassResultsPage extends StatefulWidget {
  final String classId;

  const ClassResultsPage({Key? key, required this.classId}) : super(key: key);

  @override
  State<ClassResultsPage> createState() => _ClassResultsPageState();
}

class _ClassResultsPageState extends State<ClassResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'studentId';
  bool _sortAscending = false;

  // Real stats variables
  double _averageScore = 0.0;
  double _completionRate = 0.0;
  int _submittedCount = 0;
  bool _isLoadingStats = true;

  // Theo dõi trạng thái export của từng quiz để hiển thị loading spinner riêng biệt
  final Map<String, bool> _exportingStates = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final studentsSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .get();
      final totalStudents = studentsSnap.docs.length;

      final quizzesSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .get();
      final totalQuizzes = quizzesSnap.docs.length;

      final submissionsSnap = await FirebaseFirestore.instance
          .collection('submissions')
          .where('classId', isEqualTo: widget.classId)
          .get();

      final totalSubmissions = submissionsSnap.docs.length;

      double totalScore = 0.0;
      for (var doc in submissionsSnap.docs) {
        final data = doc.data();
        final rawScore = (data['score'] ?? 0).toDouble();
        final totalQ = (data['totalQuestions'] ?? 1).toDouble();
        if (totalQ > 0) {
          final score10 = (rawScore / totalQ) * 10;
          totalScore += score10;
        }
      }

      double avgScore = totalSubmissions > 0 ? totalScore / totalSubmissions : 0.0;
      double compRate = 0.0;
      if (totalStudents > 0 && totalQuizzes > 0) {
        compRate = (totalSubmissions / (totalStudents * totalQuizzes)) * 100;
        if (compRate > 100) compRate = 100;
      }

      if (mounted) {
        setState(() {
          _averageScore = avgScore;
          _completionRate = compRate;
          _submittedCount = totalSubmissions;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm lấy tên học sinh (giữ nguyên)
  Future<String> _getStudentName(String studentId) async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        return studentDoc.data()?['name'] ?? 'Không có tên';
      }
      return 'Không có tên';
    } catch (e) {
      return 'Không có tên';
    }
  }

  // --- HÀM XUẤT EXCEL CHO TỪNG BÀI THI ---
  Future<void> _exportQuizToExcel(String quizId, String quizTitle) async {
    setState(() => _exportingStates[quizId] = true);

    try {
      // 1. Lấy dữ liệu submissions CHỈ của quizId này
      final submissionsSnapshot = await FirebaseFirestore.instance
          .collection('submissions')
          .where('classId', isEqualTo: widget.classId)
          .where('quizId', isEqualTo: quizId)
          .get();

      if (submissionsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Không có dữ liệu để xuất cho bài thi này'),
            ),
          );
        }
        return;
      }

      var submissions = submissionsSnapshot.docs;

      // Sắp xếp mặc định theo MSSV để file excel dễ nhìn
      submissions.sort((a, b) {
        final idA = (a.data()['studentId'] ?? '').toString();
        final idB = (b.data()['studentId'] ?? '').toString();
        return idA.compareTo(idB);
      });

      // 2. Tạo Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Kết quả'];
      excel.delete('Sheet1'); // Xóa sheet mặc định

      // Style
      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers
      List<String> headers = ['STT', 'Mã sinh viên', 'Họ và tên', 'Điểm số'];

      // Vẽ Header
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // 3. Ghi dữ liệu
      for (int i = 0; i < submissions.length; i++) {
        final data = submissions[i].data();
        final studentId = data['studentId'] ?? 'Unknown';
        final studentName =
            data['studentName'] ?? await _getStudentName(studentId);
        final totalQ = data['totalQuestions'] ?? 1;
        final rawScore = (data['score'] ?? 0) / totalQ * 10;
        final score = double.parse(rawScore.toStringAsFixed(1));

        int rowIndex = i + 1;

        List<dynamic> rowData = [i + 1, studentId, studentName, score];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );

          if (rowData[j] is int) {
            cell.value = IntCellValue(rowData[j]);
          } else if (rowData[j] is double) {
            cell.value = DoubleCellValue(rowData[j]);
          } else {
            cell.value = TextCellValue(rowData[j].toString());
          }
        }
      }

      // Auto-fit (tương đối)
      for (int i = 0; i < headers.length; i++)
        sheetObject.setColumnWidth(i, 20);

      // 4. Lưu file
      // Làm sạch tên file để tránh lỗi ký tự đặc biệt
      final cleanQuizTitle = quizTitle
          .replaceAll(RegExp(r'[^\w\s\u00C0-\u1EF9]+'), '')
          .trim();
      final fileName = 'Result_${cleanQuizTitle}.xlsx';

      var fileBytes = excel.save(fileName: fileName);
      if (fileBytes == null) throw Exception('Không thể tạo file');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xuất kết quả bài: $quizTitle'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exportingStates[quizId] = false);
      }
    }
  }

  String _formatDateForExcel(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analytics Row (Bento Stats)
        Row(
          children: [
            Expanded(child: _buildBentoStatCard('Điểm trung bình', _isLoadingStats ? '--' : _averageScore.toStringAsFixed(1), const Color(0xFF003D9B))),
            const SizedBox(width: 24),
            Expanded(child: _buildBentoStatCard('Tỷ lệ hoàn thành', _isLoadingStats ? '--' : '${_completionRate.toStringAsFixed(1)}%', const Color(0xFF006C47))),
            const SizedBox(width: 24),
            Expanded(child: _buildBentoStatCard('Đã nộp', _isLoadingStats ? '--' : '$_submittedCount', const Color(0xFF041B3C))),
          ],
        ),
        const SizedBox(height: 32),

        // Title and Filter Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Danh sách điểm thi', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF041B3C))),
            Row(
              children: [
                // Search Box
                Container(
                  width: 300,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Color(0xFF737685), size: 20),
                      hintText: 'Tìm kiếm bài thi...',
                      hintStyle: TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 12), // Center align text
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      if (value == 'mssv_asc') {
                        _sortBy = 'studentId';
                        _sortAscending = true;
                      } else if (value == 'score_desc') {
                        _sortBy = 'score';
                        _sortAscending = false;
                      }
                    });
                  },
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mssv_asc',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 20, color: _sortBy == 'studentId' ? const Color(0xFF0B57D0) : const Color(0xFF434654)),
                          const SizedBox(width: 12),
                          Text(
                            'Mã số SV (Thấp → Cao)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _sortBy == 'studentId' ? const Color(0xFF0B57D0) : const Color(0xFF434654),
                              fontWeight: _sortBy == 'studentId' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'score_desc',
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 20, color: _sortBy == 'score' ? const Color(0xFF0B57D0) : const Color(0xFF434654)),
                          const SizedBox(width: 12),
                          Text(
                            'Điểm số (Cao → Thấp)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: _sortBy == 'score' ? const Color(0xFF0B57D0) : const Color(0xFF434654),
                              fontWeight: _sortBy == 'score' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFC3C6D6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.filter_list, color: Color(0xFF434654), size: 18),
                        SizedBox(width: 8),
                        Text('Lọc', style: TextStyle(color: Color(0xFF434654))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quiz Results List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('quizzes')
                .snapshots(),
            builder: (context, quizSnapshot) {
              if (quizSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!quizSnapshot.hasData || quizSnapshot.data!.docs.isEmpty) {
                return _buildEmptyState('Lớp học chưa có bài thi nào');
              }

              var quizzes = quizSnapshot.data!.docs;
              
              if (_searchQuery.isNotEmpty) {
                 quizzes = quizzes.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery);
                 }).toList();
              }

              return ListView.builder(
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quizDoc = quizzes[index];
                  final quizData = quizDoc.data() as Map<String, dynamic>;
                  final quizTitle = quizData['title'] ?? 'Bài thi không tên';
                  final quizId = quizDoc.id;

                  return _buildQuizGroup(quizId, quizTitle, quizData);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatCard(String title, String value, Color valueColor, {String? trending}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF434654))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: valueColor)),
              if (trending != null) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Color(0xFF006C47)),
                    const SizedBox(width: 4),
                    Text(trending, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF006C47))),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET NHÓM KẾT QUẢ THEO BÀI THI ---
  Widget _buildQuizGroup(
    String quizId,
    String quizTitle,
    Map<String, dynamic> quizData,
  ) {
    final bool isExporting = _exportingStates[quizId] ?? false;
    final bool allowViewDetail = quizData['allowViewDetail'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          title: Text(
            quizTitle,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF041B3C)),
          ),
          subtitle: Text(
            allowViewDetail
                ? 'Đang CÔNG KHAI chi tiết'
                : 'Đang ẨN chi tiết bài làm',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: allowViewDetail ? const Color(0xFF00734C) : const Color(0xFF434654),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- NÚT BẬT/TẮT XEM KẾT QUẢ ---
              Tooltip(
                message: allowViewDetail
                    ? 'Tắt xem chi tiết'
                    : 'Bật cho SV xem chi tiết',
                child: Switch(
                  value: allowViewDetail,
                  activeColor: Colors.green,
                  onChanged: (bool value) async {
                    // Cập nhật lên Firestore
                    try {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(widget.classId)
                          .collection('quizzes')
                          .doc(quizId)
                          .update({'allowViewDetail': value});

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Đã mở xem chi tiết cho sinh viên'
                                  : 'Đã ẩn chi tiết bài làm',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Lỗi cập nhật: $e');
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Nút Export Excel (Giữ nguyên)
              ElevatedButton.icon(
                onPressed: isExporting
                    ? null
                    : () => _exportQuizToExcel(quizId, quizTitle),
                icon: isExporting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download_outlined, size: 20),
                label: Text(
                  isExporting ? '...' : 'Kết quả',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600, // Đổi màu xanh cho đẹp
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          children: [
            // ... (Giữ nguyên phần StreamBuilder danh sách sinh viên bên dưới)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('submissions')
                  .where('classId', isEqualTo: widget.classId)
                  .where('quizId', isEqualTo: quizId)
                  .snapshots(),
              builder: (context, subSnapshot) {
                // ... (Code cũ của phần danh sách sinh viên giữ nguyên) ...
                // Để code ngắn gọn tôi không paste lại đoạn logic list view sinh viên
                // Bạn hãy giữ nguyên code StreamBuilder bên trong children như cũ
                if (!subSnapshot.hasData)
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                // ... logic hiển thị list ...
                // (Copy lại nội dung bên trong children của câu trả lời trước)
                var submissions = subSnapshot.data!.docs;

                // ... (Paste lại logic filter/sort cũ vào đây) ...
                // Removed submission filtering by _searchQuery here, as it conflicts with quiz title search

                // Apply Sorting
                submissions.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  if (_sortBy == 'studentId') {
                    final idA = (dataA['studentId'] ?? '').toString();
                    final idB = (dataB['studentId'] ?? '').toString();
                    return _sortAscending ? idA.compareTo(idB) : idB.compareTo(idA);
                  } else if (_sortBy == 'score') {
                    final scoreA = (dataA['score'] ?? 0) as num;
                    final scoreB = (dataB['score'] ?? 0) as num;
                    return _sortAscending ? scoreA.compareTo(scoreB) : scoreB.compareTo(scoreA);
                  }
                  return 0;
                });

                if (submissions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Chưa có bài nộp",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(height: 1, color: Colors.grey.shade100),
                    ...submissions
                        .map((doc) => _buildStudentResultItem(doc))
                        .toList(),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentResultItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final score = data['score'] ?? 0;
    final total = data['totalQuestions'] ?? 1;
    final percentage = (score / total * 100);
    final scoreColor = _getScoreColor(percentage);
    final studentId = data['studentId'] ?? 'Unknown';
    final studentName = data['studentName'] as String?;
    final suspiciousCount = data['suspiciousActionCount'] ?? 0;

    return InkWell(
      onTap: () async {
        String resolvedName = studentName ?? await _getStudentName(studentId);
        if (context.mounted) {
          _showSubmissionDetail(context, doc.id, data, resolvedName);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
        ),
        child: Row(
          children: [
            // Điểm số (Badge nhỏ gọn)
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Thông tin sinh viên
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  studentName != null
                      ? Text(
                          studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        )
                      : FutureBuilder<String>(
                          future: _getStudentName(studentId),
                          builder: (c, s) => Text(
                            s.data ?? '...',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'MSSV: $studentId',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  $score/$total câu',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cảnh báo (nếu có)
            if (suspiciousCount > 0)
              Tooltip(
                message: '$suspiciousCount hành vi đáng ngờ',
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),

            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM TIỆN ÍCH KHÁC (GIỮ NGUYÊN LOGIC CŨ) ---
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500])),
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
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month} ${date.hour}:${date.minute}';
  }

  // Giữ nguyên hàm _showSubmissionDetail và _SubmissionDetailDialog của bạn ở phía dưới
  // ... (Copy phần dialog cũ vào đây) ...
  Future<void> _showSubmissionDetail(
    BuildContext context,
    String submissionId,
    Map<String, dynamic> submission,
    String studentName,
  ) async {
    final quizId = submission['quizId'] as String?;

    if (quizId == null) return;

    final questionsSnapshot = await FirebaseFirestore.instance
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();

    if (!context.mounted) return;

    final studentAnswers = submission['answers'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailDialog(
        submission: submission,
        questions: questionsSnapshot.docs,
        studentAnswers: studentAnswers,
        studentName: studentName,
      ),
    );
  }
}

// Dialog chi tiết submission (giữ nguyên như code cũ)
class _SubmissionDetailDialog extends StatelessWidget {
  final Map<String, dynamic> submission;
  final List<QueryDocumentSnapshot> questions;
  final Map<String, dynamic> studentAnswers;
  final String studentName;

  const _SubmissionDetailDialog({
    required this.submission,
    required this.questions,
    required this.studentAnswers,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final score = submission['score'] ?? 0;
    final total = submission['totalQuestions'] ?? 1;
    final percentage = (score / total * 100);
    final timeSpent = submission['timeSpent'] ?? 0;
    final suspiciousCount = submission['suspiciousActionCount'] ?? 0;
    final cheatingDetected = submission['cheatingDetected'] ?? false;
    final autoSubmitted = submission['autoSubmitted'] ?? false;
    final studentId = submission['studentId'] ?? 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF9F9FF),
        ),
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0B57D0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'MSSV: $studentId • ${submission['quizTitle'] ?? 'BT'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.check_circle_rounded,
                      '$score',
                      'Đúng',
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      Icons.cancel_rounded,
                      '${total - score}',
                      'Sai',
                      const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      Icons.timer_rounded,
                      _formatTime(timeSpent),
                      'Thời gian',
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      Icons.star_rounded,
                      '${percentage.toStringAsFixed(1)}%',
                      'Điểm số',
                      const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),

                  if (suspiciousCount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cheatingDetected
                            ? Colors.red.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cheatingDetected
                              ? Colors.red.shade300
                              : Colors.orange.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cheatingDetected
                                ? Icons.block_rounded
                                : Icons.warning_amber_rounded,
                            color: cheatingDetected
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  autoSubmitted
                                      ? 'Tự động nộp do vi phạm'
                                      : 'Có hành vi khả nghi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cheatingDetected
                                        ? Colors.red.shade900
                                        : Colors.orange.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$suspiciousCount vi phạm được ghi nhận',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cheatingDetected
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cheatingDetected
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$suspiciousCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: cheatingDetected
                                    ? Colors.red.shade900
                                    : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

            // Questions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final questionDoc = questions[index];
                  final questionData =
                      questionDoc.data() as Map<String, dynamic>;
                  final questionId = questionDoc.id;
                  final correctAnswer = questionData['correctAnswer'] ?? '';
                  final studentAnswer = studentAnswers[questionId] ?? '';
                  final isCorrect = studentAnswer == correctAnswer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
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
                                  color: const Color(0xFFA7F3D0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Câu ${index + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    questionData['question'],
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: () {
                              final options = questionData['options'] as List;
                              final questionType = questionData['type'] ?? 'single';

                              return List.generate(options.length, (i) {
                                final letter = String.fromCharCode(65 + i);

                                bool isCorrectOption;
                                bool isStudentChoice;

                                if (questionType == 'multiple') {
                                  final correctAnswers = correctAnswer is List
                                      ? List<String>.from(correctAnswer)
                                      : [correctAnswer.toString()];

                                  final studentAnswers = studentAnswer is List
                                      ? List<String>.from(studentAnswer)
                                      : (studentAnswer != null &&
                                            studentAnswer.toString().isNotEmpty)
                                      ? [studentAnswer.toString()]
                                      : <String>[];

                                  isCorrectOption = correctAnswers.contains(letter);
                                  isStudentChoice = studentAnswers.contains(letter);
                                } else {
                                  isCorrectOption = letter == correctAnswer;
                                  isStudentChoice = letter == studentAnswer;
                                }

                                Color bgColor = Colors.white;
                                Color borderColor = const Color(0xFFE5E7EB);
                                Color textColor = const Color(0xFF111827);
                                Color circleColor = Colors.transparent;
                                Color circleBorderColor = const Color(0xFFD1D5DB);
                                Color circleTextColor = const Color(0xFF4B5563);
                                Widget? rightWidget;

                                if (isCorrectOption && isStudentChoice) {
                                  // Right and chosen -> solid green outline, solid green circle
                                  borderColor = const Color(0xFF059669);
                                  textColor = const Color(0xFF065F46);
                                  circleColor = const Color(0xFF059669);
                                  circleBorderColor = const Color(0xFF059669);
                                  circleTextColor = Colors.white;
                                  rightWidget = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                                      SizedBox(width: 6),
                                      Text('ĐÁP ÁN ĐÚNG', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                    ],
                                  );
                                } else if (isCorrectOption) {
                                  // Right but not chosen -> show as correct option with light green background
                                  bgColor = const Color(0xFFECFDF5);
                                  borderColor = const Color(0xFF059669);
                                  circleColor = Colors.white;
                                  circleBorderColor = const Color(0xFF059669);
                                  circleTextColor = const Color(0xFF059669);
                                  rightWidget = const Text('ĐÁP ÁN ĐÚNG', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)));
                                } else if (isStudentChoice) {
                                  // Wrong and chosen -> red outline
                                  borderColor = const Color(0xFFDC2626);
                                  textColor = const Color(0xFF991B1B);
                                  circleColor = const Color(0xFFDC2626);
                                  circleBorderColor = const Color(0xFFDC2626);
                                  circleTextColor = Colors.white;
                                  rightWidget = const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 20);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor, width: isStudentChoice || isCorrectOption ? 1.5 : 1.0),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: circleColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: circleBorderColor),
                                        ),
                                        child: Center(
                                          child: Text(
                                            letter,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: circleTextColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          options[i].toString(),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: isStudentChoice || isCorrectOption ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (rightWidget != null) rightWidget,
                                    ],
                                  ),
                                );
                              });
                            }(),
                          ),
                        ),
                        // Removed the previous evaluation footer or keep if needed? I'll keep it simple
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(isCorrect ? Icons.check_circle_outline : Icons.highlight_off_outlined, size: 16, color: isCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                                  const SizedBox(width: 6),
                                  Text(
                                    isCorrect ? 'Đã chấm điểm: +1.0' : 'Đã chấm điểm: +0.0',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: isCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const Text('Xem giải thích ⓘ', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF3B82F6))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}
