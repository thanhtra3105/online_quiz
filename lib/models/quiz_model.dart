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
  final String? imageUrl;
  final List<String> imageUrls;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
    this.imageUrls = const [],
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    List<String> images = [];
    if (data['imageUrls'] is List) {
      images = (data['imageUrls'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (data['imageUrl'] != null && data['imageUrl'].toString().trim().isNotEmpty) {
      images = [data['imageUrl'].toString().trim()];
    }

    return Question(
      id: doc.id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? 'A',
      imageUrl: images.isNotEmpty ? images.first : null,
      imageUrls: images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}