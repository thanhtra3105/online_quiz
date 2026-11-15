// lib/services/attendance_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tọa độ chuẩn Trường Đại học Bách Khoa - Đại học Đà Nẵng (DUT)
  // 54 Nguyễn Lương Bằng, Liên Chiểu, Đà Nẵng
  static const double dutLatitude = 16.0738;
  static const double dutLongitude = 108.1499;
  static const double defaultMaxRadiusMeters = 500.0;
  static const String defaultLocationName = 'ĐH Bách Khoa - ĐH Đà Nẵng (DUT)';

  /// Tính khoảng cách giữa 2 tọa độ GPS theo công thức Haversine (đơn vị: mét)
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0; // Bán kính trái đất (mét)
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Định dạng khoảng cách hiển thị (VD: "~45m" hoặc "~2.3km")
  static String formatDistance(double? meters) {
    if (meters == null) return 'Không có GPS';
    if (meters < 1000) {
      return '~${meters.round()}m';
    } else {
      final km = meters / 1000.0;
      return '~${km.toStringAsFixed(1)}km';
    }
  }

  /// Tạo ngẫu nhiên chuỗi 8 chữ số (VD: 48291048)
  static String generate8DigitCode() {
    final random = Random();
    final number = 10000000 + random.nextInt(90000000);
    return number.toString();
  }

  /// Định dạng mã 8 số để dễ đọc (VD: "4829 1048")
  static String format8DigitCode(String code) {
    final clean = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 8) {
      return '${clean.substring(0, 4)} ${clean.substring(4)}';
    }
    return code;
  }

  /// Lấy Stream phiên điểm danh đang hoạt động của một lớp
  static Stream<QuerySnapshot> getActiveSessionStream(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  /// Lấy Stream tất cả các phiên điểm danh của lớp (sắp xếp theo thời gian mới nhất)
  static Stream<QuerySnapshot> getAllSessionsStream(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Lấy Stream danh sách sinh viên đã điểm danh trong 1 session
  static Stream<QuerySnapshot> getSessionRecordsStream(String classId, String sessionId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('records')
        .snapshots();
  }

  /// Lấy Stream bản ghi điểm danh của 1 sinh viên cụ thể trong 1 session
  static Stream<DocumentSnapshot> getStudentRecordStream(
      String classId, String sessionId, String studentId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('records')
        .doc(studentId)
        .snapshots();
  }

  /// Bắt đầu phiên điểm danh mới (Bật Mã QR 1 - Bước 1)
  static Future<String> createAttendanceSession({
    required String classId,
    required String className,
    String? title,
    int duration1Minutes = 2,
    int duration2Minutes = 2,
    String? createdBy,
    bool requireLocation = true,
    double? targetLatitude,
    double? targetLongitude,
    double maxRadiusMeters = 500.0,
    String? locationName,
  }) async {
    final now = DateTime.now();
    final defaultTitle = 'Điểm danh ${DateFormat('dd/MM/yyyy HH:mm').format(now)}';
    final code1 = generate8DigitCode();
    final expiresAt1 = now.add(Duration(minutes: duration1Minutes));

    final sessionRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc();

    final sessionData = {
      'id': sessionRef.id,
      'classId': classId,
      'className': className,
      'title': (title != null && title.trim().isNotEmpty) ? title.trim() : defaultTitle,
      'status': 'active', // 'active' | 'closed'
      'currentPhase': 1,  // 1: Đang phát QR 1, 2: Đang phát QR 2
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy ?? '',

      // Cấu hình định vị GPS chống điểm danh hộ
      'requireLocation': requireLocation,
      'targetLatitude': targetLatitude ?? dutLatitude,
      'targetLongitude': targetLongitude ?? dutLongitude,
      'maxRadiusMeters': maxRadiusMeters,
      'locationName': locationName ?? defaultLocationName,

      // Cấu hình QR 1
      'code1': code1,
      'duration1Minutes': duration1Minutes,
      'duration1Seconds': duration1Minutes * 60,
      'startedAt1': Timestamp.fromDate(now),
      'expiresAt1': Timestamp.fromDate(expiresAt1),
      'isActive1': true,

      // Cấu hình QR 2 (chưa kích hoạt)
      'code2': null,
      'duration2Minutes': duration2Minutes,
      'duration2Seconds': duration2Minutes * 60,
      'startedAt2': null,
      'expiresAt2': null,
      'isActive2': false,
    };

    await sessionRef.set(sessionData);

    // Đồng bộ danh sách sinh viên hiện có của lớp vào records
    try {
      final studentsSnap = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      final batch = _firestore.batch();
      for (var sDoc in studentsSnap.docs) {
        final sData = sDoc.data();
        final sId = sData['studentId']?.toString() ?? sDoc.id;
        final sName = sData['name']?.toString() ?? 'Sinh viên';
        final sEmail = sData['email']?.toString() ?? '';

        final rDoc = sessionRef.collection('records').doc(sId);
        batch.set(rDoc, {
          'studentId': sId,
          'studentName': sName,
          'studentEmail': sEmail,
          'checkIn1': false,
          'checkIn1Time': null,
          'checkIn2': false,
          'checkIn2Time': null,
          'status': 'absent', // 'full' | 'partial' | 'absent'
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}

    return sessionRef.id;
  }

  /// Chuyển sang Mã QR 2 (Bước 2) - Cơ chế chống gian lận
  static Future<String> startPhase2({
    required String classId,
    required String sessionId,
    int? customDuration2Minutes,
  }) async {
    final now = DateTime.now();
    final sessionDoc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId)
        .get();

    final data = sessionDoc.data() ?? {};
    final durationMinutes = customDuration2Minutes ?? (data['duration2Minutes'] as num? ?? 2).toInt();
    final code2 = generate8DigitCode();
    final expiresAt2 = now.add(Duration(minutes: durationMinutes));

    await sessionDoc.reference.update({
      'currentPhase': 2,
      'isActive1': false,
      'code2': code2,
      'duration2Minutes': durationMinutes,
      'duration2Seconds': durationMinutes * 60,
      'startedAt2': Timestamp.fromDate(now),
      'expiresAt2': Timestamp.fromDate(expiresAt2),
      'isActive2': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return code2;
  }

  /// Gia hạn thêm thời gian cho mã QR hiện tại (thêm N phút)
  static Future<void> extendTime({
    required String classId,
    required String sessionId,
    required int phase,
    int additionalMinutes = 1,
  }) async {
    final sessionRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId);

    final doc = await sessionRef.get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};

    if (phase == 1) {
      final currentExpire = (data['expiresAt1'] as Timestamp?)?.toDate() ?? DateTime.now();
      final base = currentExpire.isAfter(DateTime.now()) ? currentExpire : DateTime.now();
      final newExpire = base.add(Duration(minutes: additionalMinutes));
      await sessionRef.update({
        'expiresAt1': Timestamp.fromDate(newExpire),
        'isActive1': true,
      });
    } else {
      final currentExpire = (data['expiresAt2'] as Timestamp?)?.toDate() ?? DateTime.now();
      final base = currentExpire.isAfter(DateTime.now()) ? currentExpire : DateTime.now();
      final newExpire = base.add(Duration(minutes: additionalMinutes));
      await sessionRef.update({
        'expiresAt2': Timestamp.fromDate(newExpire),
        'isActive2': true,
      });
    }
  }

  /// Kết thúc phiên điểm danh
  static Future<void> closeAttendanceSession({
    required String classId,
    required String sessionId,
  }) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId)
        .update({
      'status': 'closed',
      'isActive1': false,
      'isActive2': false,
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cập nhật tọa độ vị trí mục tiêu của phiên điểm danh (khi Giảng viên cập nhật GPS)
  static Future<void> updateSessionLocation({
    required String classId,
    required String sessionId,
    required double latitude,
    required double longitude,
    String? locationName,
    double? maxRadiusMeters,
  }) async {
    final updateData = <String, dynamic>{
      'targetLatitude': latitude,
      'targetLongitude': longitude,
      'locationName': locationName ?? 'Vị trí hiện tại của Giảng viên',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (maxRadiusMeters != null) {
      updateData['maxRadiusMeters'] = maxRadiusMeters;
    }
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId)
        .update(updateData);
  }

  /// Sinh viên điểm danh (quét QR hoặc nhập mã 8 chữ số)
  static Future<Map<String, dynamic>> checkInStudent({
    required String classId,
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String inputCode,
    double? studentLatitude,
    double? studentLongitude,
    double? locationAccuracy,
    String? locationStatus,
  }) async {
    try {
      // 1. Chuẩn hóa mã nhập vào (bỏ khoảng trắng, dấu gạch nối)
      String cleanCode = inputCode.replaceAll(RegExp(r'[\s\-_]'), '').trim();

      // Nếu mã là dạng payload QR URL hoặc ATTENDANCE format
      if (cleanCode.contains(':')) {
        final parts = cleanCode.split(':');
        cleanCode = parts.last.trim();
      }

      if (cleanCode.isEmpty) {
        return {
          'success': false,
          'message': 'Vui lòng nhập mã điểm danh 8 chữ số.',
        };
      }

      // 2. Tìm phiên điểm danh đang mở ('status' == 'active')
      final sessionsSnap = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('attendance_sessions')
          .where('status', isEqualTo: 'active')
          .get();

      if (sessionsSnap.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Hiện tại giảng viên chưa mở phiên điểm danh nào cho lớp này.',
        };
      }

      final sessionDoc = sessionsSnap.docs.first;
      final sessionData = sessionDoc.data();

      final now = DateTime.now();
      final code1 = (sessionData['code1'] ?? '').toString().trim();
      final code2 = (sessionData['code2'] ?? '').toString().trim();

      final expiresAt1 = (sessionData['expiresAt1'] as Timestamp?)?.toDate();
      final expiresAt2 = (sessionData['expiresAt2'] as Timestamp?)?.toDate();

      // Grace period 10 giây dự phòng độ trễ mạng
      const gracePeriod = Duration(seconds: 10);

      final recordRef = sessionDoc.reference.collection('records').doc(studentId);
      final recordSnap = await recordRef.get();
      final recordData = recordSnap.exists ? (recordSnap.data() ?? {}) : <String, dynamic>{};

      final bool hasCheckIn1 = recordData['checkIn1'] == true;
      final bool hasCheckIn2 = recordData['checkIn2'] == true;

      // 3. Tính toán khoảng cách GPS (chống điểm danh hộ từ xa)
      final targetLat = (sessionData['targetLatitude'] as num?)?.toDouble() ?? dutLatitude;
      final targetLng = (sessionData['targetLongitude'] as num?)?.toDouble() ?? dutLongitude;
      final maxRadius = (sessionData['maxRadiusMeters'] as num?)?.toDouble() ?? defaultMaxRadiusMeters;

      double? distanceMeters;
      bool? isNearClass;

      if (studentLatitude != null && studentLongitude != null) {
        distanceMeters = calculateDistanceMeters(
          studentLatitude,
          studentLongitude,
          targetLat,
          targetLng,
        );
        isNearClass = distanceMeters <= maxRadius;
      }

      final locationPayload = <String, dynamic>{
        'studentLatitude': studentLatitude,
        'studentLongitude': studentLongitude,
        'locationAccuracy': locationAccuracy,
        'locationStatus': locationStatus ?? (studentLatitude != null ? 'allowed' : 'unknown'),
        'distanceMeters': distanceMeters != null ? double.parse(distanceMeters.toStringAsFixed(1)) : null,
        'isNearClass': isNearClass,
        'locationCheckedAt': FieldValue.serverTimestamp(),
      };

      String locFeedback = '';
      if (isNearClass == true) {
        locFeedback = ' • 📍 Vị trí: Đang ở tại lớp (${formatDistance(distanceMeters)})';
      } else if (isNearClass == false) {
        locFeedback = ' • ⚠️ Cảnh báo: Cách lớp ${formatDistance(distanceMeters)} (>500m)';
      } else if (locationStatus == 'denied') {
        locFeedback = ' • 📍 Chưa bật GPS định vị';
      }

      // 4. Kiểm tra mã điểm danh
      if (cleanCode == code1) {
        // Kiểm tra hết hạn mã QR
        if (expiresAt1 != null && now.isAfter(expiresAt1.add(gracePeriod))) {
          return {
            'success': false,
            'message': 'Mã điểm danh đã hết hạn thời gian! Hãy liên hệ giảng viên nếu bạn có mặt tại lớp.',
          };
        }

        if (hasCheckIn1) {
          return {
            'success': false,
            'isAlreadyDone': true,
            'message': 'Bạn đã hoàn tất điểm danh cho buổi học này rồi!',
          };
        }

        // Ghi nhận điểm danh thành công 1 lần duy nhất
        await recordRef.set({
          'studentId': studentId,
          'studentName': studentName,
          'studentEmail': studentEmail,
          'checkIn1': true,
          'checkIn1Time': FieldValue.serverTimestamp(),
          'checkIn2': true,
          'checkIn2Time': FieldValue.serverTimestamp(),
          'status': 'full', // 'full' / 'present'
          'updatedAt': FieldValue.serverTimestamp(),
          ...locationPayload,
        }, SetOptions(merge: true));

        return {
          'success': true,
          'isCompleted': true,
          'isNearClass': isNearClass,
          'distanceMeters': distanceMeters,
          'message': 'Điểm danh thành công!' + locFeedback,
        };
      } else if (cleanCode == code2 && code2.isNotEmpty) {
        // Kiểm tra hết hạn QR 2
        if (expiresAt2 != null && now.isAfter(expiresAt2.add(gracePeriod))) {
          return {
            'success': false,
            'message': 'Mã QR 2 đã hết hạn thời gian điểm danh! Hãy liên hệ giảng viên nếu bạn có mặt tại lớp.',
          };
        }

        if (hasCheckIn2) {
          return {
            'success': false,
            'isAlreadyDone': true,
            'message': 'Bạn đã điểm danh Mã QR 2 thành công rồi!',
          };
        }

        // Ghi nhận QR 2 thành công
        final newStatus = hasCheckIn1 ? 'full' : 'partial';
        await recordRef.set({
          'studentId': studentId,
          'studentName': studentName,
          'studentEmail': studentEmail,
          'checkIn1': hasCheckIn1,
          'checkIn1Time': recordData['checkIn1Time'],
          'checkIn2': true,
          'checkIn2Time': FieldValue.serverTimestamp(),
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
          ...locationPayload,
        }, SetOptions(merge: true));

        return {
          'success': true,
          'phase': 2,
          'isCompleted': newStatus == 'full',
          'isNearClass': isNearClass,
          'distanceMeters': distanceMeters,
          'message': (hasCheckIn1
              ? 'Xuất sắc! Bạn đã hoàn tất đầy đủ 2 bước điểm danh cho buổi học hôm nay!'
              : 'Đã điểm danh Mã QR 2 thành công! (Lưu ý: Bạn bị thiếu lượt quét Mã QR 1).') + locFeedback,
        };
      } else {
        return {
          'success': false,
          'message': 'Mã điểm danh không chính xác hoặc không thuộc đợt điểm danh này. Vui lòng kiểm tra lại 8 chữ số!',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi điểm danh: $e',
      };
    }
  }

  /// Giáo viên cập nhật điểm danh thủ công (nếu sinh viên quên máy hoặc gặp sự cố)
  static Future<void> manualUpdateRecord({
    required String classId,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String studentEmail,
    bool isPresent = true,
    bool? checkIn1,
    bool? checkIn2,
  }) async {
    final bool present = checkIn1 ?? isPresent;
    final status = present ? 'full' : 'absent';

    final ref = _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('records')
        .doc(studentId);

    await ref.set({
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'checkIn1': present,
      'checkIn1Time': present ? FieldValue.serverTimestamp() : null,
      'checkIn2': present,
      'checkIn2Time': present ? FieldValue.serverTimestamp() : null,
      'status': status,
      'isManual': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Xóa phiên điểm danh
  static Future<void> deleteSession({
    required String classId,
    required String sessionId,
  }) async {
    final sessionRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('attendance_sessions')
        .doc(sessionId);

    final records = await sessionRef.collection('records').get();
    final batch = _firestore.batch();
    for (var r in records.docs) {
      batch.delete(r.reference);
    }
    batch.delete(sessionRef);
    await batch.commit();
  }
}
