// lib/services/course_subject_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSubjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream danh sách các lớp học phần của giáo viên
  static Stream<QuerySnapshot> getSubjectsStream(String teacherId) {
    return _firestore
        .collection('course_subjects')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  /// Lấy danh sách lớp học phần
  static Future<List<QueryDocumentSnapshot>> getSubjects(String teacherId) async {
    final snap = await _firestore
        .collection('course_subjects')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snap.docs;
  }

  /// Tạo một lớp học phần mới
  static Future<DocumentReference> createSubject({
    required String teacherId,
    required String name,
    required String code,
    String? description,
    String? colorHex,
  }) async {
    final now = DateTime.now();
    return await _firestore.collection('course_subjects').add({
      'teacherId': teacherId,
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'description': description?.trim() ?? '',
      'colorHex': colorHex ?? '#003D9B',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cập nhật lớp học phần
  static Future<void> updateSubject({
    required String subjectId,
    required String name,
    required String code,
    String? description,
    String? colorHex,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'description': description?.trim() ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (colorHex != null) {
      data['colorHex'] = colorHex;
    }

    await _firestore.collection('course_subjects').doc(subjectId).update(data);

    // Cập nhật tên/mã trong các quiz thuộc học phần này
    try {
      final quizzes = await _firestore
          .collection('quiz')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var q in quizzes.docs) {
        await q.reference.update({
          'courseSubjectName': name.trim(),
          'courseSubjectCode': code.trim().toUpperCase(),
        });
      }
    } catch (_) {}

    // Cập nhật tên/mã trong các ngân hàng câu hỏi thuộc học phần này
    try {
      final banks = await _firestore
          .collection('quiz_banks')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var b in banks.docs) {
        await b.reference.update({
          'courseSubjectName': name.trim(),
          'courseSubjectCode': code.trim().toUpperCase(),
        });
      }
    } catch (_) {}

    // Cập nhật tên/mã trong các lớp học thuộc học phần này
    try {
      final classes = await _firestore
          .collection('classes')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var c in classes.docs) {
        await c.reference.update({
          'courseSubjectName': name.trim(),
          'courseSubjectCode': code.trim().toUpperCase(),
        });
      }
    } catch (_) {}
  }

  /// Xóa lớp học phần
  static Future<void> deleteSubject(String subjectId) async {
    await _firestore.collection('course_subjects').doc(subjectId).delete();

    // Gỡ liên kết trong các đề thi
    try {
      final quizzes = await _firestore
          .collection('quiz')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var q in quizzes.docs) {
        await q.reference.update({
          'courseSubjectId': FieldValue.delete(),
          'courseSubjectName': FieldValue.delete(),
          'courseSubjectCode': FieldValue.delete(),
        });
      }
    } catch (_) {}

    // Gỡ liên kết trong các ngân hàng câu hỏi
    try {
      final banks = await _firestore
          .collection('quiz_banks')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var b in banks.docs) {
        await b.reference.update({
          'courseSubjectId': FieldValue.delete(),
          'courseSubjectName': FieldValue.delete(),
          'courseSubjectCode': FieldValue.delete(),
        });
      }
    } catch (_) {}

    // Gỡ liên kết trong các lớp học
    try {
      final classes = await _firestore
          .collection('classes')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var c in classes.docs) {
        await c.reference.update({
          'courseSubjectId': FieldValue.delete(),
          'courseSubjectName': FieldValue.delete(),
          'courseSubjectCode': FieldValue.delete(),
        });
      }
    } catch (_) {}
  }

  /// Gán lớp học vào học phần
  static Future<void> assignClassToSubject({
    required String classId,
    required String subjectId,
    required String subjectName,
    required String subjectCode,
  }) async {
    await _firestore.collection('classes').doc(classId).update({
      'courseSubjectId': subjectId,
      'courseSubjectName': subjectName,
      'courseSubjectCode': subjectCode,
    });
  }

  /// Gán đề thi vào học phần
  static Future<void> assignQuizToSubject({
    required String quizId,
    required String subjectId,
    required String subjectName,
    required String subjectCode,
  }) async {
    await _firestore.collection('quiz').doc(quizId).update({
      'courseSubjectId': subjectId,
      'courseSubjectName': subjectName,
      'courseSubjectCode': subjectCode,
    });
  }

  /// Gán ngân hàng vào học phần
  static Future<void> assignBankToSubject({
    required String bankId,
    required String subjectId,
    required String subjectName,
    required String subjectCode,
  }) async {
    await _firestore.collection('quiz_banks').doc(bankId).update({
      'courseSubjectId': subjectId,
      'courseSubjectName': subjectName,
      'courseSubjectCode': subjectCode,
    });
  }

  /// Lấy Stream đề thi theo Lớp học phần
  static Stream<QuerySnapshot> getQuizzesBySubjectStream(String? subjectId) {
    if (subjectId == null || subjectId.isEmpty) {
      // Lấy các bài thi chưa gán học phần
      return _firestore
          .collection('quiz')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _firestore
        .collection('quiz')
        .where('courseSubjectId', isEqualTo: subjectId)
        .snapshots();
  }

  /// Lấy Stream ngân hàng theo Lớp học phần
  static Stream<QuerySnapshot> getBanksBySubjectStream(String? subjectId) {
    if (subjectId == null || subjectId.isEmpty) {
      return _firestore
          .collection('quiz_banks')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _firestore
        .collection('quiz_banks')
        .where('courseSubjectId', isEqualTo: subjectId)
        .snapshots();
  }
}
