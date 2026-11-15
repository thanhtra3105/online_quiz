// lib/screens/teacher/class_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;

import 'class_create_quiz_page.dart';
import 'class_quiz_detail_page.dart';
import 'quiz_create_from_bank_page.dart';
import 'class_results_page.dart';
import 'teacher_attendance_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/course_subject_service.dart';
import '../../services/quiz_schedule_service.dart';
import '../../models/quiz_schedule_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String className;
  final bool isAssistant;
  final VoidCallback? onBack;

  const ClassDetailPage({
    super.key,
    required this.classId,
    required this.className,
    this.isAssistant = false,
    this.onBack,
  });

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
  late Stream<QuerySnapshot> _assistantsStream;

  @override
  void initState() {
    super.initState();
    _studentsStream = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .snapshots();
    _assistantsStream = FirebaseService.getClassAssistants(widget.classId);
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

        final quizData = quizDoc.data();
        final int fallbackTotal = (quizData['questionCount'] ?? 0) as int;

        for (var subDoc in submissionsSnapshot.docs) {
          final data = subDoc.data();
          final double score = (data['score'] ?? 0).toDouble();
          int total = (data['totalQuestions'] ?? 0) as int;
          if (total <= 0) {
            if (data['questionOrder'] is List && (data['questionOrder'] as List).isNotEmpty) {
              total = (data['questionOrder'] as List).length;
            } else if (fallbackTotal > 0) {
              total = fallbackTotal;
            }
          }

          if (total > 0) {
            final double score10 = (score / total) * 10;
            if (!score10.isNaN) {
              totalPercentage += score10;
              submissionCount++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          double avg = submissionCount > 0 ? totalPercentage / submissionCount : 0.0;
          _classAverageScore = avg.isNaN ? 0.0 : avg;
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
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar đồng bộ với trang Quản lý lớp học
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isMobile
                  ? Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: AppConstants.txt(context)),
                          onPressed: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppConstants.surfLow(context),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppConstants.border(context)),
                            ),
                            child: TextField(
                              controller: _studentSearchController,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
                              onChanged: (value) => setState(() => _studentSearchQuery = value.toLowerCase().trim()),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm tên hoặc MSSV...',
                                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                                prefixIcon: Icon(Icons.search_rounded, color: AppConstants.txtMuted(context), size: 18),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Search Bar
                        Container(
                          width: 300,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppConstants.surfLow(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppConstants.border(context)),
                          ),
                          child: TextField(
                            controller: _studentSearchController,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
                            onChanged: (value) => setState(() => _studentSearchQuery = value.toLowerCase().trim()),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm tên hoặc MSSV...',
                              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                              prefixIcon: Icon(Icons.search_rounded, color: AppConstants.txtMuted(context), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Nav links / Breadcrumbs
                        Row(
                          children: [
                            Tooltip(
                              message: widget.isAssistant ? 'Quay lại danh sách lớp học' : 'Quay lại Quản lý lớp học',
                              child: InkWell(
                                onTap: () {
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back_rounded, size: 16, color: AppConstants.txtMuted(context)),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.isAssistant ? 'Lớp học của tôi' : 'Quản lý lớp học',
                                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.txtMuted(context)),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                              ),
                              child: Text(
                                'Chi tiết lớp học',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.brand(context)),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Actions
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Thông báo',
                              onPressed: () {},
                              icon: Icon(Icons.notifications_none_rounded, color: AppConstants.txtMuted(context)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Tài khoản',
                              onPressed: () {},
                              icon: Icon(Icons.account_circle_outlined, color: AppConstants.txtMuted(context)),
                            ),
                          ],
                        ),
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
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.className,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.txt(context),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    if (widget.isAssistant)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.badge_outlined, size: 14, color: Color(0xFF7C3AED)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Trợ giảng',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF7C3AED),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isAssistant
                                      ? 'Bạn đang truy cập với vai trò Trợ giảng của lớp'
                                      : 'Quản lý danh sách học sinh và kết quả học tập',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppConstants.txtMuted(context),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _openAttendanceDialog,
                                    icon: Icon(Icons.qr_code_scanner_rounded, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    label: Text('QR Điểm danh (2 Bước)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFF0F172A), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: isDark ? 0 : 1,
                                      shadowColor: Colors.black.withValues(alpha: 0.05),
                                    ),
                                  ),
                                ),
                                if (_tabController.index == 0) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (!widget.isAssistant) ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _showManageAssistantsDialog,
                                            icon: Icon(Icons.school_outlined, size: 18, color: AppConstants.brand(context)),
                                            label: const Text('Trợ giảng', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppConstants.brand(context),
                                              side: BorderSide(color: AppConstants.brand(context)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _showAddStudentOptionsDialog,
                                          icon: const Icon(Icons.person_add, size: 18),
                                          label: const Text('Thêm học sinh', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppConstants.brand(context),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (_tabController.index == 1) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _showQuizOptionsDialog,
                                      icon: const Icon(Icons.post_add),
                                      label: const Text('Thêm bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppConstants.brand(context),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(widget.className, style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: AppConstants.txt(context), letterSpacing: -0.5)),
                                        if (widget.isAssistant) ...[
                                          const SizedBox(width: 14),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.badge_outlined, size: 16, color: Color(0xFF7C3AED)),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Vai trò: Trợ giảng',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF7C3AED),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.isAssistant
                                          ? 'Bạn đang truy cập với vai trò Trợ giảng (Teaching Assistant) của lớp này'
                                          : 'Quản lý danh sách học sinh và kết quả học tập',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: AppConstants.txtMuted(context)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _openAttendanceDialog,
                                      icon: Icon(Icons.qr_code_scanner_rounded, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      label: Text('QR Điểm danh', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFF0F172A), width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: isDark ? 0 : 1,
                                        shadowColor: Colors.black.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_tabController.index == 0) ...[
                                      if (!widget.isAssistant) ...[
                                        OutlinedButton.icon(
                                          onPressed: _showManageAssistantsDialog,
                                          icon: Icon(Icons.school_outlined, color: AppConstants.brand(context), size: 18),
                                          label: Text('Trợ giảng', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.brand(context))),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: AppConstants.brand(context), width: 1.5),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      FilledButton.icon(
                                        onPressed: _showAddStudentOptionsDialog,
                                        icon: const Icon(Icons.person_add),
                                        label: const Text('Thêm học sinh', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppConstants.brand(context),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ] else if (_tabController.index == 1) ...[
                                      FilledButton.icon(
                                        onPressed: _showQuizOptionsDialog,
                                        icon: const Icon(Icons.post_add),
                                        label: const Text('Thêm bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppConstants.brand(context),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: 32),

                          // Tab Bar
                          Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTabButton(0, 'Danh sách sinh viên', Icons.groups_outlined),
                                  _buildTabButton(1, 'Bài thi', Icons.assignment_outlined),
                                  _buildTabButton(2, 'Kết quả', Icons.bar_chart),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tab Content (without TabBarView to allow scrolling with page)
                          if (_tabController.index == 0) _buildStudentsTab(),
                          if (_tabController.index == 1) _buildQuizzesTab(),
                          if (_tabController.index == 2) SizedBox(
                            height: 800, // Fixed height for now, Results page is complex
                            child: ClassResultsPage(
                              classId: widget.classId,
                              className: widget.className,
                            ),
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
              color: isSelected ? AppConstants.brand(context) : Colors.transparent,
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
              color: isSelected ? AppConstants.brand(context) : AppConstants.txtMuted(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppConstants.brand(context) : AppConstants.txtMuted(context),
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

        final isMobile = MediaQuery.of(context).size.width < 768;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bento Stats
            if (isMobile)
              Column(
                children: [
                  _buildBentoStatCard('Tổng số học sinh', '${snapshot.data?.docs.length ?? 0}', AppConstants.brand(context)),
                  const SizedBox(height: 12),
                  _buildBentoStatCard('Hoạt động (24h)', '${snapshot.data?.docs.length ?? 0}', const Color(0xFF16A34A)),
                  const SizedBox(height: 12),
                  _buildBentoStatCard('Điểm trung bình lớp', _isLoadingStats ? '...' : _classAverageScore.toStringAsFixed(1), AppConstants.txt(context), trending: '+0.2'),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildBentoStatCard('Tổng số học sinh', '${snapshot.data?.docs.length ?? 0}', AppConstants.brand(context))),
                  const SizedBox(width: 24),
                  Expanded(child: _buildBentoStatCard('Hoạt động (24h)', '${snapshot.data?.docs.length ?? 0}', const Color(0xFF16A34A))), // Mock
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildBentoStatCard('Điểm trung bình lớp', _isLoadingStats ? '...' : _classAverageScore.toStringAsFixed(1), AppConstants.txt(context), trending: '+0.2')), // Calculated
                ],
              ),
            const SizedBox(height: 32),

            // Assistants Section
            _buildAssistantsSection(isMobile),
            const SizedBox(height: 32),

            // Students Table Card
            Container(
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.border(context)),
              ),
              child: Column(
                children: [
                  // Table Header Actions
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: AppConstants.surf(context),
                      border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppConstants.surfLow(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppConstants.border(context)),
                                ),
                                child: TextField(
                                  controller: _studentSearchController,
                                  style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context), fontSize: 14),
                                  onChanged: (value) => setState(() => _studentSearchQuery = value.toLowerCase()),
                                  decoration: InputDecoration(
                                    icon: Icon(Icons.search, color: AppConstants.txtMuted(context)),
                                    hintText: 'Tìm kiếm tên hoặc MSSV...',
                                    hintStyle: TextStyle(color: AppConstants.txtMuted(context), fontSize: 13),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: PopupMenuButton<String>(
                                      color: AppConstants.surf(context),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppConstants.border(context)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.filter_list, color: AppConstants.txt(context), size: 18),
                                            const SizedBox(width: 6),
                                            Text('Lọc', style: TextStyle(color: AppConstants.txt(context), fontSize: 13)),
                                            const SizedBox(width: 4),
                                            Icon(
                                              _studentSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                              size: 14,
                                              color: AppConstants.txt(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(value: 'name', child: Text('Sắp xếp theo Tên', style: TextStyle(color: AppConstants.txt(context)))),
                                        PopupMenuItem(value: 'id', child: Text('Sắp xếp theo MSSV', style: TextStyle(color: AppConstants.txt(context)))),
                                        PopupMenuItem(value: 'class', child: Text('Sắp xếp theo Lớp', style: TextStyle(color: AppConstants.txt(context)))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _exportStudentsToExcel(students),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppConstants.border(context)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      icon: Icon(Icons.download, color: AppConstants.txt(context), size: 18),
                                      label: Text('Xuất CSV', style: TextStyle(color: AppConstants.txt(context), fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Search Box
                              Container(
                                width: 300,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppConstants.surfLow(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppConstants.border(context)),
                                ),
                                child: TextField(
                                  controller: _studentSearchController,
                                  style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context), fontSize: 14),
                                  onChanged: (value) => setState(() => _studentSearchQuery = value.toLowerCase()),
                                  decoration: InputDecoration(
                                    icon: Icon(Icons.search, color: AppConstants.txtMuted(context)),
                                    hintText: 'Tìm kiếm tên hoặc MSSV...',
                                    hintStyle: TextStyle(color: AppConstants.txtMuted(context), fontSize: 13),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  PopupMenuButton<String>(
                                    color: AppConstants.surf(context),
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
                                        border: Border.all(color: AppConstants.border(context)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.filter_list, color: AppConstants.txt(context), size: 18),
                                          const SizedBox(width: 8),
                                          Text('Lọc', style: TextStyle(color: AppConstants.txt(context))),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _studentSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 14,
                                            color: AppConstants.txt(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(value: 'name', child: Text('Sắp xếp theo Tên', style: TextStyle(color: AppConstants.txt(context)))),
                                      PopupMenuItem(value: 'id', child: Text('Sắp xếp theo MSSV', style: TextStyle(color: AppConstants.txt(context)))),
                                      PopupMenuItem(value: 'class', child: Text('Sắp xếp theo Lớp', style: TextStyle(color: AppConstants.txt(context)))),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _exportStudentsToExcel(students),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppConstants.border(context)),
                                    ),
                                    icon: Icon(Icons.download, color: AppConstants.txt(context)),
                                    label: Text('Xuất CSV', style: TextStyle(color: AppConstants.txt(context))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  // Table Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
                    color: AppConstants.surfLow(context),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('HỌC SINH', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txtMuted(context)))),
                        if (!isMobile) ...[
                          Expanded(child: Text('MSSV', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txtMuted(context)))),
                          Expanded(child: Text('LỚP', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txtMuted(context)))),
                        ] else
                          Text('THÔNG TIN', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txtMuted(context))),
                        const SizedBox(width: 40), // Space for actions
                      ],
                    ),
                  ),

                  // Table Data
                  if (students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Text('Chưa có học sinh nào', style: TextStyle(fontSize: 16, color: AppConstants.txtMuted(context))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: AppConstants.border(context)),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final data = student.data() as Map<String, dynamic>;
                        return InkWell(
                          onTap: () {},
                          hoverColor: AppConstants.surfLow(context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
                            child: Row(
                              children: [
                                // Name and Avatar
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: isMobile ? 18 : 20,
                                        backgroundColor: AppConstants.isDarkMode(context) ? const Color(0xFF1E293B) : const Color(0xFFDAE2FF),
                                        child: Text(data['name']?.substring(0, 1).toUpperCase() ?? 'S', style: TextStyle(color: AppConstants.brand(context), fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['name'] ?? 'Không có tên',
                                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              data['email'] ?? '',
                                              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppConstants.txtMuted(context)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isMobile) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '${data['studentId'] ?? ''} • ${data['class'] ?? widget.className}',
                                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppConstants.brand(context)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isMobile) ...[
                                  // Student ID
                                  Expanded(
                                    child: Text(data['studentId'] ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context))),
                                  ),
                                  // Class Name
                                  Expanded(
                                    child: Text(data['class'] ?? widget.className, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context))),
                                  ),
                                ],
                                // Actions
                                PopupMenuButton(
                                  color: AppConstants.surf(context),
                                  icon: Icon(Icons.more_vert, color: AppConstants.txtMuted(context), size: 20),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa', style: TextStyle(color: AppConstants.txt(context))), onTap: () => _showEditStudentDialog(student.id, data)),
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
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
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
              Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: valueColor)),
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
          return Center(child: Text('Lỗi: ${snapshot.error}', style: TextStyle(color: AppConstants.txt(context))));
        }

        final quizzes = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Exams', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppConstants.txt(context))),
            const SizedBox(height: 24),
            if (quizzes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Text('Chưa có bài thi nào', style: TextStyle(fontSize: 16, color: AppConstants.txtMuted(context))),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 950;
                  final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: isMobile ? 240 : 220,
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
                  );
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
      hoverColor: AppConstants.brand(context).withValues(alpha: 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          border: Border.all(color: AppConstants.border(context), style: BorderStyle.solid, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.brand(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: AppConstants.brand(context), size: 32),
            ),
            const SizedBox(height: 16),
            Text('Tạo bài thi mới', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
            const SizedBox(height: 8),
            Text('Chọn từ thư viện hoặc tự soạn thảo', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)), textAlign: TextAlign.center),
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
        final isDark = AppConstants.isDarkMode(context);
        
        // Define status color and text
        // Mặc định bài thi đã gán vào lớp sẽ ở trạng thái đang mở/đang diễn ra cho sinh viên làm
        Color statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFF82F9BE).withValues(alpha: 0.5);
        Color statusTextColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF00734C);
        String statusText = 'Đang diễn ra';
        
        if (schedule != null) {
          if (schedule.isClosed) {
            statusBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFC4D2FF).withValues(alpha: 0.5);
            statusTextColor = AppConstants.brand(context);
            statusText = 'Đã kết thúc';
          } else if (schedule.isOpen) {
            statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFF82F9BE).withValues(alpha: 0.5);
            statusTextColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF00734C);
            statusText = 'Đang diễn ra';
          } else {
            statusBgColor = AppConstants.surfLow(context);
            statusTextColor = AppConstants.txtMuted(context);
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
                  className: widget.className,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.surf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.border(context)),
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
                      child: Icon(Icons.delete_outline, color: AppConstants.txtMuted(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Text(data['title'] ?? 'Bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppConstants.txt(context)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: AppConstants.txtMuted(context)),
                    const SizedBox(width: 8),
                    Text('${data['duration'] ?? 0} phút • ${data['questionCount'] ?? 0} câu hỏi', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context))),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: AppConstants.border(context)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Chi tiết bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppConstants.txtMuted(context), fontStyle: FontStyle.italic)),
                    Row(
                      children: [
                        Text('Chi tiết', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.brand(context))),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16, color: AppConstants.brand(context)),
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
  void _openAttendanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TeacherAttendanceDialog(
        classId: widget.classId,
        className: widget.className,
        teacherId: FirebaseAuth.instance.currentUser?.uid,
      ),
    );
  }

  void _showAddStudentOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.border(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Thêm học sinh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.txt(context),
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
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.brand(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppConstants.brand(context),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm thủ công',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhập từng học sinh',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppConstants.txtMuted(context),
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
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Color(0xFF16A34A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import từ Excel',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload file .xlsx hoặc .xls',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppConstants.txtMuted(context),
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
                    side: BorderSide(color: AppConstants.border(context), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.txt(context)),
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

          final studentIdStr = (row[1]?.value?.toString() ?? '').trim();
          final name = (row[2]?.value?.toString() ?? '').trim();
          final phone = (row[4]?.value?.toString() ?? '').trim();

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
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppConstants.border(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successCount > 0
                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                          : const Color(0xFFDC2626).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      successCount > 0 ? Icons.check_circle : Icons.warning,
                      color: successCount > 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kết quả import',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.txt(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.surfLow(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.border(context)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thành công:',
                              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: AppConstants.txtMuted(context)),
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
                            Text(
                              'Lỗi:',
                              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: AppConstants.txtMuted(context)),
                            ),
                            Text(
                              '$errorCount',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFFDC2626),
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
                            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chi tiết lỗi:',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
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
                                          color: Color(0xFFDC2626),
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
                                    color: Color(0xFFDC2626),
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
                        backgroundColor: AppConstants.brand(context),
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
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.border(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.quiz_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Thêm bài thi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.txt(context),
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
                      builder: (context) => ClassCreateQuizPage(
                        classId: widget.classId,
                        className: widget.className,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) {
                      setState(() => _tabController.index = 1);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.brand(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_circle,
                          color: AppConstants.brand(context),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo bài thi mới',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tạo đề thi từ file PDF/TXT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppConstants.txtMuted(context),
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
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.library_add,
                          color: Color(0xFF16A34A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gán bài thi có sẵn',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chọn từ kho đề thi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppConstants.txtMuted(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showSelectQuestionBankDialog();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.surfLow(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xFF7C3AED),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo từ ngân hàng câu hỏi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sinh đề hoặc chọn câu hỏi từ ngân hàng',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: AppConstants.txtMuted(context),
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
                    side: BorderSide(color: AppConstants.border(context), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.txt(context)),
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
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 800,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppConstants.surf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppConstants.border(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConstants.brand(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Thêm học sinh',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.txt(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailCtrl,
                      style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                      onChanged: (_) {
                        if (emailError != null) setStateDialog(() => emailError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Email học sinh',
                        hintStyle: TextStyle(color: AppConstants.txtMuted(context)),
                        helperText: emailError == null ? '9 chữ số đầu email sẽ là mã học sinh' : null,
                        helperStyle: TextStyle(color: AppConstants.txtMuted(context), fontSize: 12),
                        errorText: emailError,
                        prefixIcon: Icon(Icons.mail, color: AppConstants.txtMuted(context)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppConstants.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppConstants.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppConstants.brand(context), width: 2),
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
                        fillColor: AppConstants.surfLow(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                      onChanged: (_) {
                        if (nameError != null) setStateDialog(() => nameError = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'Tên học sinh',
                        hintStyle: TextStyle(color: AppConstants.txtMuted(context)),
                        errorText: nameError,
                        prefixIcon: Icon(Icons.person, color: AppConstants.txtMuted(context)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppConstants.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppConstants.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppConstants.brand(context), width: 2),
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
                        fillColor: AppConstants.surfLow(context),
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
                              side: BorderSide(color: AppConstants.border(context), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.txt(context),
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
                              backgroundColor: AppConstants.brand(context),
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

  void _showEditStudentDialog(String studentDocId, Map<String, dynamic> data) {
    _studentEmailController.text = data['email'] ?? '';
    _studentNameController.text = data['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.border(context)),
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
                  Expanded(
                    child: Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.txt(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _studentEmailController,
                style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppConstants.txtMuted(context)),
                  prefixIcon: Icon(Icons.mail, color: AppConstants.txtMuted(context)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                  ),
                  filled: true,
                  fillColor: AppConstants.surfLow(context),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _studentNameController,
                style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                decoration: InputDecoration(
                  labelText: 'Tên học sinh',
                  labelStyle: TextStyle(color: AppConstants.txtMuted(context)),
                  prefixIcon: Icon(Icons.person, color: AppConstants.txtMuted(context)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppConstants.brand(context), width: 2),
                  ),
                  filled: true,
                  fillColor: AppConstants.surfLow(context),
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
                        side: BorderSide(color: AppConstants.border(context), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txt(context),
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
                        backgroundColor: AppConstants.brand(context),
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

  void _showSelectQuestionBankDialog() {
    String? selectedSubjectId;
    String? selectedSubjectName;
    String? selectedSubjectCode;
    final searchCtrl = TextEditingController();
    String searchQuery = '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final isDark = AppConstants.isDarkMode(context);

          return Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 820,
              height: 640,
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppConstants.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppConstants.surf(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                    ),
                    child: Row(
                      children: [
                        if (selectedSubjectId != null) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Quay lại chọn học phần khác',
                            onPressed: () {
                              setStateDialog(() {
                                selectedSubjectId = null;
                                selectedSubjectName = null;
                                selectedSubjectCode = null;
                                searchQuery = '';
                                searchCtrl.clear();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF7C3AED),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedSubjectId == null
                                    ? 'Bước 1: Chọn Lớp học phần'
                                    : 'Bước 2: Chọn ngân hàng câu hỏi',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.txt(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedSubjectId == null
                                    ? 'Chọn học phần để xem danh sách ngân hàng câu hỏi tương ứng'
                                    : 'Học phần: $selectedSubjectName ($selectedSubjectCode) • Tạo đề cho ${widget.className}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppConstants.txtMuted(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppConstants.txtMuted(context)),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                  ),

                  // NỘI DUNG CHÍNH (BƯỚC 1: CHỌN HỌC PHẦN HOẶC BƯỚC 2: CHỌN NGÂN HÀNG)
                  Expanded(
                    child: selectedSubjectId == null
                        ? _buildBankSubjectStep(
                            context,
                            uid,
                            (id, name, code) {
                              setStateDialog(() {
                                selectedSubjectId = id;
                                selectedSubjectName = name;
                                selectedSubjectCode = code;
                              });
                            },
                          )
                        : _buildBankListStep(
                            context,
                            dialogCtx,
                            selectedSubjectId!,
                            selectedSubjectName ?? '',
                            selectedSubjectCode ?? '',
                            searchQuery,
                            searchCtrl,
                            (newSearch) => setStateDialog(() => searchQuery = newSearch),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bước 1: Danh sách Lớp học phần cho Ngân hàng câu hỏi
  Widget _buildBankSubjectStep(
    BuildContext context,
    String teacherId,
    Function(String id, String name, String code) onSelectSubject,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: CourseSubjectService.getSubjectsStream(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
            ),
          );
        }

        final subjects = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // TÙY CHỌN 1: NGÂN HÀNG CHUNG / CHƯA PHÂN LOẠI
            _buildSubjectRowItem(
              context,
              title: 'Ngân hàng chung / Chưa phân loại',
              code: 'CHUNG',
              description: 'Các ngân hàng câu hỏi chưa được xếp vào học phần nào',
              color: Colors.blueGrey,
              icon: Icons.folder_open_rounded,
              onTap: () => onSelectSubject('_uncategorized', 'Ngân hàng chung', 'CHUNG'),
            ),
            const SizedBox(height: 10),

            // TÙY CHỌN 2: TẤT CẢ NGÂN HÀNG CÂU HỎI
            _buildSubjectRowItem(
              context,
              title: 'Xem tất cả ngân hàng câu hỏi',
              code: 'TẤT CẢ',
              description: 'Hiển thị toàn bộ các ngân hàng câu hỏi của bạn',
              color: const Color(0xFF7C3AED),
              icon: Icons.storage_rounded,
              onTap: () => onSelectSubject('_all', 'Tất cả ngân hàng', 'ALL'),
            ),
            const SizedBox(height: 16),

            if (subjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'DANH SÁCH LỚP HỌC PHẦN CỦA BẠN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ),
              ...subjects.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Học phần';
                final code = data['code'] ?? '';
                final desc = (data['description'] ?? '').toString();
                final colorHex = (data['colorHex'] ?? '#003D9B').toString();

                Color subColor;
                try {
                  subColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                } catch (_) {
                  subColor = const Color(0xFF7C3AED);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSubjectRowItem(
                    context,
                    title: name,
                    code: code,
                    description: desc.isNotEmpty ? desc : 'Nhấn để xem ngân hàng câu hỏi',
                    color: subColor,
                    icon: Icons.collections_bookmark_rounded,
                    onTap: () => onSelectSubject(doc.id, name, code),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  /// Bước 2: Danh sách Ngân hàng câu hỏi trong học phần đã chọn
  Widget _buildBankListStep(
    BuildContext context,
    BuildContext dialogCtx,
    String subjectId,
    String subjectName,
    String subjectCode,
    String searchQuery,
    TextEditingController searchController,
    Function(String) onSearchChanged,
  ) {
    Stream<QuerySnapshot> stream;
    if (subjectId == '_all') {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (subjectId == '_uncategorized') {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('quiz_banks')
          .where('courseSubjectId', isEqualTo: subjectId)
          .snapshots();
    }

    return Column(
      children: [
        // THANH TÌM KIẾM
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppConstants.surfLow(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.border(context)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ngân hàng câu hỏi trong $subjectName...',
                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                prefixIcon: Icon(Icons.search, color: AppConstants.txtMuted(context), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),

        // DANH SÁCH NGÂN HÀNG CÂU HỎI
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
                  ),
                );
              }

              var banks = snapshot.data?.docs ?? [];

              // Lọc chưa phân loại nếu chọn _uncategorized
              if (subjectId == '_uncategorized') {
                banks = banks.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final subId = data['courseSubjectId'];
                  return subId == null || subId.toString().isEmpty;
                }).toList();
              }

              // Lọc tìm kiếm
              if (searchQuery.isNotEmpty) {
                banks = banks.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  return title.contains(searchQuery.toLowerCase().trim()) || desc.contains(searchQuery.toLowerCase().trim());
                }).toList();
              }

              if (banks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppConstants.txtMuted(context)),
                        const SizedBox(height: 12),
                        Text(
                          'Không có ngân hàng câu hỏi nào trong học phần này',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.txtMuted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: banks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  final data = bank.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Ngân hàng câu hỏi';
                  final count = (data['questionCount'] ?? 0) as int;
                  final desc = data['description'] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.surfLow(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.border(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.folder_special_rounded,
                              color: Color(0xFF7C3AED),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.txt(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$count câu hỏi',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        desc,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: AppConstants.txtMuted(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizCreateFromBankPage(
                                  bankId: bank.id,
                                  bankTitle: title,
                                  questionCount: count,
                                  targetClassId: widget.classId,
                                  targetClassName: widget.className,
                                ),
                              ),
                            ).then((result) {
                              if (result == true && mounted) {
                                setState(() => _tabController.index = 1);
                              }
                            });
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: const Text(
                            'Tạo đề',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
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

  void _showAssignQuizDialog() {
    String? selectedSubjectId;
    String? selectedSubjectName;
    String? selectedSubjectCode;
    String quizSearch = '';
    final searchCtrl = TextEditingController();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isMobile = MediaQuery.of(context).size.width < 768;
          final isDark = AppConstants.isDarkMode(context);

          return Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 820,
              height: 650,
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppConstants.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppConstants.surf(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                    ),
                    child: Row(
                      children: [
                        if (selectedSubjectId != null) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Quay lại chọn học phần khác',
                            onPressed: () {
                              setDialogState(() {
                                selectedSubjectId = null;
                                selectedSubjectName = null;
                                selectedSubjectCode = null;
                                quizSearch = '';
                                searchCtrl.clear();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConstants.brand(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedSubjectId == null ? Icons.collections_bookmark_rounded : Icons.library_books_rounded,
                            color: AppConstants.brand(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedSubjectId == null
                                    ? 'Bước 1: Chọn Lớp học phần'
                                    : 'Bước 2: Chọn bài thi cần gán',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.txt(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedSubjectId == null
                                    ? 'Chọn học phần để hiển thị danh sách bài thi tương ứng'
                                    : 'Học phần: $selectedSubjectName ($selectedSubjectCode)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppConstants.txtMuted(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppConstants.txtMuted(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // NỘI DUNG CHÍNH (BƯỚC 1 HOẶC BƯỚC 2)
                  Expanded(
                    child: selectedSubjectId == null
                        ? _buildSubjectSelectionStep(
                            context,
                            uid,
                            (id, name, code) {
                              setDialogState(() {
                                selectedSubjectId = id;
                                selectedSubjectName = name;
                                selectedSubjectCode = code;
                              });
                            },
                          )
                        : _buildQuizSelectionStep(
                            context,
                            selectedSubjectId!,
                            selectedSubjectName ?? '',
                            selectedSubjectCode ?? '',
                            quizSearch,
                            searchCtrl,
                            (newSearch) => setDialogState(() => quizSearch = newSearch),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bước 1: Danh sách Lớp học phần
  Widget _buildSubjectSelectionStep(
    BuildContext context,
    String teacherId,
    Function(String id, String name, String code) onSelectSubject,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: CourseSubjectService.getSubjectsStream(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
            ),
          );
        }

        final subjects = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // TÙY CHỌN 1: ĐỀ THI CHUNG / CHƯA PHÂN LOẠI
            _buildSubjectRowItem(
              context,
              title: 'Đề thi chung / Chưa phân loại',
              code: 'CHUNG',
              description: 'Các bài thi chưa được xếp vào học phần nào',
              color: Colors.blueGrey,
              icon: Icons.folder_open_rounded,
              onTap: () => onSelectSubject('_uncategorized', 'Đề thi chung', 'CHUNG'),
            ),
            const SizedBox(height: 10),

            // TÙY CHỌN 2: TẤT CẢ BÀI THI
            _buildSubjectRowItem(
              context,
              title: 'Xem tất cả bài thi khả dụng',
              code: 'TẤT CẢ',
              description: 'Hiển thị toàn bộ các bài thi của bạn',
              color: AppConstants.brand(context),
              icon: Icons.list_alt_rounded,
              onTap: () => onSelectSubject('_all', 'Tất cả bài thi', 'ALL'),
            ),
            const SizedBox(height: 16),

            if (subjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'DANH SÁCH LỚP HỌC PHẦN CỦA BẠN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ),
              ...subjects.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Học phần';
                final code = data['code'] ?? '';
                final desc = (data['description'] ?? '').toString();
                final colorHex = (data['colorHex'] ?? '#003D9B').toString();

                Color subColor;
                try {
                  subColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                } catch (_) {
                  subColor = AppConstants.brand(context);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSubjectRowItem(
                    context,
                    title: name,
                    code: code,
                    description: desc.isNotEmpty ? desc : 'Nhấn để xem danh sách bài thi',
                    color: subColor,
                    icon: Icons.collections_bookmark_rounded,
                    onTap: () => onSelectSubject(doc.id, name, code),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSubjectRowItem(
    BuildContext context, {
    required String title,
    required String code,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = AppConstants.isDarkMode(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.surfLow(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppConstants.txtMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppConstants.txtMuted(context)),
          ],
        ),
      ),
    );
  }

  /// Bước 2: Danh sách Bài thi trong học phần đã chọn
  Widget _buildQuizSelectionStep(
    BuildContext context,
    String subjectId,
    String subjectName,
    String subjectCode,
    String searchQuery,
    TextEditingController searchController,
    Function(String) onSearchChanged,
  ) {
    Stream<QuerySnapshot> stream;
    if (subjectId == '_all') {
      stream = FirebaseFirestore.instance
          .collection('quiz')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else if (subjectId == '_uncategorized') {
      stream = FirebaseFirestore.instance
          .collection('quiz')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('quiz')
          .where('courseSubjectId', isEqualTo: subjectId)
          .snapshots();
    }

    return Column(
      children: [
        // THANH TÌM KIẾM
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppConstants.surfLow(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.border(context)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài thi trong $subjectName...',
                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                prefixIcon: Icon(Icons.search, color: AppConstants.txtMuted(context), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),

        // DANH SÁCH BÀI THI
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
                  ),
                );
              }

              var quizzes = snapshot.data?.docs ?? [];

              // Lọc chưa phân loại nếu chọn _uncategorized
              if (subjectId == '_uncategorized') {
                quizzes = quizzes.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final subId = data['courseSubjectId'];
                  return subId == null || subId.toString().isEmpty;
                }).toList();
              }

              // Lọc chỉ các quiz khả dụng
              quizzes = quizzes.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'available';
                return status == 'available';
              }).toList();

              // Lọc tìm kiếm
              if (searchQuery.isNotEmpty) {
                quizzes = quizzes.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  return title.contains(searchQuery.toLowerCase().trim());
                }).toList();
              }

              if (quizzes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_books_outlined, size: 48, color: AppConstants.txtMuted(context)),
                        const SizedBox(height: 12),
                        Text(
                          'Không có bài thi nào khả dụng trong học phần này',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.txtMuted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClassCreateQuizPage(
                                  courseSubjectId: (subjectId == '_all' || subjectId == '_uncategorized') ? null : subjectId,
                                  courseSubjectName: subjectName,
                                  courseSubjectCode: subjectCode,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tạo bài thi mới cho học phần này'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppConstants.brand(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  final data = quiz.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Bài thi';
                  final questionCount = data['questionCount'] ?? 0;
                  final duration = data['duration'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.surfLow(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.border(context)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppConstants.brand(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$questionCount',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppConstants.brand(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'câu',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppConstants.brand(context),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: AppConstants.txtMuted(context)),
                              const SizedBox(width: 4),
                              Text(
                                '$duration phút',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppConstants.txtMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            _assignQuizToClass(quiz.id, data);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add_task_rounded, size: 16),
                          label: const Text('Gán vào lớp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.brand(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      builder: (context) {
        final isDark = AppConstants.isDarkMode(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppConstants.surf(context),
          child: Container(
            width: 440,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppConstants.surf(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A1010) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xác nhận xóa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn có chắc muốn xóa học sinh "${data['name']}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppConstants.border(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
        setState(() {
          _tabController.index = 1;
        });
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
      builder: (context) {
        final isDark = AppConstants.isDarkMode(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppConstants.surf(context),
          child: Container(
            width: 440,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppConstants.surf(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A1010) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xác nhận gỡ bỏ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn có chắc muốn gỡ bài thi "${data['title']}" khỏi lớp?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppConstants.border(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Gỡ bỏ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  // ================= TEACHING ASSISTANTS SECTION & DIALOGS =================

  Widget _buildAssistantsSection(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _assistantsStream,
      builder: (context, snapshot) {
        final assistants = snapshot.data?.docs ?? [];

        return Container(
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppConstants.surfLow(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school, color: Color(0xFF7C3AED), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Trợ giảng lớp học',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${assistants.length}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isAssistant)
                      FilledButton.icon(
                        onPressed: _showManageAssistantsDialog,
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('Thêm trợ giảng', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: assistants.isEmpty
                    ? Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: AppConstants.txtMuted(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lớp học chưa có trợ giảng nào được gán. Trợ giảng có thể giúp tạo đề, quản lý sinh viên và thống kê điểm.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: assistants.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Trợ giảng';
                          final email = data['email'] ?? '';
                          final studentId = data['studentId'] ?? '';

                          return Container(
                            constraints: const BoxConstraints(minWidth: 240, maxWidth: 340),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.surfLow(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppConstants.border(context)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF7C3AED),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.txt(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'MSSV: $studentId',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: AppConstants.txtMuted(context),
                                        ),
                                      ),
                                      if (email.isNotEmpty)
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: AppConstants.txtMuted(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (!widget.isAssistant)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                    tooltip: 'Gỡ quyền trợ giảng',
                                    onPressed: () => _confirmRemoveAssistant(studentId, name, email),
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
      },
    );
  }

  void _showManageAssistantsDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String? errorMessage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 600,
                constraints: const BoxConstraints(maxHeight: 700),
                decoration: BoxDecoration(
                  color: AppConstants.surf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.border(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppConstants.surfLow(context),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school, color: Color(0xFF7C3AED), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gán Trợ giảng cho lớp',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppConstants.txt(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Trợ giảng sẽ có quyền hỗ trợ đề thi, quản lý sinh viên và xem điểm',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppConstants.txtMuted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gợi ý chọn từ sinh viên trong lớp
                            StreamBuilder<QuerySnapshot>(
                              stream: _studentsStream,
                              builder: (context, studentSnap) {
                                final studentDocs = studentSnap.data?.docs ?? [];
                                if (studentDocs.isEmpty) return const SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chọn nhanh từ học sinh trong lớp:',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.txt(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: AppConstants.surfLow(context),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppConstants.border(context)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          hint: Text(
                                            '-- Chọn sinh viên làm trợ giảng --',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              color: AppConstants.txtMuted(context),
                                            ),
                                          ),
                                          items: studentDocs.map((doc) {
                                            final sData = doc.data() as Map<String, dynamic>;
                                            final sName = sData['name'] ?? '';
                                            final sId = sData['studentId'] ?? '';
                                            return DropdownMenuItem<String>(
                                              value: doc.id,
                                              child: Text(
                                                '$sName ($sId)',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  color: AppConstants.txt(context),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (selectedDocId) {
                                            if (selectedDocId == null) return;
                                            final selectedDoc = studentDocs.firstWhere((d) => d.id == selectedDocId);
                                            final sData = selectedDoc.data() as Map<String, dynamic>;
                                            setStateDialog(() {
                                              nameCtrl.text = sData['name'] ?? '';
                                              emailCtrl.text = sData['email'] ?? (sData['studentId'] ?? '');
                                              errorMessage = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: AppConstants.border(context))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'hoặc nhập thủ công',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: AppConstants.txtMuted(context),
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: AppConstants.border(context))),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),

                            // Input Email/MSSV
                            Text(
                              'Email hoặc MSSV sinh viên *',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: emailCtrl,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
                              decoration: InputDecoration(
                                hintText: 'Ví dụ: 102210123@sv1.dut.udn.vn hoặc 102210123',
                                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                                prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppConstants.txtMuted(context)),
                                filled: true,
                                fillColor: AppConstants.surfLow(context),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Input Họ và tên
                            Text(
                              'Họ và tên Trợ giảng *',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.txt(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
                              decoration: InputDecoration(
                                hintText: 'Ví dụ: Nguyễn Văn A',
                                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                                prefixIcon: Icon(Icons.person_outline, size: 20, color: AppConstants.txtMuted(context)),
                                filled: true,
                                fillColor: AppConstants.surfLow(context),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                              ),
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: const TextStyle(fontFamily: 'Inter', color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        final inputEmail = emailCtrl.text.trim();
                                        final inputName = nameCtrl.text.trim();

                                        if (inputEmail.isEmpty) {
                                          setStateDialog(() => errorMessage = 'Vui lòng nhập email hoặc MSSV');
                                          return;
                                        }
                                        if (inputName.isEmpty) {
                                          setStateDialog(() => errorMessage = 'Vui lòng nhập họ tên trợ giảng');
                                          return;
                                        }

                                        String studentId = _extractStudentId(inputEmail);
                                        if (studentId.isEmpty) {
                                          final digits = inputEmail.replaceAll(RegExp(r'[^0-9]'), '');
                                          if (digits.length >= 8) {
                                            studentId = digits;
                                          }
                                        }

                                        if (studentId.length < 8) {
                                          setStateDialog(() => errorMessage = 'Email hoặc MSSV không hợp lệ (cần ít nhất 8-9 chữ số MSSV)');
                                          return;
                                        }

                                        setStateDialog(() {
                                          isSubmitting = true;
                                          errorMessage = null;
                                        });

                                        try {
                                          await FirebaseService.addAssistantToClass(
                                            classId: widget.classId,
                                            studentId: studentId,
                                            name: inputName,
                                            email: inputEmail.contains('@') ? inputEmail : '$studentId@sv1.dut.udn.vn',
                                          );

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text('✅ Đã gán trợ giảng thành công: $inputName ($studentId)'),
                                                backgroundColor: Colors.green.shade600,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (err) {
                                          setStateDialog(() {
                                            isSubmitting = false;
                                            errorMessage = err.toString().replaceAll('Exception: ', '');
                                          });
                                        }
                                      },
                                icon: isSubmitting
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check, size: 18),
                                label: Text(
                                  isSubmitting ? 'Đang lưu...' : 'Xác nhận gán Trợ giảng',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRemoveAssistant(String studentId, String name, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppConstants.surf(context),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Gỡ quyền Trợ giảng',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: AppConstants.txt(context)),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn gỡ quyền trợ giảng của sinh viên "$name" (MSSV: $studentId)?\nSinh viên này sẽ không còn quyền quản lý lớp học này nữa.',
          style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context))),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService.removeAssistantFromClass(
                  classId: widget.classId,
                  studentId: studentId,
                  email: email,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã gỡ quyền trợ giảng của $name'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận gỡ', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
