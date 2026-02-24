// lib/models/quiz_schedule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSchedule {
  final String id;
  final String quizId;
  final String classId;
  final DateTime? openTime;
  final DateTime? closeTime;
  final bool autoOpen;
  final bool autoClose;
  final String status; // 'scheduled', 'open', 'closed'
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  QuizSchedule({
    required this.id,
    required this.quizId,
    required this.classId,
    this.openTime,
    this.closeTime,
    this.autoOpen = false,
    this.autoClose = false,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory QuizSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizSchedule(
      id: doc.id,
      quizId: data['quizId'] ?? '',
      classId: data['classId'] ?? '',
      openTime: data['openTime'] != null
          ? (data['openTime'] as Timestamp).toDate()
          : null,
      closeTime: data['closeTime'] != null
          ? (data['closeTime'] as Timestamp).toDate()
          : null,
      autoOpen: data['autoOpen'] ?? false,
      autoClose: data['autoClose'] ?? false,
      status: data['status'] ?? 'scheduled',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'classId': classId,
      'openTime': openTime != null ? Timestamp.fromDate(openTime!) : null,
      'closeTime': closeTime != null ? Timestamp.fromDate(closeTime!) : null,
      'autoOpen': autoOpen,
      'autoClose': autoClose,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isOpen {
    final now = DateTime.now();
    if (openTime != null && now.isBefore(openTime!)) return false;
    if (closeTime != null && now.isAfter(closeTime!)) return false;
    return status == 'open';
  }

  bool get isClosed {
    final now = DateTime.now();
    if (closeTime != null && now.isAfter(closeTime!)) return true;
    return status == 'closed';
  }

  bool get isScheduled {
    return status == 'scheduled';
  }

  String get statusText {
    if (isClosed) return 'Đã đóng';
    if (isOpen) return 'Đang mở';
    return 'Đã lên lịch';
  }

  QuizSchedule copyWith({
    String? id,
    String? quizId,
    String? classId,
    DateTime? openTime,
    DateTime? closeTime,
    bool? autoOpen,
    bool? autoClose,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return QuizSchedule(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      classId: classId ?? this.classId,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      autoOpen: autoOpen ?? this.autoOpen,
      autoClose: autoClose ?? this.autoClose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
