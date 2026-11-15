// lib/screens/student/student_attendance_dialog.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

class StudentAttendanceDialog extends StatefulWidget {
  final String classId;
  final String className;
  final String studentId;
  final String studentName;
  final String studentEmail;

  const StudentAttendanceDialog({
    super.key,
    required this.classId,
    required this.className,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
  });

  @override
  State<StudentAttendanceDialog> createState() => _StudentAttendanceDialogState();
}

class _StudentAttendanceDialogState extends State<StudentAttendanceDialog>
    with SingleTickerProviderStateMixin {
  // 0: Quét Camera, 1: Nhập mã số
  int _activeTab = 0;

  final TextEditingController _codeController = TextEditingController();
  MobileScannerController? _cameraController;
  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool _isSuccessFeedback = false;
  bool _isTorchOn = false;
  bool _hasScanned = false; // Ngăn scan trùng lặp nhiều lần

  // Bắt buộc vị trí GPS
  UserLocationResult? _userLocation;
  bool _isCheckingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initScanner();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isCheckingLocation = true;
      _locationError = null;
    });

    final loc = await LocationService.getCurrentLocation(timeout: const Duration(seconds: 8));

    if (!mounted) return;

    if (loc.success && loc.latitude != null && loc.longitude != null) {
      setState(() {
        _userLocation = loc;
        _isCheckingLocation = false;
        _locationError = null;
      });
    } else {
      setState(() {
        _userLocation = null;
        _isCheckingLocation = false;
        _locationError = loc.errorMessage ?? 'Bạn chưa cấp quyền truy cập vị trí trên trình duyệt.';
      });
    }
  }

  void _initScanner() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitAttendanceCode(String inputCode) async {
    if (_isSubmitting) return;

    final rawCode = inputCode.trim();
    if (rawCode.isEmpty) {
      setState(() {
        _feedbackMessage = 'Vui lòng nhập hoặc quét mã điểm danh 8 chữ số!';
        _isSuccessFeedback = false;
      });
      return;
    }

    if (_userLocation == null || !_userLocation!.success) {
      await _requestLocationPermission();
      if (_userLocation == null || !_userLocation!.success) {
        setState(() {
          _feedbackMessage = 'Bắt buộc phải bật định vị vị trí GPS để điểm danh!';
          _isSuccessFeedback = false;
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    // Gửi mã điểm danh và tọa độ GPS đã xác thực
    final result = await AttendanceService.checkInStudent(
      classId: widget.classId,
      studentId: widget.studentId,
      studentName: widget.studentName,
      studentEmail: widget.studentEmail,
      inputCode: rawCode,
      studentLatitude: _userLocation!.latitude,
      studentLongitude: _userLocation!.longitude,
      locationAccuracy: _userLocation!.accuracy,
      locationStatus: _userLocation!.status,
    );

    if (!mounted) return;

    final bool isSuccess = result['success'] == true;

    setState(() {
      _isSubmitting = false;
      _feedbackMessage = result['message'];
      _isSuccessFeedback = isSuccess;
      if (isSuccess) {
        _codeController.clear();
      }
    });

    if (isSuccess) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.vibrate();
      // Cho phép scan lại sau 2.5 giây nếu thất bại
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _hasScanned = false);
      });
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned || _isSubmitting) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        _hasScanned = true;
        _submitAttendanceCode(code.trim());
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);
    final bool hasLocation = _userLocation != null && _userLocation!.success;

    return Dialog(
      backgroundColor: AppConstants.surf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppConstants.border(context)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar (Monochrome/Brand theme)
                _buildHeader(context, isDark, true),
                const SizedBox(height: 18),

                // Bắt buộc vị trí: nếu chưa có quyền vị trí -> Chặn lại ở Gate này
                if (!hasLocation)
                  _buildLocationGate(isDark)
                else
                  StreamBuilder<QuerySnapshot>(
                    stream: AttendanceService.getActiveSessionStream(widget.classId),
                    builder: (context, snapshot) {
                      final activeDocs = snapshot.data?.docs ?? [];
                      final hasActiveSession = activeDocs.isNotEmpty;
                      final activeSessionDoc = hasActiveSession ? activeDocs.first : null;

                      if (!hasActiveSession || activeSessionDoc == null) {
                        return Column(
                          children: [
                            _buildNoActiveSessionCard(context, isDark),
                            const SizedBox(height: 16),
                            _buildModeSwitcher(isDark),
                            const SizedBox(height: 16),
                            if (_activeTab == 0) _buildCameraView(isDark) else _buildManualInputView(isDark),
                            if (_feedbackMessage != null) ...[
                              const SizedBox(height: 14),
                              _buildFeedbackBanner(isDark),
                            ],
                            const SizedBox(height: 14),
                            _buildSecurityNote(isDark),
                          ],
                        );
                      }

                      return StreamBuilder<DocumentSnapshot>(
                        stream: AttendanceService.getStudentRecordStream(
                          widget.classId,
                          activeSessionDoc.id,
                          widget.studentId,
                        ),
                        builder: (context, recordSnap) {
                          final recordData = (recordSnap.data?.data() as Map<String, dynamic>?) ?? {};
                          final bool isDone = recordData['checkIn1'] == true ||
                              recordData['status'] == 'full' ||
                              recordData['status'] == 'present';

                          if (isDone) {
                            return Column(
                              children: [
                                _buildDoneCard(context, activeSessionDoc, recordData, isDark),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Đóng cửa sổ'),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActiveSessionCard(context, activeSessionDoc, isDark),
                              const SizedBox(height: 16),
                              _buildModeSwitcher(isDark),
                              const SizedBox(height: 16),
                              if (_activeTab == 0) _buildCameraView(isDark) else _buildManualInputView(isDark),
                              if (_feedbackMessage != null) ...[
                                const SizedBox(height: 14),
                                _buildFeedbackBanner(isDark),
                              ],
                              const SizedBox(height: 14),
                              _buildSecurityNote(isDark),
                            ],
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader(BuildContext context, bool isDark, bool hasActive) {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Điểm danh lớp học',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.txt(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Text(
                        'ĐANG MỞ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.className,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(context)),
          tooltip: 'Đóng',
        ),
      ],
    );
  }

  // ============================================
  // SEGMENTED SWITCHER (CAMERA vs MÃ SỐ)
  // ============================================
  Widget _buildModeSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = 0;
                  _hasScanned = false;
                  _feedbackMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTab == 0
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: _activeTab == 0
                      ? Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF0F172A),
                          width: 1.2,
                        )
                      : null,
                  boxShadow: _activeTab == 0 && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: _activeTab == 0
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : AppConstants.txtMuted(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quét Camera QR',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _activeTab == 0
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : AppConstants.txt(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = 1;
                  _feedbackMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTab == 1
                      ? (isDark ? const Color(0xFF334155) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: _activeTab == 1
                      ? Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF0F172A),
                          width: 1.2,
                        )
                      : null,
                  boxShadow: _activeTab == 1 && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pin_outlined,
                      size: 16,
                      color: _activeTab == 1
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : AppConstants.txtMuted(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nhập mã 8 số',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _activeTab == 1
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : AppConstants.txt(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CAMERA VIEW (QUÉT TRỰC TIẾP TỪ CAMERA THẬT)
  // ============================================
  Widget _buildCameraView(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera Stream Widget
          SizedBox(
            height: 270,
            width: double.infinity,
            child: _cameraController == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : MobileScanner(
                    controller: _cameraController,
                    onDetect: _onBarcodeDetected,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 36),
                              const SizedBox(height: 10),
                              const Text(
                                'Không thể truy cập camera',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Vui lòng cấp quyền camera trong trình duyệt hoặc bấm tab "Nhập mã 8 số".',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => setState(() => _activeTab = 1),
                                icon: const Icon(Icons.pin_outlined, size: 16, color: Colors.white),
                                label: const Text('Chuyển sang Nhập mã số', style: TextStyle(color: Colors.white)),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Khung viền ngắm quét (Viewfinder corners)
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
          ),

          // Lời nhắc phía trên camera
          Positioned(
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.center_focus_weak_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Hướng camera vào mã QR của giảng viên',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút bật đèn flash / đổi camera
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Bật/tắt đèn',
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                  onPressed: () async {
                    try {
                      await _cameraController?.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    } catch (_) {}
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Đổi camera trước/sau',
                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                  ),
                  onPressed: () async {
                    try {
                      await _cameraController?.switchCamera();
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),

          // Indicator khi đang gửi điểm danh
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Đang xác thực mã...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // MANUAL INPUT VIEW (BẮT BUỘC TỰ NHẬP MÃ 8 SỐ, KHÔNG NÚT DÁN)
  // ============================================
  Widget _buildManualInputView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập mã điểm danh 8 chữ số:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.txt(context),
          ),
        ),
        const SizedBox(height: 8),

        // Text field: Tự nhập, KHÔNG có nút dán (Paste)
        TextFormField(
          controller: _codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          enableInteractiveSelection: false, // Ngăn menu dán tự động
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          ),
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
          ],
          decoration: InputDecoration(
            hintText: '48291048',
            hintStyle: TextStyle(
              fontSize: 18,
              letterSpacing: 2,
              color: AppConstants.txtMuted(context).withValues(alpha: 0.4),
            ),
            counterText: '',
            prefixIcon: Icon(Icons.keyboard_outlined, color: AppConstants.txtMuted(context)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppConstants.surfLow(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onFieldSubmitted: (val) => _submitAttendanceCode(val),
        ),
        const SizedBox(height: 12),

        // Nút xác nhận điểm danh (Nền trắng, chữ và icon đen đồng bộ)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : () => _submitAttendanceCode(_codeController.text),
            icon: _isSubmitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  )
                : Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
            label: Text(
              _isSubmitting ? 'Đang xác thực...' : 'Xác nhận điểm danh',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: isDark ? 0 : 1,
              shadowColor: Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // FEEDBACK BANNER
  // ============================================
  Widget _buildFeedbackBanner(bool isDark) {
    final Color bg = _isSuccessFeedback
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.35) : const Color(0xFFFFF1F2));
    final Color border = _isSuccessFeedback
        ? (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
        : (isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3));
    final Color txtColor = _isSuccessFeedback
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
        : (isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isSuccessFeedback ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 18,
            color: border,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedbackMessage!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: txtColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CHƯA CÓ PHIÊN ĐIỂM DANH
  // ============================================
  Widget _buildNoActiveSessionCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Giảng viên chưa mở phiên điểm danh cho lớp này. Nếu giảng viên đọc mã số, bạn có thể tự nhập ở dưới.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CỔNG YÊU CẦU BẬT VỊ TRÍ GPS (GATE KHOÁ CHỨC NĂNG ĐIỂM DANH)
  // ============================================
  Widget _buildLocationGate(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 42,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bắt buộc bật vị trí GPS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppConstants.txt(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống yêu cầu xác thực bạn đang có mặt tại trường ĐH Bách Khoa để điểm danh. Chỉ khi vị trí GPS được bật, bạn mới có thể thực hiện quét mã hoặc nhập mã điểm danh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppConstants.txtMuted(context),
              height: 1.5,
            ),
          ),
          if (_locationError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFBE123C), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFFBE123C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '💡 Cách mở: Bấm biểu tượng ổ khóa 🔒 góc trái thanh địa chỉ trình duyệt -> Cho phép mục Vị trí (Location) -> Bấm nút bên dưới.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: AppConstants.txtMuted(context),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isCheckingLocation ? null : _requestLocationPermission,
              icon: _isCheckingLocation
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 18,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
              label: Text(
                _isCheckingLocation ? 'Đang kiểm tra vị trí...' : 'Bật vị trí & Tiếp tục điểm danh',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // THẺ ĐÃ ĐIỂM DANH THÀNH CÔNG
  // ============================================
  Widget _buildDoneCard(
    BuildContext context,
    DocumentSnapshot sessionDoc,
    Map<String, dynamic> recordData,
    bool isDark,
  ) {
    final sessionData = (sessionDoc.data() as Map<String, dynamic>?) ?? {};
    final title = sessionData['title'] ?? 'Buổi điểm danh';
    final cTime = (recordData['checkIn1Time'] as Timestamp?)?.toDate();
    final timeStr = cTime != null ? DateFormat('HH:mm - dd/MM/yyyy').format(cTime) : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF047857),
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'ĐÃ ĐIỂM DANH THÀNH CÔNG',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppConstants.txt(context),
            ),
          ),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Thời gian: $timeStr',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppConstants.txtMuted(context),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _buildStudentLocationBadge(recordData, isDark),
        ],
      ),
    );
  }

  // ============================================
  // PHIÊN ĐIỂM DANH ĐANG PHÁT (1 LẦN DUY NHẤT)
  // ============================================
  Widget _buildActiveSessionCard(
    BuildContext context,
    DocumentSnapshot sessionDoc,
    bool isDark,
  ) {
    final sessionData = (sessionDoc.data() as Map<String, dynamic>?) ?? {};
    final title = sessionData['title'] ?? 'Buổi điểm danh';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 20,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
            ),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quét mã QR từ máy chiếu hoặc nhập mã 8 số bên dưới.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0)),
            ),
            child: Text(
              'ĐANG MỞ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLocationBadge(Map<String, dynamic> recordData, bool isDark) {
    final isNear = recordData['isNearClass'] as bool?;
    final dist = (recordData['distanceMeters'] as num?)?.toDouble();
    final status = recordData['locationStatus']?.toString();

    if (isNear == true) {
      final text = 'Vị trí hợp lệ: Đang có mặt tại lớp (${AttendanceService.formatDistance(dist)})';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, size: 14, color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isNear == false) {
      final text = 'Cảnh báo vị trí: Cách lớp học ${AttendanceService.formatDistance(dist)} (>500m)';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.35) : const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3)),
        ),
        child: Row(
          children: [
            Icon(Icons.wrong_location_rounded, size: 14, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'denied') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, size: 14, color: Color(0xFFB45309)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Chưa cấp quyền GPS vị trí khi điểm danh.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ============================================
  // SECURITY NOTE
  // ============================================
  Widget _buildSecurityNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 15, color: AppConstants.txtMuted(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '• Quét camera trực tiếp hoặc nhập bằng tay, không hỗ trợ tải ảnh.\n'
              '• Hệ thống tự xác thực GPS vị trí.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppConstants.txtMuted(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
