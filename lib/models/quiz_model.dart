// lib/models/quiz_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String title;
  final int questionCount;
  final int duration; // phút
  final String status; // 'available', 'archived'
  final Timestamp? createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.duration,
    required this.status,
    this.createdAt,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] ?? 'Untitled Quiz',
      questionCount: data['questionCount'] ?? 0,
      duration: data['duration'] ?? 30,
      status: data['status'] ?? 'available',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'questionCount': questionCount,
      'duration': duration,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class Question {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer; // A, B, C, D

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? 'A',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}