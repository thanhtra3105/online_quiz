// lib/screens/teacher/edit_quiz_bank_page.dart
import 'package:flutter/material.dart';
import 'edit_quiz_page.dart';

/// Chỉnh sửa ngân hàng câu hỏi sử dụng chung module [EditQuizPage]
/// với cấu hình [isQuestionBank: true] để đảm bảo đồng bộ 100% giao diện và logic.
class EditQuizBankPage extends StatelessWidget {
  final String bankId;
  final String bankTitle;

  const EditQuizBankPage({
    super.key,
    required this.bankId,
    required this.bankTitle,
  });

  @override
  Widget build(BuildContext context) {
    return EditQuizPage(
      quizId: bankId,
      quizData: {
        'title': bankTitle,
      },
      isQuestionBank: true,
    );
  }
}
