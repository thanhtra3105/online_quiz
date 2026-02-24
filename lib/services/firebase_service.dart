// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ ERROR HANDLING ============

  /// Handle Firebase errors and print useful debug information
  static void _handleFirebaseError(dynamic error, String operation) {
    // Force print to console
    final errorString = error.toString();

    // Always log with developer.log
    developer.log(
      'Firebase Error in $operation',
      error: error,
      name: 'FirebaseService',
    );

    // Check for missing index error
    if (errorString.contains('index') ||
        errorString.contains('FAILED_PRECONDITION') ||
        errorString.contains('requires an index')) {

      // Print multiple times to ensure visibility
      debugPrint('\n' + '=' * 60);
      debugPrint('🔥 FIREBASE INDEX ERROR 🔥');
      debugPrint('=' * 60);
      debugPrint('Operation: $operation');
      debugPrint('Error: $errorString');
      debugPrint('');

      print('\n' + '=' * 60);
      print('🔥 FIREBASE INDEX ERROR 🔥');
      print('=' * 60);
      print('Operation: $operation');
      print('Error: $errorString');
      print('');

      // Extract index URL if present
      final urlPattern = RegExp(r'https://console\.firebase\.google\.com[^\s\)]+');
      final match = urlPattern.firstMatch(errorString);

      if (match != null) {
        final indexUrl = match.group(0);

        debugPrint('📋 CLICK THIS LINK TO CREATE THE REQUIRED INDEX:');
        debugPrint('👉 $indexUrl');
        debugPrint('');
        debugPrint('Or copy and paste this URL into your browser:');
        debugPrint(indexUrl);

        print('📋 CLICK THIS LINK TO CREATE THE REQUIRED INDEX:');
        print('👉 $indexUrl');
        print('');
        print('Or copy and paste this URL into your browser:');
        print(indexUrl);
      } else {
        debugPrint('📋 To fix this error:');
        debugPrint('1. Go to Firebase Console');
        debugPrint('2. Select your project');
        debugPrint('3. Go to Firestore Database > Indexes');
        debugPrint('4. Create the required composite index');

        print('📋 To fix this error:');
        print('1. Go to Firebase Console');
        print('2. Select your project');
        print('3. Go to Firestore Database > Indexes');
        print('4. Create the required composite index');
      }

      debugPrint('=' * 60 + '\n');
      print('=' * 60 + '\n');
    } else if (errorString.contains('permission-denied') ||
        errorString.contains('PERMISSION_DENIED')) {
      print('\n' + '=' * 60);
      print('🔒 FIREBASE PERMISSION ERROR 🔒');
      print('=' * 60);
      print('Operation: $operation');
      print('Error: $errorString');
      print('');
      print('📋 TO FIX THIS:');
      print('1. Go to Firebase Console');
      print('2. Select your project');
      print('3. Go to Firestore Database > Rules');
      print('4. Check and update your Security Rules');
      print('');
      print('Current operation needs permission for: $operation');
      print('=' * 60 + '\n');
    } else if (errorString.contains('not-found') ||
        errorString.contains('NOT_FOUND')) {
      print('\n' + '=' * 60);
      print('🔍 FIREBASE NOT FOUND ERROR 🔍');
      print('=' * 60);
      print('Operation: $operation');
      print('Error: Document or collection not found');
      print('Details: $errorString');
      print('=' * 60 + '\n');
    } else if (errorString.contains('already-exists') ||
        errorString.contains('ALREADY_EXISTS')) {
      print('\n' + '=' * 60);
      print('⚠️ FIREBASE DUPLICATE ERROR ⚠️');
      print('=' * 60);
      print('Operation: $operation');
      print('Error: Document already exists');
      print('Details: $errorString');
      print('=' * 60 + '\n');
    } else {
      print('\n' + '=' * 60);
      print('❌ FIREBASE ERROR ❌');
      print('=' * 60);
      print('Operation: $operation');
      print('Error Type: ${error.runtimeType}');
      print('Error Message: $errorString');
      print('=' * 60 + '\n');
    }
  }

  // ============ CLASS OPERATIONS ============

  /// Get classes where student is enrolled (using subcollection approach)
  static Stream<List<Map<String, dynamic>>> getStudentClasses(String studentId) async* {
    try {
      print('📚 Fetching classes for student: $studentId');

      final studentDocsStream = _firestore
          .collectionGroup('students')
          .where('studentId', isEqualTo: studentId)
          .snapshots();

      await for (var snapshot in studentDocsStream) {
        List<Map<String, dynamic>> classes = [];

        for (var studentDoc in snapshot.docs) {
          try {
            final classRef = studentDoc.reference.parent.parent;
            if (classRef != null) {
              final classDoc = await classRef.get();
              if (classDoc.exists) {
                classes.add({
                  'id': classDoc.id,
                  ...classDoc.data() as Map<String, dynamic>,
                });
              }
            }
          } catch (e) {
            _handleFirebaseError(e, 'getStudentClasses - fetching class document');
          }
        }

        yield classes;
      }
    } catch (e) {
      _handleFirebaseError(e, 'getStudentClasses');
      yield [];
    }
  }

  /// Get class information by ID
  static Future<DocumentSnapshot> getClassById(String classId) async {
    try {
      print('📖 Fetching class by ID: $classId');
      return await _firestore.collection('classes').doc(classId).get();
    } catch (e) {
      _handleFirebaseError(e, 'getClassById');
      rethrow;
    }
  }

  /// Get all classes for a teacher
  static Stream<QuerySnapshot> getTeacherClasses(String teacherId) {
    try {
      print('👨‍🏫 Fetching classes for teacher: $teacherId');
      return _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getTeacherClasses');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getTeacherClasses');
      rethrow;
    }
  }

  /// Create a new class
  static Future<DocumentReference> createClass({
    required String teacherId,
    required String name,
    String? description,
  }) async {
    try {
      print('➕ Creating new class: $name');
      return await _firestore.collection('classes').add({
        'teacherId': teacherId,
        'name': name,
        'description': description ?? '',
        'studentCount': 0,
        'quizCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirebaseError(e, 'createClass');
      rethrow;
    }
  }

  /// Update class information
  static Future<void> updateClass(String classId, Map<String, dynamic> data) async {
    try {
      print('✏️ Updating class: $classId');
      await _firestore.collection('classes').doc(classId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirebaseError(e, 'updateClass');
      rethrow;
    }
  }

  /// Delete a class
  static Future<void> deleteClass(String classId) async {
    try {
      print('🗑️ Deleting class: $classId');

      // Delete students subcollection
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      for (var doc in studentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete quizzes subcollection
      final quizzesSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .get();

      for (var doc in quizzesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete class document
      await _firestore.collection('classes').doc(classId).delete();
      print('✅ Class deleted successfully');
    } catch (e) {
      _handleFirebaseError(e, 'deleteClass');
      rethrow;
    }
  }

  // ============ STUDENT OPERATIONS ============

  /// Add student to a class
  static Future<void> addStudentToClass({
    required String classId,
    required String studentId,
    required String name,
  }) async {
    try {
      print('👤 Adding student to class: $name');

      // Check if student already exists
      final existingStudent = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        throw Exception('Student already exists in this class');
      }

      // Add student
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .add({
        'studentId': studentId,
        'name': name,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Update student count
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final currentCount = (classDoc.data()?['studentCount'] ?? 0) as int;

      await _firestore.collection('classes').doc(classId).update({
        'studentCount': currentCount + 1,
      });

      print('✅ Student added successfully');
    } catch (e) {
      _handleFirebaseError(e, 'addStudentToClass');
      rethrow;
    }
  }

  /// Update student information
  static Future<void> updateStudent({
    required String classId,
    required String studentDocId,
    required String name,
  }) async {
    try {
      print('✏️ Updating student: $name');
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentDocId)
          .update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirebaseError(e, 'updateStudent');
      rethrow;
    }
  }

  /// Remove student from class
  static Future<void> removeStudentFromClass({
    required String classId,
    required String studentDocId,
  }) async {
    try {
      print('🗑️ Removing student from class');
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentDocId)
          .delete();

      // Update student count
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final currentCount = (classDoc.data()?['studentCount'] ?? 1) as int;

      await _firestore.collection('classes').doc(classId).update({
        'studentCount': currentCount > 0 ? currentCount - 1 : 0,
      });

      print('✅ Student removed successfully');
    } catch (e) {
      _handleFirebaseError(e, 'removeStudentFromClass');
      rethrow;
    }
  }

  /// Get students in a class
  static Stream<QuerySnapshot> getClassStudents(String classId) {
    try {
      print('👥 Fetching students for class: $classId');
      return _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .orderBy('name')
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getClassStudents');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getClassStudents');
      rethrow;
    }
  }

  // ============ QUIZ OPERATIONS ============

  /// Get available quizzes (all quizzes with available status)
  static Stream<QuerySnapshot> getAvailableQuizzes() {
    try {
      print('📝 Fetching available quizzes');
      return _firestore
          .collection('quiz')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getAvailableQuizzes');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getAvailableQuizzes');
      rethrow;
    }
  }

  /// Get all quizzes (for teacher management)
  static Stream<QuerySnapshot> getAllQuizzes() {
    try {
      print('📚 Fetching all quizzes');
      return _firestore
          .collection('quiz')
          .orderBy('title')
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getAllQuizzes');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getAllQuizzes');
      rethrow;
    }
  }

  /// Create a new quiz
  static Future<DocumentReference> createQuiz({
    required String title,
    required int questionCount,
    required int duration,
    String status = 'available',
  }) async {
    try {
      print('➕ Creating new quiz: $title');
      return await _firestore.collection('quiz').add({
        'title': title,
        'questionCount': questionCount,
        'duration': duration,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirebaseError(e, 'createQuiz');
      rethrow;
    }
  }

  /// Update quiz information
  static Future<void> updateQuiz(String quizId, Map<String, dynamic> data) async {
    try {
      print('✏️ Updating quiz: $quizId');
      await _firestore.collection('quiz').doc(quizId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleFirebaseError(e, 'updateQuiz');
      rethrow;
    }
  }

  /// Delete a quiz and all its questions
  static Future<void> deleteQuiz(String quizId) async {
    try {
      print('🗑️ Deleting quiz: $quizId');

      // Delete all questions first
      final questionsSnapshot = await _firestore
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete quiz document
      await _firestore.collection('quiz').doc(quizId).delete();
      print('✅ Quiz deleted successfully');
    } catch (e) {
      _handleFirebaseError(e, 'deleteQuiz');
      rethrow;
    }
  }

  /// Add question to quiz
  static Future<DocumentReference> addQuestionToQuiz({
    required String quizId,
    required String question,
    required List<String> options,
    required String correctAnswer,
    int? order,
  }) async {
    try {
      print('➕ Adding question to quiz: $quizId');
      return await _firestore
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .add({
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        if (order != null) 'order': order,
      });
    } catch (e) {
      _handleFirebaseError(e, 'addQuestionToQuiz');
      rethrow;
    }
  }

  /// Delete all questions from a quiz
  static Future<void> deleteAllQuestionsFromQuiz(String quizId) async {
    try {
      print('🗑️ Deleting all questions from quiz: $quizId');
      final questionsSnapshot = await _firestore
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();

      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ All questions deleted');
    } catch (e) {
      _handleFirebaseError(e, 'deleteAllQuestionsFromQuiz');
      rethrow;
    }
  }

  /// Get quizzes assigned to a class (from class subcollection)
  static Stream<QuerySnapshot> getClassQuizzes(String classId) {
    try {
      print('📝 Fetching quizzes for class: $classId');
      return _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getClassQuizzes');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getClassQuizzes');
      rethrow;
    }
  }

  /// Get full quiz details for quizzes in a class
  static Future<List<Map<String, dynamic>>> getClassQuizzesWithDetails(
      String classId,
      ) async {
    try {
      print('📚 Fetching quiz details for class: $classId');
      final classQuizzesSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .get();

      List<Map<String, dynamic>> quizzes = [];

      for (var quizDoc in classQuizzesSnapshot.docs) {
        try {
          final quizSnapshot = await _firestore
              .collection('quiz')
              .doc(quizDoc.id)
              .get();

          if (quizSnapshot.exists) {
            quizzes.add({
              'id': quizSnapshot.id,
              ...quizSnapshot.data() as Map<String, dynamic>,
            });
          }
        } catch (e) {
          _handleFirebaseError(e, 'getClassQuizzesWithDetails - fetching quiz ${quizDoc.id}');
        }
      }

      return quizzes;
    } catch (e) {
      _handleFirebaseError(e, 'getClassQuizzesWithDetails');
      return [];
    }
  }

  /// Assign quiz to a class
  static Future<void> assignQuizToClass({
    required String classId,
    required String quizId,
  }) async {
    try {
      print('📌 Assigning quiz to class');
      final quizDoc = await _firestore.collection('quiz').doc(quizId).get();

      if (!quizDoc.exists) {
        throw Exception('Quiz not found');
      }

      final quizData = quizDoc.data() as Map<String, dynamic>;

      // Check if quiz already assigned
      final existingQuiz = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (existingQuiz.exists) {
        throw Exception('Quiz already assigned to this class');
      }

      // Add quiz reference to class subcollection with metadata
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(quizId)
          .set({
        'title': quizData['title'],
        'questionCount': quizData['questionCount'],
        'duration': quizData['duration'],
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // Update quiz count in class
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 0) as int;

      await _firestore.collection('classes').doc(classId).update({
        'quizCount': currentCount + 1,
      });

      print('✅ Quiz assigned successfully');
    } catch (e) {
      _handleFirebaseError(e, 'assignQuizToClass');
      rethrow;
    }
  }

  /// Remove quiz from class
  static Future<void> removeQuizFromClass({
    required String classId,
    required String quizId,
  }) async {
    try {
      print('🗑️ Removing quiz from class');
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(quizId)
          .delete();

      // Update quiz count
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final currentCount = (classDoc.data()?['quizCount'] ?? 1) as int;

      await _firestore.collection('classes').doc(classId).update({
        'quizCount': currentCount > 0 ? currentCount - 1 : 0,
      });

      print('✅ Quiz removed successfully');
    } catch (e) {
      _handleFirebaseError(e, 'removeQuizFromClass');
      rethrow;
    }
  }

  /// Get quiz by ID from main quiz collection
  static Future<DocumentSnapshot> getQuizById(String quizId) async {
    try {
      print('📖 Fetching quiz by ID: $quizId');
      return await _firestore.collection('quiz').doc(quizId).get();
    } catch (e) {
      _handleFirebaseError(e, 'getQuizById');
      rethrow;
    }
  }

  /// Get questions for a quiz from quiz subcollection
  static Stream<QuerySnapshot> getQuizQuestions(String quizId) {
    try {
      print('❓ Fetching questions for quiz: $quizId');
      return _firestore
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getQuizQuestions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getQuizQuestions');
      rethrow;
    }
  }

  /// Get quiz questions once (for submission)
  static Future<QuerySnapshot> getQuizQuestionsOnce(String quizId) async {
    try {
      print('❓ Fetching questions once for quiz: $quizId');
      return await _firestore
          .collection('quiz')
          .doc(quizId)
          .collection('questions')
          .get();
    } catch (e) {
      _handleFirebaseError(e, 'getQuizQuestionsOnce');
      rethrow;
    }
  }

  // ============ SUBMISSION OPERATIONS ============

  /// Submit quiz answers
  static Future<void> submitQuiz({
    required String studentId,
    required String quizId,
    required String classId,
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required Map<String, String> answers,
    required int timeSpent,
  }) async {
    try {
      print('📤 Submitting quiz: $quizTitle');
      await _firestore.collection('submissions').add({
        'studentId': studentId,
        'quizId': quizId,
        'classId': classId,
        'quizTitle': quizTitle,
        'score': score,
        'totalQuestions': totalQuestions,
        'answers': answers,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': timeSpent,
      });
      print('✅ Quiz submitted successfully');
    } catch (e) {
      _handleFirebaseError(e, 'submitQuiz');
      rethrow;
    }
  }

  /// Get student submissions for all classes
  static Stream<QuerySnapshot> getStudentSubmissions(String studentId) {
    try {
      print('📊 Fetching submissions for student: $studentId');
      return _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getStudentSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getStudentSubmissions');
      rethrow;
    }
  }

  /// Get student submissions for a specific class
  static Stream<QuerySnapshot> getStudentClassSubmissions(
      String studentId,
      String classId,
      ) {
    try {
      print('📊 Fetching class submissions for student: $studentId');
      return _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getStudentClassSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getStudentClassSubmissions');
      rethrow;
    }
  }

  /// Get recent submissions
  static Stream<QuerySnapshot> getRecentSubmissions(
      String studentId, {
        int limit = 5,
      }) {
    try {
      print('📊 Fetching recent submissions (limit: $limit)');
      return _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getRecentSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getRecentSubmissions');
      rethrow;
    }
  }

  /// Get recent submissions for a specific class
  static Stream<QuerySnapshot> getRecentClassSubmissions(
      String studentId,
      String classId, {
        int limit = 5,
      }) {
    try {
      print('📊 Fetching recent class submissions (limit: $limit)');
      return _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getRecentClassSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getRecentClassSubmissions');
      rethrow;
    }
  }

  /// Get submission by ID
  static Future<DocumentSnapshot> getSubmissionById(String submissionId) async {
    try {
      print('📖 Fetching submission by ID: $submissionId');
      return await _firestore.collection('submissions').doc(submissionId).get();
    } catch (e) {
      _handleFirebaseError(e, 'getSubmissionById');
      rethrow;
    }
  }

  /// Get all submissions (for teacher view)
  static Stream<QuerySnapshot> getAllSubmissions() {
    try {
      print('📊 Fetching all submissions');
      return _firestore
          .collection('submissions')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getAllSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getAllSubmissions');
      rethrow;
    }
  }

  /// Get submissions for a specific quiz
  static Stream<QuerySnapshot> getQuizSubmissions(String quizId) {
    try {
      print('📊 Fetching submissions for quiz: $quizId');
      return _firestore
          .collection('submissions')
          .where('quizId', isEqualTo: quizId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getQuizSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getQuizSubmissions');
      rethrow;
    }
  }

  /// Get submissions for a specific class (teacher view)
  static Stream<QuerySnapshot> getClassSubmissions(String classId) {
    try {
      print('📊 Fetching submissions for class: $classId');
      return _firestore
          .collection('submissions')
          .where('classId', isEqualTo: classId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
        _handleFirebaseError(error, 'getClassSubmissions');
      });
    } catch (e) {
      _handleFirebaseError(e, 'getClassSubmissions');
      rethrow;
    }
  }

  /// Check if student has completed a quiz
  static Future<bool> hasCompletedQuiz(String studentId, String quizId) async {
    try {
      final result = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('quizId', isEqualTo: quizId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      _handleFirebaseError(e, 'hasCompletedQuiz');
      return false;
    }
  }

  /// Check if student has completed a quiz in a specific class
  static Future<bool> hasCompletedQuizInClass(
      String studentId,
      String quizId,
      String classId,
      ) async {
    try {
      final result = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('quizId', isEqualTo: quizId)
          .where('classId', isEqualTo: classId)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      _handleFirebaseError(e, 'hasCompletedQuizInClass');
      return false;
    }
  }

  /// Get completed quiz IDs for a student
  static Future<Set<String>> getCompletedQuizIds(String studentId) async {
    try {
      print('✅ Fetching completed quiz IDs for student: $studentId');
      final snapshot = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .get();

      return snapshot.docs
          .map((doc) => (doc.data()['quizId'] as String))
          .toSet();
    } catch (e) {
      _handleFirebaseError(e, 'getCompletedQuizIds');
      return {};
    }
  }

  /// Get completed quiz IDs for a student in a specific class
  static Future<Set<String>> getCompletedQuizIdsInClass(
      String studentId,
      String classId,
      ) async {
    try {
      print('✅ Fetching completed quiz IDs for student in class: $classId');
      final snapshot = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .get();

      return snapshot.docs
          .map((doc) => (doc.data()['quizId'] as String))
          .toSet();
    } catch (e) {
      _handleFirebaseError(e, 'getCompletedQuizIdsInClass');
      return {};
    }
  }

  // ============ STATISTICS OPERATIONS ============

  /// Get class statistics
  static Future<Map<String, dynamic>> getClassStatistics(String classId) async {
    try {
      print('📈 Calculating statistics for class: $classId');
      final classDoc = await getClassById(classId);
      final classData = classDoc.data() as Map<String, dynamic>?;

      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      final quizzesSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .get();

      final submissionsSnapshot = await _firestore
          .collection('submissions')
          .where('classId', isEqualTo: classId)
          .get();

      return {
        'className': classData?['name'] ?? 'Unknown',
        'studentCount': studentsSnapshot.docs.length,
        'quizCount': quizzesSnapshot.docs.length,
        'totalSubmissions': submissionsSnapshot.docs.length,
        'averageScore': _calculateAverageScore(submissionsSnapshot.docs),
      };
    } catch (e) {
      _handleFirebaseError(e, 'getClassStatistics');
      rethrow;
    }
  }

  /// Calculate average score from submissions
  static double _calculateAverageScore(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;

    double totalPercentage = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final score = (data['score'] ?? 0) as int;
      final total = (data['totalQuestions'] ?? 1) as int;
      totalPercentage += (score / total) * 100;
    }

    return totalPercentage / docs.length;
  }

  /// Get student statistics in a class
  static Future<Map<String, dynamic>> getStudentClassStatistics(
      String studentId,
      String classId,
      ) async {
    try {
      print('📈 Calculating student statistics for class: $classId');
      final submissionsSnapshot = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .get();

      final quizzesSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .get();

      int totalScore = 0;
      int totalQuestions = 0;

      for (var doc in submissionsSnapshot.docs) {
        final data = doc.data();
        totalScore += (data['score'] ?? 0) as int;
        totalQuestions += (data['totalQuestions'] ?? 0) as int;
      }

      final averagePercentage = totalQuestions > 0
          ? (totalScore / totalQuestions) * 100
          : 0.0;

      return {
        'completedQuizzes': submissionsSnapshot.docs.length,
        'totalQuizzes': quizzesSnapshot.docs.length,
        'averageScore': averagePercentage,
        'totalScore': totalScore,
        'totalQuestions': totalQuestions,
      };
    } catch (e) {
      _handleFirebaseError(e, 'getStudentClassStatistics');
      rethrow;
    }
  }
}