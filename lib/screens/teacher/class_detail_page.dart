// lib/screens/teacher/class_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:excel/excel.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;

import 'class_create_quiz_page.dart';
import 'class_quiz_detail_page.dart';
import 'class_results_page.dart';
import '../../services/quiz_schedule_service.dart';
import '../../models/quiz_schedule_model.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDetailPage({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _studentEmailController = TextEditingController();
  final _studentNameController = TextEditingController();
  bool _isImporting = false;
  String _studentSearchQuery = '';
  String _studentSortBy = 'id'; // name, id, date
  bool _studentSortAscending = true;
  double _classAverageScore = 0.0;
  bool _isLoadingStats = true;

  final _studentSearchController = TextEditingController();
  late Stream<QuerySnapshot> _studentsStream;

  @override
  void initState() {
    super.initState();
    _studentsStream = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .snapshots();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchClassStats();
  }

  Future<void> _fetchClassStats() async {
    try {
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .get();

      double totalPercentage = 0;
      int submissionCount = 0;

      for (var quizDoc in quizzesSnapshot.docs) {
        final submissionsSnapshot = await FirebaseFirestore.instance
            .collection('submissions')
            .where('classId', isEqualTo: widget.classId)
            .where('quizId', isEqualTo: quizDoc.id)
            .get();

        for (var subDoc in submissionsSnapshot.docs) {
          final data = subDoc.data();
          final score = data['score'] ?? 0;
          final total = data['totalQuestions'] ?? 1;
          totalPercentage += (score / total) * 10;
          submissionCount++;
        }
      }

      if (mounted) {
        setState(() {
          _classAverageScore = submissionCount > 0 ? totalPercentage / submissionCount : 0.0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _exportStudentsToExcel(List<QueryDocumentSnapshot> students) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Học sinh'];
      excel.delete('Sheet1'); // Remove default sheet

      CellStyle headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
      );

      List<String> headers = ['STT', 'Họ và tên', 'MSSV', 'Email', 'Lớp'];
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < students.length; i++) {
        final data = students[i].data() as Map<String, dynamic>;
        final rowIndex = i + 1;
        
        final className = data['class'] ?? widget.className;

        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(i + 1);
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(data['name'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(data['studentId'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(data['email'] ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(className);
      }

      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }

      final fileName = 'DanhSachHocSinh_${widget.className.replaceAll(RegExp(r'[^\w\s]+'), '')}.xlsx';
      var fileBytes = excel.save(fileName: fileName);
      if (fileBytes == null) throw Exception('Không thể tạo file');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xuất danh sách học sinh'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi xuất file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentEmailController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  String _extractStudentId(String email) {
    final parts = email.split('@');
    if (parts.isEmpty) return '';
    final username = parts[0];
    final digits = username.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 9) {
      return digits.substring(0, 9);
    }
    return digits;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FF),
                border: Border(bottom: BorderSide(color: Color(0xFFC3C6D6))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF434654)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('Quản lý lớp học', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B57D0))),
                  const SizedBox(width: 24),
                  const Text('Chi tiết lớp học', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B57D0))),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF434654))),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF434654))),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Breadcrumbs & Header
                          Row(
                            children: [
                              const Text('CLASSES', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF434654), letterSpacing: 1.5)),
                              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF434654)),
                              const Text('CHI TIẾT LỚP HỌC', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF003D9B), letterSpacing: 1.5)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.className, style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF041B3C), letterSpacing: -0.5)),
                                  const SizedBox(height: 8),
                                  const Text('Quản lý danh sách học sinh và kết quả học tập', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
                                ],
                              ),
                              if (_tabController.index == 0)
                                FilledButton.icon(
                                  onPressed: _showAddStudentOptionsDialog,
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Thêm học sinh', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF003D9B),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                )
                              else if (_tabController.index == 1)
                                FilledButton.icon(
                                  onPressed: _showQuizOptionsDialog,
                                  icon: const Icon(Icons.post_add),
                                  label: const Text('Thêm bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF003D9B),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Tab Bar
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFC3C6D6))),
                            ),
                            child: Row(
                              children: [
                                _buildTabButton(0, 'Danh sách sinh viên', Icons.groups_outlined),
                                _buildTabButton(1, 'Bài thi', Icons.assignment_outlined),
                                _buildTabButton(2, 'Kết quả', Icons.bar_chart),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tab Content (without TabBarView to allow scrolling with page)
                          if (_tabController.index == 0) _buildStudentsTab(),
                          if (_tabController.index == 1) _buildQuizzesTab(),
                          if (_tabController.index == 2) SizedBox(
                            height: 800, // Fixed height for now, Results page is complex
                            child: ClassResultsPage(classId: widget.classId),
                          ),
                        ],
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

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () => setState(() => _tabController.index = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF0B57D0) : Colors.transparent, // Update color to match standard blue
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF0B57D0) : const Color(0xFF434654),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0B57D0) : const Color(0xFF434654),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _studentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        var students = snapshot.data?.docs ?? [];

        // Apply Search
        if (_studentSearchQuery.isNotEmpty) {
          students = students.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final mssv = (data['studentId'] ?? '').toString().toLowerCase();
            return name.contains(_studentSearchQuery) || mssv.contains(_studentSearchQuery);
          }).toList();
        }

        // Apply Sort
        students.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          int comparison = 0;
          if (_studentSortBy == 'name') {
            comparison = (dataA['name'] ?? '').compareTo(dataB['name'] ?? '');
          } else if (_studentSortBy == 'id') {
            comparison = (dataA['studentId'] ?? '').compareTo(dataB['studentId'] ?? '');
          } else if (_studentSortBy == 'class') {
            final classA = (dataA['class'] ?? widget.className).toString();
            final classB = (dataB['class'] ?? widget.className).toString();
            comparison = classA.compareTo(classB);
          }
          return _studentSortAscending ? comparison : -comparison;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bento Stats
            Row(
              children: [
                Expanded(child: _buildBentoStatCard('Tổng số học sinh', '${snapshot.data?.docs.length ?? 0}', const Color(0xFF003D9B))),
                const SizedBox(width: 24),
                Expanded(child: _buildBentoStatCard('Hoạt động (24h)', '${snapshot.data?.docs.length ?? 0}', const Color(0xFF006C47))), // Mock
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildBentoStatCard('Điểm trung bình lớp', _isLoadingStats ? '...' : _classAverageScore.toStringAsFixed(1), const Color(0xFF041B3C), trending: '+0.2')), // Calculated
              ],
            ),
            const SizedBox(height: 32),

            // Students Table Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC3C6D6)),
              ),
              child: Column(
                children: [
                  // Table Header Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      border: Border(bottom: BorderSide(color: Color(0xFFC3C6D6))),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Search Box
                        Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _studentSearchController,
                            onChanged: (value) => setState(() => _studentSearchQuery = value.toLowerCase()),
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Color(0xFF737685)),
                              hintText: 'Tìm kiếm tên hoặc MSSV...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                setState(() {
                                  if (_studentSortBy == value) {
                                    _studentSortAscending = !_studentSortAscending;
                                  } else {
                                    _studentSortBy = value;
                                    _studentSortAscending = true;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFC3C6D6)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_list, color: Color(0xFF434654), size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Lọc', style: TextStyle(color: Color(0xFF434654))),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _studentSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                      size: 14,
                                      color: const Color(0xFF434654),
                                    ),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'name', child: Text('Sắp xếp theo Tên')),
                                const PopupMenuItem(value: 'id', child: Text('Sắp xếp theo MSSV')),
                                const PopupMenuItem(value: 'class', child: Text('Sắp xếp theo Lớp')),
                              ],
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _exportStudentsToExcel(students),
                              icon: const Icon(Icons.download, color: Color(0xFF434654)),
                              label: const Text('Xuất CSV', style: TextStyle(color: Color(0xFF434654))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: const Color(0xFFE8EDFF),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('HỌC SINH', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434654)))),
                        Expanded(child: Text('MSSV', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434654)))),
                        Expanded(child: Text('LỚP', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434654)))),
                        SizedBox(width: 48), // Space for actions
                      ],
                    ),
                  ),

                  // Table Data
                  if (students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Text('Chưa có học sinh nào', style: TextStyle(fontSize: 16, color: Color(0xFF434654))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFC3C6D6)),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final data = student.data() as Map<String, dynamic>;
                        return InkWell(
                          onTap: () {},
                          hoverColor: const Color(0xFFF1F3FF),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                // Name and Avatar
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFDAE2FF),
                                        child: Text(data['name']?.substring(0, 1).toUpperCase() ?? 'S', style: const TextStyle(color: Color(0xFF003D9B), fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['name'] ?? 'Không có tên', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF041B3C))),
                                          Text(data['email'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF434654))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Student ID
                                Expanded(
                                  child: Text(data['studentId'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
                                ),
                                // Class Name
                                Expanded(
                                  child: Text(data['class'] ?? widget.className, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
                                ),
                                // Actions
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, color: Color(0xFF434654)),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'edit', child: const Text('Chỉnh sửa'), onTap: () => _showEditStudentDialog(student.id, data)),
                                    PopupMenuItem(value: 'delete', child: const Text('Xóa', style: TextStyle(color: Colors.red)), onTap: () => _deleteStudent(student.id, data)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
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

  Widget _buildQuizzesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final quizzes = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Class Exams', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF041B3C))),
            const SizedBox(height: 24),
            if (quizzes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text('Chưa có bài thi nào', style: TextStyle(fontSize: 16, color: Color(0xFF434654))),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  mainAxisExtent: 220,
                ),
                itemCount: quizzes.length + 1, // +1 for "Create New" card
                itemBuilder: (context, index) {
                  if (index == quizzes.length) {
                    return _buildAddExamCard();
                  }
                  final quiz = quizzes[index];
                  final data = quiz.data() as Map<String, dynamic>;
                  return _buildQuizCard(quiz.id, data);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddExamCard() {
    return InkWell(
      onTap: _showQuizOptionsDialog,
      hoverColor: const Color(0xFF003D9B).withOpacity(0.05),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC3C6D6), style: BorderStyle.solid, width: 2), // dashed representation
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003D9B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF003D9B), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Tạo bài thi mới', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF041B3C))),
            const SizedBox(height: 8),
            const Text('Chọn từ thư viện hoặc tự soạn thảo', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF737685)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(String quizId, Map<String, dynamic> data) {
    return FutureBuilder<QuizSchedule?>(
      future: QuizScheduleService.getSchedule(widget.classId, quizId),
      builder: (context, scheduleSnapshot) {
        final schedule = scheduleSnapshot.data;
        
        // Define status color and text
        Color statusBgColor = const Color(0xFFF1F3FF); // Default draft
        Color statusTextColor = const Color(0xFF434654);
        String statusText = 'Bản nháp';
        
        if (schedule != null) {
          if (schedule.isClosed) {
            statusBgColor = const Color(0xFFC4D2FF).withOpacity(0.5); // primary-container
            statusTextColor = const Color(0xFF003D9B);
            statusText = 'Đã kết thúc';
          } else if (schedule.isOpen) {
            statusBgColor = const Color(0xFF82F9BE).withOpacity(0.5); // secondary-container
            statusTextColor = const Color(0xFF00734C);
            statusText = 'Đang diễn ra';
          } else {
            statusBgColor = const Color(0xFFE8EDFF); 
            statusTextColor = const Color(0xFF434654);
            statusText = 'Sắp diễn ra';
          }
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassQuizDetailPage(
                  classId: widget.classId,
                  quizId: quizId,
                  quizData: data,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC3C6D6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(statusText, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: statusTextColor)),
                    ),
                    InkWell(
                      onTap: () => _removeQuizFromClass(quizId, data),
                      child: const Icon(Icons.delete_outline, color: Color(0xFF737685)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Text(data['title'] ?? 'Bài thi', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF041B3C)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Color(0xFF434654)),
                    const SizedBox(width: 8),
                    Text('${data['duration'] ?? 0} phút • ${data['questionCount'] ?? 0} câu hỏi', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFC3C6D6)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chi tiết bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF434654), fontStyle: FontStyle.italic)),
                    Row(
                      children: [
                        const Text('Chi tiết', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF003D9B))),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF003D9B)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEW: Show dialog with options to add student manually or import from Excel
  void _showAddStudentOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Thêm học sinh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF041B3C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Manual add option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showAddStudentDialog();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0DFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm thủ công',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF041B3C),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Nhập từng học sinh',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF737685),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Color(0xFF737685),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Import from Excel option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _importStudentsFromExcel();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FEF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0FFDD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Color(0xFF16A34A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import từ Excel',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF041B3C),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Upload file .xlsx hoặc .xls',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF737685),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Color(0xFF737685),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Import students from Excel file
  Future<void> _importStudentsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null) return;

      setState(() => _isImporting = true);

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw Exception('Không thể đọc file');
      }

      // Parse Excel file
      var excel = Excel.decodeBytes(bytes);

      // Get first sheet
      var sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('File Excel trống');
      }

      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      // Skip header row (row 0) and process data
      for (var i = 1; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];

        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }

        try {
          // Columns: B=Số thẻ SV (1), C=Họ tên SV (2), E=Số điện thoại (4)
          // D=Lớp sinh hoạt (3) - optional

          final studentIdStr = row[1]?.value?.toString().trim() ?? '';
          final name = row[2]?.value?.toString().trim() ?? '';
          final phone = row[4]?.value?.toString().trim() ?? '';

          if (studentIdStr.isEmpty || name.isEmpty) {
            errorCount++;
            errors.add('Dòng ${i + 1}: Thiếu mã SV hoặc tên');
            continue;
          }

          // Extract 9 digits from student ID
          final studentId = studentIdStr.replaceAll(RegExp(r'[^0-9]'), '');
          if (studentId.length < 9) {
            errorCount++;
            errors.add('Dòng ${i + 1}: Mã SV không hợp lệ ($studentIdStr)');
            continue;
          }

          final studentId9 = studentId.substring(0, 9);

          // Create email from student ID
          final email = '${studentId9}@sv1.dut.udn.vn';

          // Check if student already exists
          final existingStudent = await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc(studentId9)
              .get();

          if (existingStudent.exists) {
            errorCount++;
            errors.add('Dòng ${i + 1}: Học sinh $studentId9 đã tồn tại');
            continue;
          }

          // Add student to Firestore
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc(studentId9)
              .set({
                'studentId': studentId9,
                'email': email,
                'name': name,
                'phone': phone,
                'addedAt': FieldValue.serverTimestamp(),
              });

          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Dòng ${i + 1}: Lỗi - $e');
        }
      }

      // Update student count
      if (successCount > 0) {
        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .get();
        final currentCount = (classDoc.data()?['studentCount'] ?? 0) as int;

        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .update({'studentCount': currentCount + successCount});
      }

      if (mounted) {
        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successCount > 0
                          ? const Color(0xFFD0FFDD)
                          : const Color(0xFFFFE4E6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      successCount > 0 ? Icons.check_circle : Icons.warning,
                      color: successCount > 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE11D48),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kết quả import',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF041B3C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thành công:',
                              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                            Text(
                              '$successCount',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lỗi:',
                              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                            Text(
                              '$errorCount',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFFE11D48),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chi tiết lỗi:',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...errors
                                  .take(10)
                                  .map(
                                    (error) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $error',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ),
                              if (errors.length > 10)
                                Text(
                                  '... và ${errors.length - 10} lỗi khác',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showQuizOptionsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Thêm bài thi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF041B3C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassCreateQuizPage(classId: widget.classId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0DFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo bài thi mới',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF041B3C),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tạo đề thi từ file PDF/TXT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF737685),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Color(0xFF737685),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showAssignQuizDialog();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FEF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0FFDD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.library_add,
                          color: Color(0xFF16A34A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gán bài thi có sẵn',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF041B3C),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Chọn từ kho đề thi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF737685),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Color(0xFF737685),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String? emailError;
    String? nameError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 800,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6), // Blue background for icon
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Thêm học sinh',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailCtrl,
                      onChanged: (_) {
                        if (emailError != null) setStateDialog(() => emailError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Email học sinh',
                        helperText: emailError == null ? '9 chữ số đầu email sẽ là mã học sinh' : null,
                        helperStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                        errorText: emailError,
                        prefixIcon: const Icon(Icons.mail, color: Color(0xFF6B7280)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) {
                        if (nameError != null) setStateDialog(() => nameError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Tên học sinh',
                        errorText: nameError,
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF6B7280)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final email = emailCtrl.text.trim();
                              final name = nameCtrl.text.trim();
                              
                              if (email.isEmpty) {
                                setStateDialog(() => emailError = 'Vui lòng nhập email');
                                return;
                              }
                              if (name.isEmpty) {
                                setStateDialog(() => nameError = 'Vui lòng nhập tên học sinh');
                                return;
                              }
                              if (!_isValidEmail(email)) {
                                setStateDialog(() => emailError = 'Định dạng email không hợp lệ');
                                return;
                              }
                              
                              final studentId = _extractStudentId(email);
                              if (studentId.length < 9) {
                                setStateDialog(() => emailError = 'Email phải chứa ít nhất 9 chữ số');
                                return;
                              }

                              final error = await _addStudent(email, name);
                              if (error != null) {
                                if (error.contains('tồn tại')) {
                                  setStateDialog(() => emailError = error);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('⚠️ $error'),
                                        backgroundColor: Colors.orange.shade600,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  Navigator.pop(context); // Pop the dialog
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Thêm',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      emailCtrl.dispose();
      nameCtrl.dispose();
    });
  }

  // Continue with remaining methods (_showEditStudentDialog, _showAssignQuizDialog, _addStudent, etc.)
  // These remain the same as in your original code...
  void _showEditStudentDialog(String studentDocId, Map<String, dynamic> data) {
    _studentEmailController.text = data['email'] ?? '';
    _studentNameController.text = data['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316), // Orange background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _studentEmailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.mail, color: Color(0xFF6B7280)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _studentNameController,
                decoration: InputDecoration(
                  labelText: 'Tên học sinh',
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF6B7280)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await _updateStudent(studentDocId);
                        if (success && mounted) {
                          Navigator.pop(context); // Pop the dialog
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignQuizDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.library_books_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Chọn bài thi',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quiz')
                      .where('status', isEqualTo: 'available')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Không có bài thi nào khả dụng',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }

                    final quizzes = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = quizzes[index];
                        final data = quiz.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${data['questionCount'] ?? 0}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                data['title'] ?? 'Bài thi',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${data['duration'] ?? 0} phút',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _assignQuizToClass(quiz.id, data);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Gán',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
          ),
        ),
      ),
    );
  }

  Future<String?> _addStudent(String email, String name) async {
    final studentId = _extractStudentId(email);

    try {
      final existingStudent = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId)
          .get();

      if (existingStudent.exists) {
        return 'Học sinh đã tồn tại trong lớp';
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentId)
          .set({
            'studentId': studentId,
            'email': email,
            'name': name,
            'addedAt': FieldValue.serverTimestamp(),
          });

      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['studentCount'] ?? 0) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'studentCount': currentCount + 1});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Thêm học sinh thành công! ID: $studentId'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> _updateStudent(String studentDocId) async {
    if (_studentNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Vui lòng nhập tên học sinh'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentDocId)
          .update({'name': _studentNameController.text.trim()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Cập nhật học sinh thành công!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _deleteStudent(
    String studentDocId,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFDC2626),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác nhận xóa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc muốn xóa học sinh "${data['name']}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(studentDocId)
          .delete();

      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['studentCount'] ?? 1) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'studentCount': currentCount > 0 ? currentCount - 1 : 0});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã xóa học sinh'),
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
            content: Text('❌ Lỗi: $e'),
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

  Future<void> _assignQuizToClass(
    String quizId,
    Map<String, dynamic> quizData,
  ) async {
    try {
      final existingQuiz = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (existingQuiz.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Bài thi đã được gán cho lớp này'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .set({
            'title': quizData['title'],
            'questionCount': quizData['questionCount'],
            'duration': quizData['duration'],
            'assignedAt': FieldValue.serverTimestamp(),
          });

      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 0) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'quizCount': currentCount + 1});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Gán bài thi thành công!'),
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
            content: Text('❌ Lỗi: $e'),
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

  Future<void> _removeQuizFromClass(
    String quizId,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFDC2626),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác nhận gỡ bỏ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc muốn gỡ bài thi "${data['title']}" khỏi lớp?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Gỡ bỏ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('quizzes')
          .doc(quizId)
          .delete();

      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 1) as int;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'quizCount': currentCount > 0 ? currentCount - 1 : 0});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã gỡ bài thi khỏi lớp'),
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
            content: Text('❌ Lỗi: $e'),
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
}
