import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:xml/xml.dart';

class DocumentParserService {
  /// Trích xuất văn bản từ file Word (.docx)
  static Future<String> extractTextFromDocx(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) {
        throw Exception('Không tìm thấy nội dung văn bản (word/document.xml) trong file Word.');
      }

      final xmlContent = utf8.decode(documentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);

      final StringBuffer buffer = StringBuffer();
      // Lấy toàn bộ các đoạn văn <w:p>
      final paragraphs = document.findAllElements('w:p');

      for (final p in paragraphs) {
        // Lấy tất cả text run <w:t> trong đoạn
        final runs = p.findAllElements('w:t');
        final pText = runs.map((t) => t.innerText).join('');
        if (pText.trim().isNotEmpty) {
          buffer.writeln(pText.trim());
        }
      }

      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw Exception('File Word không có nội dung chữ hoặc văn bản rỗng.');
      }
      return result;
    } catch (e) {
      throw Exception('Lỗi khi đọc file Word (.docx): $e');
    }
  }

  /// Trích xuất văn bản từ file PDF bằng cách gom dòng vật lý (extractTextLines)
  static Future<String> extractTextFromPdf(List<int> bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final List<TextLine> lines = PdfTextExtractor(document).extractTextLines();
      String text;
      if (lines.isNotEmpty) {
        text = lines.map((l) => l.text).join('\n');
      } else {
        text = PdfTextExtractor(document).extractText();
      }
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Lỗi khi đọc PDF: $e');
    }
  }

  /// Chuẩn hóa nội dung văn bản trước khi phân tích
  static String standardizeQuizContent(String content) {
    // 1. Thêm xuống dòng trước các từ khóa "Câu X:", "Bài X:" để tách khối
    content = content.replaceAllMapped(
      RegExp(
        r'(?:^|\n)\s*(?:Câu|Bài|Question|Q)\s*(\d+)\s*[:.)]?\s*',
        caseSensitive: false,
      ),
      (match) => '\n@@BLOCK_START@@Câu ${match.group(1)}: ',
    );

    // 2. Chuẩn hóa các đáp án (A. B. C. D. ...) thành format "A. "
    content = content.replaceAllMapped(
      RegExp(r'(?:^|\n)\s*([A-Z])\s*[:.)]\s+', caseSensitive: false),
      (match) => '\n${match.group(1)!.toUpperCase()}. ',
    );

    // 3. Chuẩn hóa dòng đáp án
    content = content.replaceAllMapped(
      RegExp(
        r'(?:^|\n)\s*(?:Đáp\s*án|DA|Answer|Result|KQ|ĐA)\s*[:.]?\s*([A-Z0-9\s,]+)',
        caseSensitive: false,
      ),
      (match) => '\nĐáp án: ${match.group(1)!.toUpperCase()}',
    );

    return content;
  }

  /// Phân tích nội dung câu hỏi thành cấu trúc Map
  static Map<String, dynamic> parseQuestions(String content) {
    List<Map<String, dynamic>> questions = [];
    List<String> errors = [];

    try {
      // BƯỚC 1: Xử lý sơ bộ văn bản (Unicode, Newline)
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      content = unorm.nfc(content); // Chuẩn hóa tiếng Việt

      // BƯỚC 2: Chuẩn hóa format chung
      content = standardizeQuizContent(content);

      // Xóa các ký tự điều khiển lạ
      content = content.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

      // BƯỚC 3: Tách các câu hỏi dựa trên marker @@BLOCK_START@@
      final blocks = content.split('@@BLOCK_START@@');

      for (var block in blocks) {
        block = block.trim();
        if (block.isEmpty) continue;

        // 1. Tách nội dung câu hỏi (Từ đầu cho đến khi gặp đáp án A.)
        final questionMatch = RegExp(
          r'^(.*?)(\n[A-Z]\.\s+)',
          dotAll: true,
        ).firstMatch(block);

        if (questionMatch == null) {
          if (block.contains('Câu') && block.length < 50) {
            continue; // Bỏ qua header ngắn
          }
          errors.add(
            "Không tìm thấy các lựa chọn (A, B...) cho: \"${block.split('\n')[0]}\"",
          );
          continue;
        }

        String questionText = questionMatch.group(1)!.trim();
        questionText = questionText.replaceAll(
          RegExp(r'^Câu\s+\d+:\s*', caseSensitive: false),
          '',
        );
        questionText = questionText.replaceAll('\n', ' ').trim();

        // 2. Tìm tất cả các đáp án (A. ..., B. ...)
        List<String> options = [];
        List<String> optionKeys = [];

        final optionMatches = RegExp(
          r'\n([A-Z])\.\s+(.*?)(?=\n[A-Z]\.\s+|\nĐáp án:|$)',
          dotAll: true,
        ).allMatches(block);

        for (var match in optionMatches) {
          optionKeys.add(match.group(1)!);
          options.add(match.group(2)!.replaceAll('\n', ' ').trim());
        }

        if (options.length < 2) {
          final preview = questionText.length > 20 ? questionText.substring(0, 20) : questionText;
          errors.add(
            "Câu hỏi \"$preview...\" có ít hơn 2 đáp án.",
          );
          continue;
        }

        // 3. Tìm đáp án đúng
        final answerMatch = RegExp(
          r'\nĐáp án:\s*([A-Z\s,]+)',
        ).firstMatch(block);

        if (answerMatch == null) {
          final preview = questionText.length > 20 ? questionText.substring(0, 20) : questionText;
          errors.add(
            "Câu hỏi \"$preview...\" thiếu dòng 'Đáp án:'.",
          );
          continue;
        }

        String rawAnswer = answerMatch.group(1)!;
        List<String> correctAnswers = rawAnswer
            .split(RegExp(r'[,\s]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        bool isValidAnswer = true;
        for (var ans in correctAnswers) {
          if (!optionKeys.contains(ans)) {
            final preview = questionText.length > 20 ? questionText.substring(0, 20) : questionText;
            errors.add(
              "Câu hỏi \"$preview...\" có đáp án '$ans' không nằm trong các lựa chọn (${optionKeys.join(', ')}).",
            );
            isValidAnswer = false;
            break;
          }
        }
        if (!isValidAnswer) continue;

        // 4. Đóng gói kết quả
        questions.add({
          'question': questionText,
          'options': options,
          'correctAnswer': correctAnswers.length > 1
              ? correctAnswers
              : correctAnswers.first,
          'type': correctAnswers.length > 1 ? 'multiple' : 'single',
        });
      }
    } catch (e) {
      errors.add("Lỗi hệ thống khi phân tích file: $e");
    }

    return {'questions': questions, 'errors': errors, 'rawContent': content};
  }
}
