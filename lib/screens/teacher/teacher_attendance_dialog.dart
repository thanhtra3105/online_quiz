// lib/screens/teacher/teacher_attendance_dialog.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

class TeacherAttendanceDialog extends StatefulWidget {
  final String classId;
  final String className;
  final String? teacherId;

  const TeacherAttendanceDialog({
    super.key,
    required this.classId,
    required this.className,
    this.teacherId,
  });

  @override
  State<TeacherAttendanceDialog> createState() => _TeacherAttendanceDialogState();
}

class _TeacherAttendanceDialogState extends State<TeacherAttendanceDialog> {
  bool _isFullscreen = false;
  int _selectedDuration1 = 2; // phút mặc định
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _searchStudentController = TextEditingController();
  String _studentSearchQuery = '';
  String _filterStatus = 'all'; // all, full, partial, absent

  late final Stream<QuerySnapshot> _activeSessionStream;
  late final Stream<QuerySnapshot> _allSessionsStream;
  Stream<QuerySnapshot>? _recordsStream;
  String? _cachedRecordsSessionId;

  Stream<QuerySnapshot> _getRecordsStream(String sessionId) {
    if (_recordsStream == null || _cachedRecordsSessionId != sessionId) {
      _cachedRecordsSessionId = sessionId;
      _recordsStream = AttendanceService.getSessionRecordsStream(widget.classId, sessionId);
    }
    return _recordsStream!;
  }

  @override
  void initState() {
    super.initState();
    _activeSessionStream = AttendanceService.getActiveSessionStream(widget.classId);
    _allSessionsStream = AttendanceService.getAllSessionsStream(widget.classId);
    _customTitleController.text =
        'Điểm danh ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _searchStudentController.dispose();
    super.dispose();
  }

  // Xuất Excel điểm danh
  Future<void> _exportToExcel(
    BuildContext context,
    Map<String, dynamic> sessionData,
    List<QueryDocumentSnapshot> records,
  ) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'DiemDanh';
      final sheet = excel[sheetName];
      excel.delete('Sheet1');

      final title = sessionData['title'] ?? 'Điểm danh';
      final sessionDate = (sessionData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Headers
      final headerStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#003D9B'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headers = [
        'STT',
        'Mã SV / Email',
        'Họ và tên',
        'Thời gian điểm danh',
        'Xác thực vị trí GPS',
        'Khoảng cách đến lớp',
        'Tọa độ SV (Lat, Lng)',
        'Kết quả điểm danh',
      ];

      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = headerStyle;
      }

      int rowIdx = 1;
      for (var r in records) {
        final d = (r.data() as Map<String, dynamic>?) ?? {};
        final sId = d['studentId']?.toString() ?? '';
        final sName = d['studentName']?.toString() ?? '';
        final c1 = d['checkIn1'] == true;
        final c2 = d['checkIn2'] == true;
        final status = d['status']?.toString() ?? 'absent';
        final isDone = c1 || c2 || status == 'full' || status == 'present';

        final checkTime = (d['checkIn1Time'] as Timestamp?)?.toDate() ??
            (d['checkIn2Time'] as Timestamp?)?.toDate() ??
            (d['updatedAt'] as Timestamp?)?.toDate();

        final isNear = d['isNearClass'] as bool?;
        final dist = (d['distanceMeters'] as num?)?.toDouble();
        final locStatus = d['locationStatus']?.toString();
        final sLat = d['studentLatitude'];
        final sLng = d['studentLongitude'];

        // Chỉ hiển thị 'Hợp lệ' hoặc 'Không hợp lệ' theo yêu cầu
        String gpsText = '-';
        if (isNear == true) {
          gpsText = 'Hợp lệ';
        } else if (isNear == false) {
          gpsText = 'Không hợp lệ';
        } else if (locStatus == 'denied') {
          gpsText = 'Không hợp lệ (Từ chối GPS)';
        }

        final distText = dist != null ? AttendanceService.formatDistance(dist) : '-';
        final coordText = (sLat != null && sLng != null) ? '$sLat, $sLng' : '-';
        final resultText = isDone ? 'Có mặt' : 'Vắng mặt';
        final timeFmt = DateFormat('HH:mm:ss dd/MM/yyyy');
        final timeText = (isDone && checkTime != null) ? timeFmt.format(checkTime) : '-';

        sheet.appendRow([
          IntCellValue(rowIdx),
          TextCellValue(sId),
          TextCellValue(sName),
          TextCellValue(timeText),
          TextCellValue(gpsText),
          TextCellValue(distText),
          TextCellValue(coordText),
          TextCellValue(resultText),
        ]);

        // Làm nổi bật cột Kết quả điểm danh (Cột index 7)
        final resultCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx));
        resultCell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          fontColorHex: isDone
              ? ExcelColor.fromHexString('#047857')
              : ExcelColor.fromHexString('#BE123C'),
          backgroundColorHex: isDone
              ? ExcelColor.fromHexString('#D1FAE5')
              : ExcelColor.fromHexString('#FFE4E6'),
        );

        // Định dạng cột Xác thực vị trí GPS (Cột index 4)
        if (isNear != null || locStatus == 'denied') {
          final gpsCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx));
          gpsCell.cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
            fontColorHex: isNear == true
                ? ExcelColor.fromHexString('#047857')
                : ExcelColor.fromHexString('#BE123C'),
          );
        }

        rowIdx++;
      }

      final cleanName = title.replaceAll(RegExp(r'[^\w\s\u00C0-\u1EF9]+'), '').trim();
      final fileName = 'DiemDanh_${cleanName}_${DateFormat('yyyyMMdd').format(sessionDate)}.xlsx';

      excel.save(fileName: fileName);

      if (context.mounted) {
        final isDark = AppConstants.isDarkMode(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('Đã xuất file điểm danh: $fileName'),
              ],
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất file Excel: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _activeSessionStream,
      builder: (context, snapshot) {
        final activeDocs = snapshot.data?.docs ?? [];
        final hasActiveSession = activeDocs.isNotEmpty;

        return Dialog(
          backgroundColor: AppConstants.surf(context),
          insetPadding: _isFullscreen
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
            side: BorderSide(color: AppConstants.border(context)),
          ),
          child: Container(
            width: _isFullscreen ? double.infinity : 1080,
            height: _isFullscreen ? double.infinity : 760,
            decoration: BoxDecoration(
              color: AppConstants.surf(context),
              borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 20),
            ),
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(hasActiveSession, isDark),
                const Divider(height: 1, thickness: 1),

                // Main Content Body
                Expanded(
                  child: hasActiveSession
                      ? _buildActiveSessionView(activeDocs.first, isDark)
                      : _buildCreateSessionView(isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // HEADER BAR
  // ============================================
  Widget _buildHeader(bool hasActiveSession, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Hệ thống Điểm danh QR & Định vị GPS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.txt(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (hasActiveSession)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF047857),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ĐANG MỞ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Lớp: ${widget.className} • Điểm danh 1 lần bảo mật định vị GPS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _isFullscreen ? 'Thu nhỏ cửa sổ' : 'Chiếu toàn màn hình (Máy chiếu)',
            onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
              color: AppConstants.txt(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(context)),
          ),
        ],
      ),
    );
  }

  // ============================================
  // VIEW 1: FORM TẠO PHIÊN ĐIỂM DANH MỚI
  // ============================================
  Widget _buildCreateSessionView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin hướng dẫn cơ chế QR & GPS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppConstants.brand(context), size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cơ chế Điểm danh bằng Mã QR & Định vị GPS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.txt(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• Phiên điểm danh sẽ phát sinh 1 mã QR ngẫu nhiên và mã số 8 chữ số tương ứng.\n'
                            '• Sinh viên bắt buộc phải bật định vị vị trí GPS trên thiết bị khi mở điểm danh.\n'
                            '• Hệ thống tự động đối soát vị trí thực tế của sinh viên với bán kính phòng học (≤500m) để ngăn chặn điểm danh hộ từ xa.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppConstants.txtMuted(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tên / Tiêu đề buổi điểm danh
              Text(
                'Tiêu đề phiên điểm danh',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.txt(context),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customTitleController,
                decoration: InputDecoration(
                  hintText: 'Nhập tiêu đề (Ví dụ: Buổi 3 - Đại số tuyến tính)',
                  prefixIcon: const Icon(Icons.event_note_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppConstants.surfLow(context),
                ),
              ),
              const SizedBox(height: 24),

              // Cài đặt thời gian hết hạn mã QR
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thời gian hết hạn mã QR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.txt(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedDuration1,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppConstants.surfLow(context),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 phút (Rất nhanh)')),
                      DropdownMenuItem(value: 2, child: Text('2 phút (Tiêu chuẩn)')),
                      DropdownMenuItem(value: 3, child: Text('3 phút')),
                      DropdownMenuItem(value: 5, child: Text('5 phút')),
                      DropdownMenuItem(value: 10, child: Text('10 phút')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuration1 = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Nút Bắt đầu điểm danh
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    final title = _customTitleController.text.trim();
                    await AttendanceService.createAttendanceSession(
                      classId: widget.classId,
                      className: widget.className,
                      title: title,
                      duration1Minutes: _selectedDuration1,
                      createdBy: widget.teacherId,
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                  label: const Text(
                    'Bắt đầu điểm danh (Phát mã QR)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.brand(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // Danh sách các phiên điểm danh trước đó
              Text(
                'Lịch sử các buổi điểm danh đã qua',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.txt(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildHistorySection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // VIEW 2: MÀN HÌNH ĐIỂM DANH TRỰC TIẾP (LIVE SCREEN)
  // ============================================
  Widget _buildActiveSessionView(DocumentSnapshot sessionDoc, bool isDark) {
    final sessionData = (sessionDoc.data() as Map<String, dynamic>?) ?? {};
    final sessionId = sessionDoc.id;

    final code = (sessionData['code1'] ?? sessionData['code'] ?? '').toString();
    final expiresAt = (sessionData['expiresAt1'] ?? sessionData['expiresAt']) as Timestamp?;

    return StreamBuilder<QuerySnapshot>(
      stream: _getRecordsStream(sessionId),
      builder: (context, recordsSnap) {
        final records = recordsSnap.data?.docs ?? [];
        final totalCount = records.length;
        final countPresent = records.where((d) {
          final data = d.data() as Map;
          return data['checkIn1'] == true ||
              data['checkIn2'] == true ||
              data['status'] == 'full' ||
              data['status'] == 'present';
        }).length;
        final countAbsent = totalCount - countPresent;
        final countNear = records.where((d) => (d.data() as Map)['isNearClass'] == true).length;
        final countFar = records.where((d) => (d.data() as Map)['isNearClass'] == false).length;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột bên trái: Máy chiếu QR & Mã số to
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Vị trí GPS của buổi học + Nút Cập nhật GPS phòng
                    _buildLocationInfoBar(sessionData, sessionId, isDark),
                    const SizedBox(height: 18),

                    // Khung QR to ở giữa (tự quản lý đếm ngược cục bộ, không trigger dialog rebuild)
                    _AttendanceQrCard(
                      classId: widget.classId,
                      phase: 1,
                      code: code,
                      expiresAt: expiresAt,
                      sessionId: sessionId,
                      isFullscreen: _isFullscreen,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Nút điều khiển kết thúc điểm danh
                    _buildControlsRow(
                      context: context,
                      sessionId: sessionId,
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1, thickness: 1),

            // Cột bên phải: Danh sách & Bảng thống kê Realtime
            Expanded(
              flex: 4,
              child: Container(
                color: isDark ? AppConstants.surfLow(context) : const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat Cards
                    _buildStatCardsRow(
                      total: totalCount,
                      countPresent: countPresent,
                      countAbsent: countAbsent,
                      countNear: countNear,
                      countFar: countFar,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Search & Filter
                    _buildSearchAndFilter(isDark),
                    const SizedBox(height: 12),

                    // Header danh sách + Nút xuất Excel
                    Row(
                      children: [
                        Text(
                          'Danh sách điểm danh realtime',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => _exportToExcel(context, sessionData, records),
                          icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF047857)),
                          label: const Text(
                            'Xuất Excel',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF047857)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Danh sách sinh viên
                    Expanded(
                      child: _buildStudentRecordsList(
                        records: records,
                        sessionId: sessionId,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // ============================================
  // KHU VỰC VỊ TRÍ GPS (CHỐNG ĐIỂM DANH HỘ)
  // ============================================
  Widget _buildLocationInfoBar(Map<String, dynamic> sessionData, String sessionId, bool isDark) {
    final locationName = sessionData['locationName'] ?? 'Trường ĐH Bách Khoa - ĐH Đà Nẵng';
    final radius = (sessionData['maxRadiusMeters'] as num?)?.toInt() ?? 500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF047857).withValues(alpha: 0.3) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 16,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Xác thực vị trí: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$locationName (≤${radius}m)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txt(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Sinh viên điểm danh trong bán kính ${radius}m quanh trường/phòng sẽ được đánh dấu Tại lớp',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang lấy vị trí GPS thực tế của giảng viên...'),
                  duration: Duration(milliseconds: 1500),
                ),
              );

              final loc = await LocationService.getCurrentLocation(timeout: const Duration(seconds: 6));
              if (!loc.success || loc.latitude == null || loc.longitude == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể lấy GPS: ${loc.errorMessage ?? "Vui lòng cho phép quyền vị trí trong trình duyệt"}'),
                      backgroundColor: const Color(0xFFBE123C),
                    ),
                  );
                }
                return;
              }

              await AttendanceService.updateSessionLocation(
                classId: widget.classId,
                sessionId: sessionId,
                latitude: loc.latitude!,
                longitude: loc.longitude!,
                locationName: 'GPS Phòng học (${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)})',
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Đã cập nhật tọa độ phòng học theo GPS của bạn thành công!'),
                      ],
                    ),
                    backgroundColor: Color(0xFF047857),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.my_location_rounded,
              size: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            label: Text(
              'Cập nhật GPS phòng',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFF0F172A),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTION BUTTONS (KẾT THÚC ĐIỂM DANH)
  // ============================================
  Widget _buildControlsRow({
    required BuildContext context,
    required String sessionId,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Kết thúc phiên điểm danh?'),
              content: const Text(
                'Mã QR sẽ dừng nhận điểm danh và lưu kết quả buổi điểm danh vào lịch sử lớp.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBE123C)),
                  child: const Text('Đồng ý kết thúc'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await AttendanceService.closeAttendanceSession(
              classId: widget.classId,
              sessionId: sessionId,
            );
          }
        },
        icon: Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        label: Text(
          'Hoàn tất & Đóng điểm danh',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          side: BorderSide(
            color: isDark ? const Color(0xFF475569) : const Color(0xFF0F172A),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isDark ? 0 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  // ============================================
  // STAT CARDS (REALTIME)
  // ============================================
  Widget _buildStatCardsRow({
    required int total,
    required int countPresent,
    required int countAbsent,
    required int countNear,
    required int countFar,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCardMini('Tổng sĩ số', '$total', Icons.groups_outlined, const Color(0xFF475569), isDark),
            const SizedBox(width: 6),
            _buildStatCardMini('Đã điểm danh', '$countPresent', Icons.check_circle_rounded, const Color(0xFF047857), isDark),
            const SizedBox(width: 6),
            _buildStatCardMini('Chưa điểm danh', '$countAbsent', Icons.cancel_outlined, const Color(0xFF64748B), isDark),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildStatCardMini('Tại lớp', '$countNear', Icons.location_on_rounded, const Color(0xFF047857), isDark),
            const SizedBox(width: 6),
            _buildStatCardMini('Ở xa', '$countFar', Icons.wrong_location_rounded, const Color(0xFFBE123C), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCardMini(String title, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.surf(context) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              val,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppConstants.txtMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SEARCH & FILTER
  // ============================================
  Widget _buildSearchAndFilter(bool isDark) {
    return Column(
      children: [
        TextFormField(
          controller: _searchStudentController,
          decoration: InputDecoration(
            hintText: 'Tìm sinh viên theo tên hoặc mã...',
            prefixIcon: const Icon(Icons.search, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: AppConstants.surf(context),
            isDense: true,
          ),
          onChanged: (val) => setState(() => _studentSearchQuery = val.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'Tất cả'),
              const SizedBox(width: 6),
              _buildFilterChip('present', 'Đã điểm danh'),
              const SizedBox(width: 6),
              _buildFilterChip('absent', 'Chưa điểm danh'),
              const SizedBox(width: 6),
              _buildFilterChip('near', 'Tại lớp'),
              const SizedBox(width: 6),
              _buildFilterChip('far', 'Ở xa'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    final isDark = AppConstants.isDarkMode(context);
    final brandGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    final bgGreen = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
        : const Color(0xFFECFDF5);
    final borderGreen = isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? brandGreen
              : AppConstants.txtMuted(context),
        ),
      ),
      selected: isSelected,
      selectedColor: bgGreen,
      backgroundColor: AppConstants.surf(context),
      side: BorderSide(
        color: isSelected ? borderGreen : AppConstants.border(context),
      ),
      onSelected: (val) {
        if (val) setState(() => _filterStatus = key);
      },
    );
  }

  // ============================================
  // DANH SÁCH SINH VIÊN REALTIME
  // ============================================
  Widget _buildStudentRecordsList({
    required List<QueryDocumentSnapshot> records,
    required String sessionId,
    required bool isDark,
  }) {
    // Lọc theo search và status
    final filtered = records.where((doc) {
      final d = (doc.data() as Map<String, dynamic>?) ?? {};
      final name = (d['studentName'] ?? '').toString().toLowerCase();
      final id = (d['studentId'] ?? '').toString().toLowerCase();
      final status = (d['status'] ?? 'absent').toString();
      final isDone = d['checkIn1'] == true || d['checkIn2'] == true || status == 'full' || status == 'present';
      final isNear = d['isNearClass'] as bool?;

      final matchesSearch = _studentSearchQuery.isEmpty ||
          name.contains(_studentSearchQuery) ||
          id.contains(_studentSearchQuery);

      bool matchesFilter = false;
      if (_filterStatus == 'all') {
        matchesFilter = true;
      } else if (_filterStatus == 'present') {
        matchesFilter = isDone;
      } else if (_filterStatus == 'absent') {
        matchesFilter = !isDone;
      } else if (_filterStatus == 'near') {
        matchesFilter = isNear == true;
      } else if (_filterStatus == 'far') {
        matchesFilter = isNear == false;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Không có sinh viên nào khớp bộ lọc',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final doc = filtered[index];
        final d = (doc.data() as Map<String, dynamic>?) ?? {};
        final sId = d['studentId']?.toString() ?? doc.id;
        final sName = d['studentName']?.toString() ?? 'Sinh viên';
        final status = d['status']?.toString() ?? 'absent';
        final isDone = d['checkIn1'] == true || d['checkIn2'] == true || status == 'full' || status == 'present';
        final isNear = d['isNearClass'] as bool?;
        final dist = (d['distanceMeters'] as num?)?.toDouble();
        final locStatus = d['locationStatus']?.toString();

        final Color badgeColor = isDone ? const Color(0xFF047857) : const Color(0xFFBE123C);
        final String badgeText = isDone ? 'Có mặt' : 'Vắng';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppConstants.border(context)),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: badgeColor.withValues(alpha: 0.15),
                    child: Text(
                      sName.isNotEmpty ? sName[0].toUpperCase() : 'S',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ),
                  if (isNear != null)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isNear ? const Color(0xFF047857) : const Color(0xFFBE123C),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.txt(context),
                            ),
                          ),
                        ),
                        if (isNear != null || locStatus == 'denied')
                          _buildLocationTag(
                            isNear: isNear,
                            distanceMeters: dist,
                            locationStatus: locStatus,
                            isDark: isDark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          sId,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppConstants.txtMuted(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Nút chỉnh sửa thủ công
              PopupMenuButton<String>(
                tooltip: 'Sửa điểm danh thủ công',
                icon: const Icon(Icons.more_vert, size: 16),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'mark_present',
                    child: Text(isDone ? 'Đã có mặt (Cập nhật lại)' : 'Đánh dấu có mặt'),
                  ),
                  PopupMenuItem(
                    value: 'mark_absent',
                    child: Text(!isDone ? 'Đã vắng (Cập nhật lại)' : 'Đánh dấu vắng mặt'),
                  ),
                ],
                onSelected: (val) async {
                  if (val == 'mark_present') {
                    await AttendanceService.manualUpdateRecord(
                      classId: widget.classId,
                      sessionId: sessionId,
                      studentId: sId,
                      studentName: sName,
                      studentEmail: d['studentEmail'] ?? '',
                      isPresent: true,
                      checkIn1: true,
                      checkIn2: true,
                    );
                  } else if (val == 'mark_absent') {
                    await AttendanceService.manualUpdateRecord(
                      classId: widget.classId,
                      sessionId: sessionId,
                      studentId: sId,
                      studentName: sName,
                      studentEmail: d['studentEmail'] ?? '',
                      isPresent: false,
                      checkIn1: false,
                      checkIn2: false,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // HUY HIỆU VỊ TRÍ GPS CỦA SINH VIÊN
  // ============================================
  Widget _buildLocationTag({
    required bool? isNear,
    required double? distanceMeters,
    required String? locationStatus,
    required bool isDark,
  }) {
    if (isNear == true) {
      final distStr = distanceMeters != null ? ' (~${AttendanceService.formatDistance(distanceMeters)})' : '';
      return Tooltip(
        message: 'Vị trí hợp lệ: Đang có mặt tại lớp/trường ($distStr)',
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 11,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
              ),
              const SizedBox(width: 3),
              Text(
                'Tại lớp$distStr',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isNear == false) {
      final distStr = distanceMeters != null ? ' (~${AttendanceService.formatDistance(distanceMeters)})' : '';
      return Tooltip(
        message: 'Cảnh báo vị trí: Sinh viên đang ở xa lớp học (>500m)',
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.35) : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wrong_location_rounded,
                size: 11,
                color: isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C),
              ),
              const SizedBox(width: 3),
              Text(
                'Ở xa$distStr',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (locationStatus == 'denied') {
      return Tooltip(
        message: 'Sinh viên từ chối cấp quyền GPS hoặc thiết bị chưa bật vị trí',
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 11,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
              ),
              const SizedBox(width: 3),
              Text(
                'Không GPS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ============================================
  // LỊCH SỬ CÁC BUỔI ĐIỂM DANH ĐÃ QUA
  // ============================================
  Widget _buildHistorySection(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _allSessionsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Lớp này chưa có phiên điểm danh nào trước đây.',
                style: TextStyle(color: AppConstants.txtMuted(context)),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = (doc.data() as Map<String, dynamic>?) ?? {};
            final title = data['title'] ?? 'Điểm danh';
            final status = data['status'] ?? 'closed';
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final dateStr = date != null ? DateFormat('HH:mm - dd/MM/yyyy').format(date) : '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.surfLow(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.border(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'active' ? Icons.fiber_manual_record : Icons.check_circle_outline,
                    color: status == 'active' ? const Color(0xFF047857) : AppConstants.txtMuted(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        Text(
                          '$dateStr • Trạng thái: ${status == 'active' ? 'Đang mở' : 'Đã đóng'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppConstants.txtMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút xuất Excel lịch sử
                  IconButton(
                    tooltip: 'Xuất file Excel',
                    icon: const Icon(Icons.file_download_outlined, color: Color(0xFF047857)),
                    onPressed: () async {
                      final recordsSnap = await doc.reference.collection('records').get();
                      if (context.mounted) {
                        await _exportToExcel(context, data, recordsSnap.docs);
                      }
                    },
                  ),

                  // Nút xóa
                  IconButton(
                    tooltip: 'Xóa phiên điểm danh này',
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFBE123C), size: 20),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: const Text('Bạn có chắc chắn muốn xóa phiên điểm danh này không?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBE123C)),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await AttendanceService.deleteSession(
                          classId: widget.classId,
                          sessionId: doc.id,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AttendanceQrCard extends StatefulWidget {
  final String classId;
  final int phase;
  final String code;
  final Timestamp? expiresAt;
  final String sessionId;
  final bool isFullscreen;
  final bool isDark;

  const _AttendanceQrCard({
    Key? key,
    required this.classId,
    required this.phase,
    required this.code,
    required this.expiresAt,
    required this.sessionId,
    required this.isFullscreen,
    required this.isDark,
  }) : super(key: key);

  @override
  State<_AttendanceQrCard> createState() => _AttendanceQrCardState();
}

class _AttendanceQrCardState extends State<_AttendanceQrCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration _calculateRemaining(Timestamp? expiresAt) {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt.toDate().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _calculateRemaining(widget.expiresAt);
    final isExpired = remaining == Duration.zero;
    final formattedCode = AttendanceService.format8DigitCode(widget.code);
    final qrPayload = 'ATTENDANCE:${widget.classId}:${widget.sessionId}:${widget.phase}:${widget.code}';
    final activeGreen = widget.isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    final activeGreenBg = widget.isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
        : const Color(0xFFECFDF5);
    final activeGreenBorder = widget.isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0);

    final expiredRed = widget.isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C);
    final expiredRedBg = widget.isDark
        ? const Color(0xFF4C0519).withValues(alpha: 0.35)
        : const Color(0xFFFFF1F2);
    final expiredRedBorder = widget.isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? (widget.isDark ? const Color(0xFF9F1239) : const Color(0xFFFDA4AF))
              : AppConstants.brand(context).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge giai đoạn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isExpired ? expiredRedBg : activeGreenBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isExpired ? expiredRedBorder : activeGreenBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 16,
                  color: isExpired ? expiredRed : activeGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpired
                      ? 'MÃ ĐÃ HẾT HẠN (Hãy gia hạn thêm nếu cần)'
                      : 'MÃ ĐANG HOẠT ĐỘNG • CÒN LẠI: ${_formatDuration(remaining)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? expiredRed : activeGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // QR Code Image
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: widget.isFullscreen ? 280 : 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF041B3C),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF041B3C),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Số ngẫu nhiên 8 chữ số to rõ
          Text(
            'HOẶC NHẬP MÃ 8 CHỮ SỐ:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.txtMuted(context),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép mã 8 chữ số vào bộ nhớ tạm'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark ? AppConstants.border(context) : const Color(0xFFDBEAFE),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.isFullscreen ? 40 : 34,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.brand(context),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.copy_rounded, size: 20, color: AppConstants.brand(context)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nút gia hạn thời gian
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gia hạn thêm:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppConstants.txtMuted(context),
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('+1 phút'),
                onPressed: () => AttendanceService.extendTime(
                  classId: widget.classId,
                  sessionId: widget.sessionId,
                  phase: widget.phase,
                  additionalMinutes: 1,
                ),
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('+2 phút'),
                onPressed: () => AttendanceService.extendTime(
                  classId: widget.classId,
                  sessionId: widget.sessionId,
                  phase: widget.phase,
                  additionalMinutes: 2,
                ),
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('+5 phút'),
                onPressed: () => AttendanceService.extendTime(
                  classId: widget.classId,
                  sessionId: widget.sessionId,
                  phase: widget.phase,
                  additionalMinutes: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
