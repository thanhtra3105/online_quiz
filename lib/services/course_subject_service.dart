// lib/services/course_subject_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSubjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream danh sách các lớp học phần của giáo viên hoặc trợ giảng
  static Stream<List<QueryDocumentSnapshot>> getSubjectsStream(
    String userId, {
    String? studentId,
    String? email,
  }) {
    late StreamController<List<QueryDocumentSnapshot>> controller;
    final List<StreamSubscription> subs = [];
    final Map<int, List<QueryDocumentSnapshot>> streamResults = {};

    void emit() {
      if (controller.isClosed) return;
      final Map<String, QueryDocumentSnapshot> map = {};
      for (var list in streamResults.values) {
        for (var d in list) {
          map[d.id] = d;
        }
      }
      controller.add(map.values.toList());
    }

    controller = StreamController<List<QueryDocumentSnapshot>>(
      onListen: () {
        int index = 0;

        void addQuery(Query query) {
          final i = index++;
          subs.add(query.snapshots().listen((snap) {
            streamResults[i] = snap.docs;
            emit();
          }, onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          }));
        }

        // 1. Giảng viên tạo
        addQuery(_firestore.collection('course_subjects').where('teacherId', isEqualTo: userId));

        // 2. Trợ giảng theo userId
        addQuery(_firestore.collection('course_subjects').where('assistantIds', arrayContains: userId));

        // 3. Trợ giảng theo studentId (nếu khác userId)
        if (studentId != null && studentId.isNotEmpty && studentId != userId) {
          addQuery(_firestore.collection('course_subjects').where('assistantIds', arrayContains: studentId));
        }

        // 4. Trợ giảng theo email
        if (email != null && email.isNotEmpty) {
          addQuery(_firestore.collection('course_subjects').where('assistantEmails', arrayContains: email.toLowerCase().trim()));
        }
      },
      onCancel: () {
        for (var sub in subs) {
          sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  /// Lấy danh sách lớp học phần của giáo viên hoặc trợ giảng (Future)
  static Future<List<QueryDocumentSnapshot>> getSubjects(
    String userId, {
    String? studentId,
    String? email,
  }) async {
    final Map<String, QueryDocumentSnapshot> map = {};

    try {
      final snap1 = await _firestore.collection('course_subjects').where('teacherId', isEqualTo: userId).get();
      for (var d in snap1.docs) {
        map[d.id] = d;
      }
    } catch (_) {}

    try {
      final snap2 = await _firestore.collection('course_subjects').where('assistantIds', arrayContains: userId).get();
      for (var d in snap2.docs) {
        map[d.id] = d;
      }
    } catch (_) {}

    if (studentId != null && studentId.isNotEmpty && studentId != userId) {
      try {
        final snap3 = await _firestore.collection('course_subjects').where('assistantIds', arrayContains: studentId).get();
        for (var d in snap3.docs) {
          map[d.id] = d;
        }
      } catch (_) {}
    }

    if (email != null && email.isNotEmpty) {
      try {
        final snap4 = await _firestore.collection('course_subjects').where('assistantEmails', arrayContains: email.toLowerCase().trim()).get();
        for (var d in snap4.docs) {
          map[d.id] = d;
        }
      } catch (_) {}
    }

    return map.values.toList();
  }

  /// Lấy danh sách lớp học của giáo viên hoặc trợ giảng (Stream kết hợp real-time)
  static Stream<List<QueryDocumentSnapshot>> getClassesStream(
    String userId, {
    String? studentId,
    String? email,
    String? subjectId,
  }) {
    late StreamController<List<QueryDocumentSnapshot>> controller;
    final List<StreamSubscription> subs = [];
    final Map<int, List<QueryDocumentSnapshot>> streamResults = {};

    void emit() {
      if (controller.isClosed) return;
      final Map<String, QueryDocumentSnapshot> map = {};
      for (var list in streamResults.values) {
        for (var d in list) {
          map[d.id] = d;
        }
      }
      controller.add(map.values.toList());
    }

    controller = StreamController<List<QueryDocumentSnapshot>>(
      onListen: () {
        int index = 0;

        void addQuery(Query query) {
          final i = index++;
          subs.add(query.snapshots().listen((snap) {
            streamResults[i] = snap.docs;
            emit();
          }, onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          }));
        }

        // 1. Giáo viên tạo lớp
        addQuery(_firestore.collection('classes').where('teacherId', isEqualTo: userId));

        // 2. Trợ giảng theo userId
        addQuery(_firestore.collection('classes').where('assistantIds', arrayContains: userId));

        // 3. Trợ giảng theo studentId (nếu khác userId)
        if (studentId != null && studentId.isNotEmpty && studentId != userId) {
          addQuery(_firestore.collection('classes').where('assistantIds', arrayContains: studentId));
        }

        // 4. Trợ giảng theo email
        if (email != null && email.isNotEmpty) {
          addQuery(_firestore.collection('classes').where('assistantEmails', arrayContains: email.toLowerCase().trim()));
        }

        // 5. Nếu truyền subjectId trực tiếp
        if (subjectId != null && subjectId.isNotEmpty && subjectId != '_all' && subjectId != '_uncategorized') {
          addQuery(_firestore.collection('classes').where('courseSubjectId', isEqualTo: subjectId));
        }

        // 6. Lấy tất cả lớp thuộc các học phần mà user được giao (giảng viên hoặc trợ giảng)
        final Set<String> observedSubjects = {};
        if (subjectId != null && subjectId.isNotEmpty && subjectId != '_all' && subjectId != '_uncategorized') {
          observedSubjects.add(subjectId);
        }

        subs.add(getSubjectsStream(userId, studentId: studentId, email: email).listen((subjects) {
          for (var s in subjects) {
            final sId = s.id;
            if (!observedSubjects.contains(sId)) {
              observedSubjects.add(sId);
              final i = index++;
              subs.add(_firestore.collection('classes').where('courseSubjectId', isEqualTo: sId).snapshots().listen((snap) {
                streamResults[i] = snap.docs;
                emit();
              }, onError: (e) {
                if (!controller.isClosed) controller.addError(e);
              }));
            }
          }
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        }));
      },
      onCancel: () {
        for (var sub in subs) {
          sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  /// Thêm trợ giảng vào Lớp học phần
  static Future<void> addAssistantToSubject({
    required String subjectId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    final normalizedEmail = studentEmail.trim().toLowerCase();

    await _firestore
        .collection('course_subjects')
        .doc(subjectId)
        .collection('assistants')
        .doc(studentId)
        .set({
      'studentId': studentId,
      'name': studentName.trim(),
      'email': normalizedEmail,
      'role': 'assistant',
      'assignedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('course_subjects').doc(subjectId).update({
      'assistantIds': FieldValue.arrayUnion([studentId]),
      if (normalizedEmail.isNotEmpty)
        'assistantEmails': FieldValue.arrayUnion([normalizedEmail]),
      'managerIds': FieldValue.arrayUnion([studentId]),
    });

    // Đồng bộ trợ giảng vào tất cả các lớp học thuộc học phần này
    try {
      final classDocs = await _firestore
          .collection('classes')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var cd in classDocs.docs) {
        await cd.reference.update({
          'assistantIds': FieldValue.arrayUnion([studentId]),
          if (normalizedEmail.isNotEmpty)
            'assistantEmails': FieldValue.arrayUnion([normalizedEmail]),
        });
        await cd.reference.collection('assistants').doc(studentId).set({
          'studentId': studentId,
          'name': studentName.trim(),
          'email': normalizedEmail,
          'role': 'assistant',
          'assignedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Gỡ trợ giảng khỏi Lớp học phần
  static Future<void> removeAssistantFromSubject({
    required String subjectId,
    required String studentId,
    String? studentEmail,
  }) async {
    final normalizedEmail = (studentEmail ?? '').trim().toLowerCase();

    await _firestore
        .collection('course_subjects')
        .doc(subjectId)
        .collection('assistants')
        .doc(studentId)
        .delete();

    final updateData = <String, dynamic>{
      'assistantIds': FieldValue.arrayRemove([studentId]),
      'managerIds': FieldValue.arrayRemove([studentId]),
    };
    if (normalizedEmail.isNotEmpty) {
      updateData['assistantEmails'] = FieldValue.arrayRemove([normalizedEmail]);
    }
    await _firestore.collection('course_subjects').doc(subjectId).update(updateData);

    // Đồng bộ gỡ trợ giảng khỏi tất cả các lớp học thuộc học phần này
    try {
      final classDocs = await _firestore
          .collection('classes')
          .where('courseSubjectId', isEqualTo: subjectId)
          .get();
      for (var cd in classDocs.docs) {
        final updateMap = <String, dynamic>{
          'assistantIds': FieldValue.arrayRemove([studentId]),
        };
        if (normalizedEmail.isNotEmpty) {
          updateMap['assistantEmails'] = FieldValue.arrayRemove([normalizedEmail]);
        }
        await cd.reference.update(updateMap);
        await cd.reference.collection('assistants').doc(studentId).delete();
      }
    } catch (_) {}
  }

  /// Lấy danh sách trợ giảng của học phần (Stream)
  static Stream<QuerySnapshot> getSubjectAssistantsStream(String subjectId) {
    return _firestore
        .collection('course_subjects')
        .doc(subjectId)
        .collection('assistants')
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }

  /// Tạo một lớp học phần mới
  static Future<DocumentReference> createSubject({
    required String teacherId,
    required String name,
    required String code,
    String? description,
    String? colorHex,
  }) async {
    return await _firestore.collection('course_subjects').add({
      'teacherId': teacherId,
      'assistantIds': <String>[],
      'assistantEmails': <String>[],
      'managerIds': [teacherId],
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
