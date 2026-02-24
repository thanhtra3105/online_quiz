// lib/services/quiz_schedule_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/quiz_schedule_model.dart';

class QuizScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _schedulerTimer;
  static bool _isRunning = false;

  /// Khởi động scheduler để tự động mở/đóng đề thi theo lịch
  static void startScheduler() {
    if (_isRunning) {
      print('⏰ Scheduler already running');
      return;
    }

    print('🚀 Starting Quiz Scheduler...');
    _isRunning = true;

    // Chạy mỗi phút
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndUpdateSchedules();
    });

    // Chạy ngay lần đầu
    _checkAndUpdateSchedules();
  }

  /// Dừng scheduler
  static void stopScheduler() {
    print('🛑 Stopping Quiz Scheduler...');
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    _isRunning = false;
  }

  /// Kiểm tra và cập nhật trạng thái các đề thi theo lịch
  static Future<void> _checkAndUpdateSchedules() async {
    try {
      print('🔍 Checking quiz schedules...');
      final now = DateTime.now();

      // Lấy tất cả schedules đang active
      final schedulesSnapshot = await _firestore
          .collection('quiz_schedules')
          .where('status', whereIn: ['scheduled', 'open'])
          .get();

      for (var doc in schedulesSnapshot.docs) {
        final schedule = QuizSchedule.fromFirestore(doc);
        bool needsUpdate = false;
        String? newStatus;

        // Kiểm tra nếu cần mở
        if (schedule.autoOpen &&
            schedule.openTime != null &&
            now.isAfter(schedule.openTime!) &&
            schedule.status == 'scheduled') {
          print(
            '📂 Opening quiz: ${schedule.quizId} in class: ${schedule.classId}',
          );
          newStatus = 'open';
          needsUpdate = true;
        }

        // Kiểm tra nếu cần đóng
        if (schedule.autoClose &&
            schedule.closeTime != null &&
            now.isAfter(schedule.closeTime!) &&
            schedule.status == 'open') {
          print(
            '🔒 Closing quiz: ${schedule.quizId} in class: ${schedule.classId}',
          );
          newStatus = 'closed';
          needsUpdate = true;
        }

        // Cập nhật nếu cần
        if (needsUpdate && newStatus != null) {
          await _updateScheduleStatus(schedule.id, newStatus);

          // Cập nhật status trong class/quizzes subcollection nếu cần
          await _updateClassQuizStatus(
            schedule.classId,
            schedule.quizId,
            newStatus,
          );
        }
      }
    } catch (e) {
      print('❌ Error checking schedules: $e');
    }
  }

  /// Cập nhật trạng thái schedule
  static Future<void> _updateScheduleStatus(
    String scheduleId,
    String status,
  ) async {
    await _firestore.collection('quiz_schedules').doc(scheduleId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cập nhật trạng thái quiz trong class
  static Future<void> _updateClassQuizStatus(
    String classId,
    String quizId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(quizId)
          .update({
            'scheduleStatus': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('⚠️ Could not update class quiz status: $e');
    }
  }

  /// Tạo schedule mới
  static Future<String> createSchedule({
    required String quizId,
    required String classId,
    DateTime? openTime,
    DateTime? closeTime,
    bool autoOpen = false,
    bool autoClose = false,
  }) async {
    try {
      // Validate
      if (openTime != null &&
          closeTime != null &&
          closeTime.isBefore(openTime)) {
        throw Exception('Thời gian đóng phải sau thời gian mở');
      }

      // Xác định status ban đầu
      String status = 'scheduled';
      final now = DateTime.now();

      if (openTime == null || now.isAfter(openTime)) {
        status = 'open';
      }

      final scheduleData = {
        'quizId': quizId,
        'classId': classId,
        'openTime': openTime != null ? Timestamp.fromDate(openTime) : null,
        'closeTime': closeTime != null ? Timestamp.fromDate(closeTime) : null,
        'autoOpen': autoOpen,
        'autoClose': autoClose,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('quiz_schedules')
          .add(scheduleData);

      // Cập nhật schedule ID vào class/quizzes
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(quizId)
          .update({
            'scheduleId': docRef.id,
            'scheduleStatus': status,
            'hasSchedule': true,
          });

      print('✅ Schedule created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating schedule: $e');
      rethrow;
    }
  }

  /// Cập nhật schedule
  static Future<void> updateSchedule({
    required String scheduleId,
    DateTime? openTime,
    DateTime? closeTime,
    bool? autoOpen,
    bool? autoClose,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (openTime != null) updates['openTime'] = Timestamp.fromDate(openTime);
      if (closeTime != null)
        updates['closeTime'] = Timestamp.fromDate(closeTime);
      if (autoOpen != null) updates['autoOpen'] = autoOpen;
      if (autoClose != null) updates['autoClose'] = autoClose;
      if (status != null) updates['status'] = status;

      await _firestore
          .collection('quiz_schedules')
          .doc(scheduleId)
          .update(updates);
      print('✅ Schedule updated: $scheduleId');
    } catch (e) {
      print('❌ Error updating schedule: $e');
      rethrow;
    }
  }

  /// Xóa schedule
  static Future<void> deleteSchedule(String scheduleId) async {
    try {
      // Lấy thông tin schedule trước khi xóa
      final doc = await _firestore
          .collection('quiz_schedules')
          .doc(scheduleId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final classId = data['classId'];
        final quizId = data['quizId'];

        // Xóa schedule
        await doc.reference.delete();

        // Cập nhật class/quizzes
        await _firestore
            .collection('classes')
            .doc(classId)
            .collection('quizzes')
            .doc(quizId)
            .update({
              'scheduleId': FieldValue.delete(),
              'scheduleStatus': FieldValue.delete(),
              'hasSchedule': false,
            });
      }

      print('✅ Schedule deleted: $scheduleId');
    } catch (e) {
      print('❌ Error deleting schedule: $e');
      rethrow;
    }
  }

  /// Lấy schedule theo quiz và class
  static Future<QuizSchedule?> getSchedule(
    String classId,
    String quizId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('quiz_schedules')
          .where('classId', isEqualTo: classId)
          .where('quizId', isEqualTo: quizId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return QuizSchedule.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting schedule: $e');
      return null;
    }
  }

  /// Lấy tất cả schedules của một class
  static Stream<List<QuizSchedule>> getClassSchedules(String classId) {
    return _firestore
        .collection('quiz_schedules')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizSchedule.fromFirestore(doc))
              .toList(),
        );
  }

  /// Kiểm tra xem quiz có thể làm không (theo lịch)
  static Future<bool> canTakeQuiz(String classId, String quizId) async {
    try {
      final schedule = await getSchedule(classId, quizId);

      // Nếu không có lịch thì có thể làm
      if (schedule == null) return true;

      // Kiểm tra theo lịch
      final now = DateTime.now();

      // Kiểm tra đã đóng chưa
      if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
        return false;
      }

      // Kiểm tra đã mở chưa
      if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
        return false;
      }

      // Kiểm tra status
      return schedule.status == 'open';
    } catch (e) {
      print('❌ Error checking quiz availability: $e');
      return true; // Mặc định cho phép làm nếu có lỗi
    }
  }

  /// Lấy thông tin thời gian còn lại
  static Future<Map<String, dynamic>> getTimeInfo(
    String classId,
    String quizId,
  ) async {
    try {
      final schedule = await getSchedule(classId, quizId);

      if (schedule == null) {
        return {
          'hasSchedule': false,
          'canTake': true,
          'message': 'Không có lịch giới hạn',
        };
      }

      final now = DateTime.now();

      // Kiểm tra đã đóng
      if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
        return {
          'hasSchedule': true,
          'canTake': false,
          'status': 'closed',
          'message': 'Đề thi đã đóng',
          'closedAt': schedule.closeTime,
        };
      }

      // Kiểm tra chưa mở
      if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
        final timeUntilOpen = schedule.openTime!.difference(now);
        return {
          'hasSchedule': true,
          'canTake': false,
          'status': 'scheduled',
          'message': 'Đề thi chưa mở',
          'openAt': schedule.openTime,
          'timeUntilOpen': timeUntilOpen,
        };
      }

      // Đang mở
      Map<String, dynamic> result = {
        'hasSchedule': true,
        'canTake': true,
        'status': 'open',
        'message': 'Đề thi đang mở',
        'openedAt': schedule.openTime,
      };

      if (schedule.closeTime != null) {
        final timeUntilClose = schedule.closeTime!.difference(now);
        result['closeAt'] = schedule.closeTime;
        result['timeUntilClose'] = timeUntilClose;
      }

      return result;
    } catch (e) {
      print('❌ Error getting time info: $e');
      return {'hasSchedule': false, 'canTake': true, 'error': e.toString()};
    }
  }

  /// Mở quiz ngay lập tức (manual)
  static Future<void> openQuizNow(String classId, String quizId) async {
    try {
      final schedule = await getSchedule(classId, quizId);

      if (schedule != null) {
        await updateSchedule(scheduleId: schedule.id, status: 'open');

        await _updateClassQuizStatus(classId, quizId, 'open');
      }

      print('✅ Quiz opened manually');
    } catch (e) {
      print('❌ Error opening quiz: $e');
      rethrow;
    }
  }

  /// Đóng quiz ngay lập tức (manual)
  static Future<void> closeQuizNow(String classId, String quizId) async {
    try {
      final schedule = await getSchedule(classId, quizId);

      if (schedule != null) {
        await updateSchedule(scheduleId: schedule.id, status: 'closed');

        await _updateClassQuizStatus(classId, quizId, 'closed');
      }

      print('✅ Quiz closed manually');
    } catch (e) {
      print('❌ Error closing quiz: $e');
      rethrow;
    }
  }
}
