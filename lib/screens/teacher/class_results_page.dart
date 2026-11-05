// lib/screens/teacher/class_results_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import '../../utils/constants.dart';

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
      int validSubmissions = 0;
      for (var doc in submissionsSnap.docs) {
        final data = doc.data();
        final rawScore = (data['score'] ?? 0).toDouble();
        double totalQ = (data['totalQuestions'] ?? 0).toDouble();
        if (totalQ <= 0 && data['questionOrder'] is List && (data['questionOrder'] as List).isNotEmpty) {
          totalQ = (data['questionOrder'] as List).length.toDouble();
        }
        if (totalQ > 0) {
          final score10 = (rawScore / totalQ) * 10;
          if (!score10.isNaN) {
            totalScore += score10;
            validSubmissions++;
          }
        }
      }

      double avgScore = validSubmissions > 0 ? totalScore / validSubmissions : 0.0;
      if (avgScore.isNaN) avgScore = 0.0;
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
        double totalQ = (data['totalQuestions'] ?? 0).toDouble();
        if (totalQ <= 0 && data['questionOrder'] is List && (data['questionOrder'] as List).isNotEmpty) {
          totalQ = (data['questionOrder'] as List).length.toDouble();
        }
        final rawScore = totalQ > 0 ? ((data['score'] ?? 0).toDouble() / totalQ * 10) : 0.0;
        final score = rawScore.isNaN ? 0.0 : double.parse(rawScore.toStringAsFixed(1));

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
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filterButton = PopupMenuButton<String>(
      color: AppConstants.surf(context),
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
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'mssv_asc',
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 20, color: _sortBy == 'studentId' ? AppConstants.brand(context) : AppConstants.txtMuted(context)),
              const SizedBox(width: 12),
              Text(
                'Mã số SV (Thấp → Cao)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _sortBy == 'studentId' ? AppConstants.brand(context) : AppConstants.txt(context),
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
              Icon(Icons.sort, size: 20, color: _sortBy == 'score' ? AppConstants.brand(context) : AppConstants.txtMuted(context)),
              const SizedBox(width: 12),
              Text(
                'Điểm số (Cao → Thấp)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _sortBy == 'score' ? AppConstants.brand(context) : AppConstants.txt(context),
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
          color: AppConstants.surf(context),
          border: Border.all(color: AppConstants.border(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, color: AppConstants.txt(context), size: 18),
            const SizedBox(width: 8),
            Text('Lọc', style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );

    final searchBox = Container(
      width: isMobile ? double.infinity : 300,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: AppConstants.txtMuted(context), size: 20),
          hintText: 'Tìm kiếm bài thi...',
          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 12),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analytics Row (Bento Stats)
        if (isMobile)
          Column(
            children: [
              _buildBentoStatCard('Điểm trung bình', _isLoadingStats ? '--' : _averageScore.toStringAsFixed(1), AppConstants.brand(context)),
              const SizedBox(height: 12),
              _buildBentoStatCard('Tỷ lệ hoàn thành', _isLoadingStats ? '--' : '${_completionRate.toStringAsFixed(1)}%', const Color(0xFF16A34A)),
              const SizedBox(height: 12),
              _buildBentoStatCard('Đã nộp', _isLoadingStats ? '--' : '$_submittedCount', AppConstants.txt(context)),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _buildBentoStatCard('Điểm trung bình', _isLoadingStats ? '--' : _averageScore.toStringAsFixed(1), AppConstants.brand(context))),
              const SizedBox(width: 24),
              Expanded(child: _buildBentoStatCard('Tỷ lệ hoàn thành', _isLoadingStats ? '--' : '${_completionRate.toStringAsFixed(1)}%', const Color(0xFF16A34A))),
              const SizedBox(width: 24),
              Expanded(child: _buildBentoStatCard('Đã nộp', _isLoadingStats ? '--' : '$_submittedCount', AppConstants.txt(context))),
            ],
          ),
        SizedBox(height: isMobile ? 20 : 32),

        // Title and Filter Row
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Danh sách điểm thi', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppConstants.txt(context))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: searchBox),
                  const SizedBox(width: 10),
                  filterButton,
                ],
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách điểm thi', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppConstants.txt(context))),
              Row(
                children: [
                  searchBox,
                  const SizedBox(width: 12),
                  filterButton,
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
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.isDarkMode(context) ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.txtMuted(context))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: valueColor == const Color(0xFF041B3C) ? AppConstants.txt(context) : valueColor)),
              if (trending != null) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(trending, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.isDarkMode(context) ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 10 : 16),
          title: Text(
            quizTitle,
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: isMobile ? 16 : 18, color: AppConstants.txt(context)),
          ),
          subtitle: Text(
            allowViewDetail
                ? 'Đang CÔNG KHAI chi tiết'
                : 'Đang ẨN chi tiết bài làm',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: allowViewDetail ? const Color(0xFF16A34A) : AppConstants.txtMuted(context),
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
                  activeThumbColor: AppConstants.brand(context),
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

              const SizedBox(width: 6),

              // Nút Export Excel
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
                    : const Icon(Icons.file_download_outlined, size: 18),
                label: Text(
                  isExporting ? '...' : (isMobile ? 'Excel' : 'Xuất Excel'),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.brand(context),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('submissions')
                  .where('classId', isEqualTo: widget.classId)
                  .where('quizId', isEqualTo: quizId)
                  .snapshots(),
              builder: (context, subSnapshot) {
                if (!subSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }
                var submissions = subSnapshot.data!.docs;

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
                      style: TextStyle(color: AppConstants.txtMuted(context)),
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(height: 1, color: AppConstants.border(context)),
                    ...submissions
                        .map((doc) => _buildStudentResultItem(doc, quizData))
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

  Widget _buildStudentResultItem(QueryDocumentSnapshot doc, Map<String, dynamic> quizData) {
    final data = doc.data() as Map<String, dynamic>;
    final score = (data['score'] ?? 0).toDouble();
    int total = (data['totalQuestions'] ?? 0) as int;
    if (total <= 0) {
      if (data['questionOrder'] is List && (data['questionOrder'] as List).isNotEmpty) {
        total = (data['questionOrder'] as List).length;
      } else if (quizData['questionCount'] != null && (quizData['questionCount'] as num) > 0) {
        total = (quizData['questionCount'] as num).toInt();
      }
    }
    final percentage = total > 0 ? (score / total * 100) : 0.0;
    final finalPercentage = percentage.isNaN ? 0.0 : percentage;
    final scoreColor = _getScoreColor(finalPercentage);
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
          border: Border(bottom: BorderSide(color: AppConstants.border(context))),
        ),
        child: Row(
          children: [
            // Điểm số (Badge nhỏ gọn)
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  '${finalPercentage.toStringAsFixed(0)}%',
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppConstants.txt(context),
                          ),
                        )
                      : FutureBuilder<String>(
                          future: _getStudentName(studentId),
                          builder: (c, s) => Text(
                            s.data ?? '...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppConstants.txt(context),
                            ),
                          ),
                        ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'MSSV: $studentId',
                        style: TextStyle(fontSize: 12, color: AppConstants.txtMuted(context)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        total > 0
                            ? '•  ${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)}/$total câu'
                            : '•  0 câu',
                        style: TextStyle(fontSize: 12, color: AppConstants.txtMuted(context)),
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

            Icon(Icons.chevron_right, color: AppConstants.txtMuted(context), size: 20),
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
    final score = (submission['score'] ?? 0).toDouble();
    int total = (submission['totalQuestions'] ?? 0) as int;
    if (total <= 0 && questions.isNotEmpty) {
      total = questions.length;
    }
    final percentage = total > 0 ? (score / total * 100) : 0.0;
    final finalPercentage = percentage.isNaN ? 0.0 : percentage;
    final timeSpent = submission['timeSpent'] ?? 0;
    final suspiciousCount = submission['suspiciousActionCount'] ?? 0;
    final cheatingDetected = submission['cheatingDetected'] ?? false;
    final autoSubmitted = submission['autoSubmitted'] ?? false;
    final studentId = submission['studentId'] ?? 'Unknown';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppConstants.bg(context),
          border: Border.all(color: AppConstants.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppConstants.isDarkMode(context) ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF003D9B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003D9B).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
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
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'MSSV: $studentId • ${submission['quizTitle'] ?? 'Bài kiểm tra'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.check_circle_rounded,
                      '$score',
                      'Đúng',
                      const Color(0xFF16A34A),
                      bgColor: AppConstants.isDarkMode(context) ? const Color(0xFF1B3820) : const Color(0xFFDCFCE7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.cancel_rounded,
                      '${total - score}',
                      'Sai',
                      const Color(0xFFDC2626),
                      bgColor: AppConstants.isDarkMode(context) ? const Color(0xFF3B1818) : const Color(0xFFFEE2E2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.timer_rounded,
                      _formatTime(timeSpent),
                      'Thời gian',
                      const Color(0xFF003D9B),
                      bgColor: AppConstants.isDarkMode(context) ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      Icons.star_rounded,
                      '${finalPercentage.toStringAsFixed(1)}%',
                      'Điểm số',
                      const Color(0xFFD97706),
                      bgColor: AppConstants.isDarkMode(context) ? const Color(0xFF3A2508) : const Color(0xFFFEF3C7),
                    ),
                  ),
                ],
              ),
            ),

            if (suspiciousCount > 0) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cheatingDetected ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cheatingDetected ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cheatingDetected ? Icons.block_rounded : Icons.warning_amber_rounded,
                        color: cheatingDetected ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              autoSubmitted ? 'Tự động nộp do vi phạm' : 'Có hành vi khả nghi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: cheatingDetected ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$suspiciousCount vi phạm được ghi nhận trong quá trình làm bài',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: cheatingDetected ? const Color(0xFFB91C1C) : const Color(0xFFB45309),
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
                          color: cheatingDetected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$suspiciousCount',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cheatingDetected ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Questions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final questionDoc = questions[index];
                  final questionData =
                      questionDoc.data() as Map<String, dynamic>;
                  final questionId = questionDoc.id;
                  final rawCorrect = questionData['correctAnswer'];
                  final rawUser = studentAnswers[questionId];
                  final options = List<String>.from(questionData['options'] ?? []);
                  final List<String> correctList = _normalizeToList(rawCorrect);
                  final List<String> userList = _normalizeToList(rawUser);
                  final isMultiple = rawCorrect is List || (questionData['type'] == 'multiple');
                  final earnedScore = _calculateQuestionScore(rawCorrect, rawUser);

                  final bool isDark = AppConstants.isDarkMode(context);
                  final Color statusColor = earnedScore >= 0.99
                      ? const Color(0xFF2E7D32)
                      : (earnedScore > 0
                          ? const Color(0xFFB86200)
                          : const Color(0xFFD32F2F));
                  final Color statusBg = earnedScore >= 0.99
                      ? (isDark ? const Color(0xFF1B3820) : const Color(0xFFEDF7ED))
                      : (earnedScore > 0
                          ? (isDark ? const Color(0xFF382710) : const Color(0xFFFFF3E0))
                          : (isDark ? const Color(0xFF381515) : const Color(0xFFFFEDED)));
                  final IconData statusIcon = earnedScore >= 0.99
                      ? Icons.check_circle_outline
                      : (earnedScore > 0
                          ? Icons.warning_amber_outlined
                          : Icons.cancel_outlined);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.surf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Câu ${index + 1}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '+${_formatScore(earnedScore)} điểm',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Text(
                          questionData['question'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Options
                        ...options.asMap().entries.map((optEntry) {
                          final letter = String.fromCharCode(65 + optEntry.key);
                          final text = optEntry.value;
                          final bool isCorrectOption = correctList.contains(letter);
                          final bool isUserSelected = userList.contains(letter);

                          Color optBg = AppConstants.surfLow(context);
                          Color optBorder = AppConstants.border(context);
                          Color optText = AppConstants.txt(context);
                          Color badgeColor = AppConstants.surfHigh(context);
                          Color badgeTextColor = AppConstants.txtMuted(context);
                          Widget? statusBadge;

                          if (isUserSelected && isCorrectOption) {
                            // 1. Sinh viên chọn ĐÚNG: Xanh lá
                            optBg = isDark ? const Color(0xFF163319) : const Color(0xFFEDF7ED);
                            optBorder = const Color(0xFF2E7D32);
                            optText = isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);
                            badgeColor = const Color(0xFF2E7D32);
                            badgeTextColor = Colors.white;
                            statusBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 13, color: isDark ? Colors.white : const Color(0xFF1B5E20)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đã chọn (Đúng)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (isUserSelected && !isCorrectOption) {
                            // 2. Sinh viên chọn SAI: Đỏ
                            optBg = isDark ? const Color(0xFF3B1515) : const Color(0xFFFFEDED);
                            optBorder = const Color(0xFFD32F2F);
                            optText = isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
                            badgeColor = const Color(0xFFD32F2F);
                            badgeTextColor = Colors.white;
                            statusBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF5C1D1D) : const Color(0xFFFFCDD2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, size: 13, color: isDark ? Colors.white : const Color(0xFFC62828)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đã chọn (Sai)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFFC62828),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (!isUserSelected && isCorrectOption) {
                            // 3. Đáp án ĐÚNG mà sinh viên CHƯA CHỌN / BỎ SÓT: Vàng/Cam
                            optBg = isDark ? const Color(0xFF382A0F) : const Color(0xFFFFF8E1);
                            optBorder = const Color(0xFFFFA000);
                            optText = isDark ? const Color(0xFFFFD54F) : const Color(0xFFB78103);
                            badgeColor = const Color(0xFFFFA000);
                            badgeTextColor = Colors.white;
                            statusBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF543E10) : const Color(0xFFFFECB3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline, size: 13, color: isDark ? Colors.white : const Color(0xFF8F6B00)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đáp án đúng (Chưa chọn)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF8F6B00),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: optBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: optBorder,
                                width: statusBadge != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                                    borderRadius: isMultiple ? BorderRadius.circular(6) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: badgeTextColor,
                                        fontWeight: FontWeight.w700,
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
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: optText,
                                      fontWeight: statusBadge != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (statusBadge != null) ...[
                                  const SizedBox(width: 8),
                                  statusBadge,
                                ],
                              ],
                            ),
                          );
                        }),

                        // Explanation Section (if exists)
                        if (questionData['explanation'] != null &&
                            questionData['explanation'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.surfLow(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppConstants.border(context)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF003D9B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Giải thích: ${questionData['explanation']}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppConstants.txt(context),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  // ===================== Logic =====================

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
        if (correctList.contains(ans)) {
          currentScore += unitScore;
        } else {
          currentScore -= penaltyScore;
        }
      }
      return currentScore.clamp(0.0, 1.0);
    } else {
      return (userList.isNotEmpty && correctList.contains(userList.first))
          ? 1.0
          : 0.0;
    }
  }

  List<String> _normalizeToList(dynamic input) {
    if (input == null) return [];
    if (input is List) return input.map((e) => e.toString().trim()).toList();
    return [input.toString().trim()];
  }

  String _formatScore(double score) =>
      score.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color, {
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppConstants.isDarkMode(context) ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor ?? color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppConstants.txt(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppConstants.txtMuted(context),
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
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
