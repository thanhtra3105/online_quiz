// lib/screens/teacher/class_results_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
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

  // Theo dõi trạng thái export của từng quiz để hiển thị loading spinner riêng biệt
  final Map<String, bool> _exportingStates = {};

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
      children: [
        // --- HEADER CỐ ĐỊNH (Tìm kiếm & Tiêu đề) ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Kết quả thi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thanh tìm kiếm chung
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm sinh viên theo MSSV trong các bài thi...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),

              const SizedBox(height: 10),

              // Bộ lọc sắp xếp nhỏ gọn
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Sắp xếp theo:",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    underline: Container(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'studentId',
                        child: Text('Mã SV'),
                      ),
                      DropdownMenuItem(value: 'score', child: Text('Điểm số')),
                      DropdownMenuItem(value: 'time', child: Text('Thời gian')),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v!),
                  ),
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: Colors.blue,
                    ),
                    onPressed: () =>
                        setState(() => _sortAscending = !_sortAscending),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- DANH SÁCH BÀI THI (Main Content) ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // 1. Lấy danh sách QUIZZES trước
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

              final quizzes = quizSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quizDoc = quizzes[index];
                  final quizData = quizDoc.data() as Map<String, dynamic>;
                  final quizTitle = quizData['title'] ?? 'Bài thi không tên';
                  final quizId = quizDoc.id;

                  // Gọi widget con hiển thị từng nhóm bài thi
                  return _buildQuizGroup(quizId, quizTitle, quizData);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- WIDGET NHÓM KẾT QUẢ THEO BÀI THI ---
  // --- WIDGET NHÓM KẾT QUẢ THEO BÀI THI ---
  Widget _buildQuizGroup(
    String quizId,
    String quizTitle,
    Map<String, dynamic> quizData,
  ) {
    final bool isExporting = _exportingStates[quizId] ?? false;

    // Lấy trạng thái cho phép xem điểm (mặc định là false nếu chưa có field này)
    final bool allowViewDetail = quizData['allowViewDetail'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in,
              color: Colors.blue.shade700,
            ),
          ),
          title: Text(
            quizTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // Thay đổi subtitle để hiển thị trạng thái
          subtitle: Text(
            allowViewDetail
                ? 'Đang CÔNG KHAI chi tiết'
                : 'Đang ẨN chi tiết bài làm',
            style: TextStyle(
              fontSize: 12,
              color: allowViewDetail ? Colors.green : Colors.grey,
              fontWeight: allowViewDetail ? FontWeight.bold : FontWeight.normal,
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
                if (_searchQuery.isNotEmpty) {
                  submissions = submissions.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sId = (data['studentId'] ?? '')
                        .toString()
                        .toLowerCase();
                    final sName = (data['studentName'] ?? '')
                        .toString()
                        .toLowerCase();
                    return sId.contains(_searchQuery) ||
                        sName.contains(_searchQuery);
                  }).toList();
                }

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
      onTap: () => _showSubmissionDetail(context, doc.id, data),
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
      ),
    );
  }
}

// Dialog chi tiết submission (giữ nguyên như code cũ)
class _SubmissionDetailDialog extends StatelessWidget {
  final Map<String, dynamic> submission;
  final List<QueryDocumentSnapshot> questions;
  final Map<String, dynamic> studentAnswers;

  const _SubmissionDetailDialog({
    required this.submission,
    required this.questions,
    required this.studentAnswers,
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
    final studentName = submission['studentName'] ?? 'Không có tên';
    final studentId = submission['studentId'] ?? 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
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
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MSSV: $studentId',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          submission['quizTitle'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
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

            // Stats with Suspicious Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.check_circle_rounded,
                        '$score',
                        'Đúng',
                        Colors.green,
                      ),
                      _buildStatItem(
                        Icons.cancel_rounded,
                        '${total - score}',
                        'Sai',
                        Colors.red,
                      ),
                      _buildStatItem(
                        Icons.timer_rounded,
                        _formatTime(timeSpent),
                        'Thời gian',
                        Colors.blue,
                      ),
                      _buildStatItem(
                        Icons.grade_rounded,
                        '${percentage.toStringAsFixed(1)}%',
                        'Điểm số',
                        Colors.orange,
                      ),
                    ],
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
                ],
              ),
            ),

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
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCorrect ? Colors.green : Colors.red)
                              .withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade50
                                : Colors.red.shade50,
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

                        // Padding(
                        //   padding: const EdgeInsets.all(16),
                        //   child: Column(
                        //     children: List.generate(4, (i) {
                        //       final letter = String.fromCharCode(65 + i);
                        //       final options = questionData['options'] as List;
                        //       final isCorrectOption = letter == correctAnswer;
                        //       final isStudentChoice = letter == studentAnswer;

                        //       Color bgColor = Colors.white;
                        //       Color borderColor = Colors.grey.shade200;
                        //       Color textColor = Colors.black87;
                        //       IconData? icon;

                        //       if (isCorrectOption) {
                        //         bgColor = Colors.green.shade50;
                        //         borderColor = Colors.green.shade400;
                        //         textColor = Colors.green.shade800;
                        //         icon = Icons.check_circle_rounded;
                        //       } else if (isStudentChoice && !isCorrect) {
                        //         bgColor = Colors.red.shade50;
                        //         borderColor = Colors.red.shade400;
                        //         textColor = Colors.red.shade800;
                        //         icon = Icons.cancel_rounded;
                        //       } else if (isStudentChoice) {
                        //         bgColor = Colors.green.shade50;
                        //         borderColor = Colors.green.shade400;
                        //       }

                        //       return Container(
                        //         margin: const EdgeInsets.only(bottom: 8),
                        //         padding: const EdgeInsets.all(12),
                        //         decoration: BoxDecoration(
                        //           color: bgColor,
                        //           borderRadius: BorderRadius.circular(10),
                        //           border: Border.all(color: borderColor),
                        //         ),
                        //         child: Row(
                        //           children: [
                        //             Container(
                        //               width: 28,
                        //               height: 28,
                        //               decoration: BoxDecoration(
                        //                 color: isCorrectOption
                        //                     ? Colors.green
                        //                     : (isStudentChoice
                        //                           ? Colors.red
                        //                           : Colors.grey.shade300),
                        //                 shape: BoxShape.circle,
                        //               ),
                        //               child: Center(
                        //                 child: Text(
                        //                   letter,
                        //                   style: TextStyle(
                        //                     color:
                        //                         isStudentChoice ||
                        //                             isCorrectOption
                        //                         ? Colors.white
                        //                         : Colors.grey.shade700,
                        //                     fontWeight: FontWeight.bold,
                        //                   ),
                        //                 ),
                        //               ),
                        //             ),
                        //             const SizedBox(width: 12),
                        //             Expanded(
                        //               child: Text(
                        //                 options[i],
                        //                 style: TextStyle(
                        //                   color: textColor,
                        //                   fontWeight: FontWeight.w500,
                        //                 ),
                        //               ),
                        //             ),
                        //             if (icon != null)
                        //               Icon(icon, color: borderColor, size: 20),
                        //           ],
                        //         ),
                        //       );
                        //     }),
                        //   ),
                        // ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: () {
                              // ✨ Lấy options và kiểm tra type
                              final options = questionData['options'] as List;
                              final questionType =
                                  questionData['type'] ?? 'single';

                              return List.generate(options.length, (i) {
                                final letter = String.fromCharCode(65 + i);

                                // ✨ Xử lý multiple choice
                                bool isCorrectOption;
                                bool isStudentChoice;

                                if (questionType == 'multiple') {
                                  // Multiple choice
                                  final correctAnswers = correctAnswer is List
                                      ? List<String>.from(correctAnswer)
                                      : [correctAnswer.toString()];

                                  final studentAnswers = studentAnswer is List
                                      ? List<String>.from(studentAnswer)
                                      : (studentAnswer != null &&
                                            studentAnswer.toString().isNotEmpty)
                                      ? [studentAnswer.toString()]
                                      : <String>[];

                                  isCorrectOption = correctAnswers.contains(
                                    letter,
                                  );
                                  isStudentChoice = studentAnswers.contains(
                                    letter,
                                  );
                                } else {
                                  // Single choice
                                  isCorrectOption = letter == correctAnswer;
                                  isStudentChoice = letter == studentAnswer;
                                }

                                Color bgColor = Colors.white;
                                Color borderColor = Colors.grey.shade200;
                                Color textColor = Colors.black87;
                                IconData? icon;

                                if (isCorrectOption && isStudentChoice) {
                                  // Đúng và chọn
                                  bgColor = Colors.green.shade50;
                                  borderColor = Colors.green.shade400;
                                  textColor = Colors.green.shade800;
                                  icon = Icons.check_circle_rounded;
                                } else if (isCorrectOption) {
                                  // Đúng nhưng không chọn
                                  bgColor = Colors.green.shade50;
                                  borderColor = Colors.green.shade400;
                                  textColor = Colors.green.shade800;
                                  icon = Icons.check_circle_outline;
                                } else if (isStudentChoice) {
                                  // Sai và chọn
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
                                              : (isStudentChoice
                                                    ? Colors.red
                                                    : Colors.grey.shade300),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            letter,
                                            style: TextStyle(
                                              color:
                                                  isStudentChoice ||
                                                      isCorrectOption
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
                                          options[i].toString(),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (icon != null)
                                        Icon(
                                          icon,
                                          color: borderColor,
                                          size: 20,
                                        ),
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
