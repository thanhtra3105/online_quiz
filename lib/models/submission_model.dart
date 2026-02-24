// lib/models/submission_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final String id;
  final String studentId;
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final Map<String, String> answers;
  final Timestamp? timestamp;
  final int timeSpent; // giây

  Submission({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.answers,
    this.timestamp,
    required this.timeSpent,
  });

  factory Submission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Submission(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      quizId: data['quizId'] ?? '',
      quizTitle: data['quizTitle'] ?? 'N/A',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      answers: Map<String, String>.from(data['answers'] ?? {}),
      timestamp: data['timestamp'] as Timestamp?,
      timeSpent: data['timeSpent'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'timeSpent': timeSpent,
    };
  }

  double get percentage => (score / totalQuestions * 100);
}