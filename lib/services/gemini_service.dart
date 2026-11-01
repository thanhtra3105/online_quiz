import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  // 👉 Bạn có thể dán API Key trực tiếp vào đây:
  static String defaultApiKey = 'AQ.Ab8RN6IgikktDRurauIyFB5zATBUVed1oqoDKrnTOMY_4CH9YA';

  static const String _prefKey = 'gemini_api_key';

  /// Lấy API Key đang lưu (từ bộ nhớ máy hoặc mặc định trong code)
  static Future<String> getApiKey() async {
    if (defaultApiKey.trim().isNotEmpty) {
      return defaultApiKey.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '';
  }

  /// Lưu API Key mới vào máy
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
  }

  /// Trích xuất số lượng câu hỏi nếu người dùng gõ trong câu chat (ví dụ: "với 9 câu hỏi")
  static int? extractQuestionCount(String text) {
    final match = RegExp(r'(?:khoảng\s*)?(\d+)\s*(?:câu(?:\s*hỏi)?|cau(?:\s*hoi)?|questions?)', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final parsed = int.tryParse(match.group(1)!);
      if (parsed != null && parsed > 0 && parsed <= 100) {
        return parsed;
      }
    }
    return null;
  }

  /// 1. Tạo đề thi trắc nghiệm bằng Gemini AI theo yêu cầu/chủ đề
  static Future<List<Map<String, dynamic>>> generateQuiz({
    required String topic,
    int? questionCount,
    String difficulty = 'Trung bình',
    String questionType = 'Tổng hợp (1 đáp án & Nhiều đáp án)',
  }) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Chưa cấu hình Gemini API Key. Vui lòng nhập API Key để tiếp tục.');
    }

    // Tự động nhận diện số câu hỏi nếu người dùng nhập trong văn bản chat (ví dụ "với 9 câu hỏi")
    final extractedCount = extractQuestionCount(topic);
    final finalCount = questionCount ?? extractedCount ?? 5;

    final prompt = '''
Bạn là chuyên gia giáo dục và biên soạn đề thi trắc nghiệm học thuật chuyên sâu.
Hãy phân tích kỹ kiến thức chuyên môn và tạo đúng $finalCount câu hỏi trắc nghiệm chất lượng cao theo yêu cầu chi tiết sau:
"$topic"

Các thông số tham khảo thêm:
- Mức độ khó: $difficulty
- Dạng câu hỏi ưu tiên: $questionType

TIÊU CHUẨN ĐỀ THI CHẤT LƯỢNG CAO:
1. Phân tích ngữ cảnh sâu sắc: Tránh các câu hỏi quá đơn giản, ngô nghê hoặc định nghĩa suông. Hãy đưa ra các tình huống thực tế, bài toán thực hành, hoặc đoạn mã nguồn (code snippet nếu là môn lập trình).
2. Tính phân loại cao: Các phương án gây nhiễu (distractor options) phải hợp lý, đánh trúng vào các quan niệm sai lầm phổ biến mà người học hay mắc phải.
3. Đáp án chính xác tuyệt đối, khoa học và không gây tranh cãi.

QUY ĐỊNH BẮT BUỘC:
Trả về định dạng JSON Array chứa đúng $finalCount câu hỏi. Không xuất thêm bất kỳ văn bản nào ngoài JSON.
Mỗi câu hỏi có cấu trúc:
{
  "question": "Nội dung câu hỏi (không viết tiền tố 'Câu 1:')",
  "options": ["Nội dung phương án A", "Nội dung phương án B", "Nội dung phương án C", "Nội dung phương án D"],
  "correctAnswer": "A",
  "type": "single"
}
Quy tắc:
- Với câu hỏi 1 đáp án: "correctAnswer" là 1 ký tự ("A", "B", "C" hoặc "D"), "type" là "single".
- Với câu hỏi nhiều đáp án đúng: "correctAnswer" là mảng các ký tự, ví dụ ["A", "C"], "type" là "multiple", và thêm "(Chọn nhiều đáp án)" vào cuối câu hỏi.
- Với câu hỏi Đúng/Sai: options gồm 2 phương án ["Đúng", "Sai"], "correctAnswer" là "A" hoặc "B", "type" là "single".
- Các phương án trong options TUYỆT ĐỐI KHÔNG chứa tiền tố "A.", "B.", "C." hay "D.".
''';

    final responseText = await _callGeminiApi(apiKey, prompt, isJson: true);
    return _parseJsonQuestions(responseText);
  }

  /// 2. Dùng Gemini AI để tự động sửa lỗi định dạng văn bản đề thi bị lỗi
  static Future<String> fixUnformattedContent(String brokenText) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Chưa cấu hình Gemini API Key. Vui lòng nhập API Key để dùng tính năng AI.');
    }

    final prompt = '''
Bạn là trợ lý chuẩn hóa định dạng đề thi trắc nghiệm.
Dưới đây là một đoạn văn bản đề thi trắc nghiệm được trích xuất từ file nhưng bị lỗi định dạng, ngắt dòng sai hoặc thiếu cấu trúc chuẩn:

"""
$brokenText
"""

HÃY ĐỌC VÀ CHUẨN HÓA LẠI TOÀN BỘ ĐỀ THI TRÊN THEO ĐÚNG ĐỊNH DẠNG CHUẨN SAU:
- Mỗi câu bắt đầu bằng "Câu X: [Nội dung câu hỏi]"
- Các phương án lần lượt là:
A. [Đáp án A]
B. [Đáp án B]
C. [Đáp án C]
D. [Đáp án D]
- Dòng đáp án đúng bắt đầu bằng: "Đáp án: [Chữ cái đáp án đúng]" (Ví dụ: "Đáp án: A" hoặc nhiều đáp án "Đáp án: A, C")
- Giữa các câu hỏi cách nhau bởi một dòng trống.
- KHÔNG thêm bất kỳ lời chào, ghi chú hay định dạng markdown khác ngoài nội dung các câu hỏi.
''';

    final fixedText = await _callGeminiApi(apiKey, prompt, isJson: false);
    return fixedText.trim();
  }

  /// Hàm gọi REST API tới Google Gemini với ưu tiên mô hình phân tích sâu Gemini 3.8 Flash
  static Future<String> _callGeminiApi(String apiKey, String prompt, {bool isJson = false}) async {
    // Ưu tiên mô hình phân tích chuyên sâu Gemini 3.8 Flash & 3.5 Flash
    final models = [
      'gemini-3.8-flash',
      'gemini-3.5-flash',
      'gemini-flash-latest',
      'gemini-3.5-flash-lite',
    ];
    
    Exception? lastError;
    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final Map<String, dynamic> genConfig = {
          'temperature': 0.2,
        };
        if (isJson) {
          genConfig['responseMimeType'] = 'application/json';
        }

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': genConfig,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? '';
            }
          }
          throw Exception('Không nhận được nội dung phản hồi từ Gemini.');
        } else {
          final errBody = utf8.decode(response.bodyBytes);
          lastError = Exception('Lỗi Gemini ($model - mã ${response.statusCode}): $errBody');
        }
      } catch (e) {
        lastError = Exception('Lỗi kết nối Gemini ($model): $e');
      }
    }

    throw lastError ?? Exception('Không thể kết nối đến máy chủ Google Gemini.');
  }

  /// Trích xuất danh sách câu hỏi từ chuỗi phản hồi JSON của Gemini
  static List<Map<String, dynamic>> _parseJsonQuestions(String rawResponse) {
    String cleanJson = rawResponse.trim();
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    } else if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

    // Tìm mảng JSON [...]
    final startIndex = cleanJson.indexOf('[');
    final endIndex = cleanJson.lastIndexOf(']');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      cleanJson = cleanJson.substring(startIndex, endIndex + 1);
    }

    final dynamic parsed = jsonDecode(cleanJson);
    if (parsed is! List) {
      throw Exception('Dữ liệu AI trả về không phải là danh sách câu hỏi hợp lệ.');
    }

    List<Map<String, dynamic>> questions = [];
    for (var item in parsed) {
      if (item is Map) {
        final qText = item['question']?.toString().trim() ?? '';
        final rawOpts = item['options'];
        List<String> options = [];
        if (rawOpts is List) {
          options = rawOpts.map((o) => o.toString().trim()).toList();
        }

        dynamic correctAns = item['correctAnswer'];
        if (correctAns is List) {
          correctAns = correctAns.map((c) => c.toString().trim().toUpperCase()).toList();
        } else {
          correctAns = correctAns?.toString().trim().toUpperCase() ?? 'A';
        }

        final type = item['type']?.toString() ?? (correctAns is List ? 'multiple' : 'single');

        if (qText.isNotEmpty && options.length >= 2) {
          questions.add({
            'question': qText,
            'options': options,
            'correctAnswer': correctAns,
            'type': type,
          });
        }
      }
    }

    if (questions.isEmpty) {
      throw Exception('AI không tạo được câu hỏi nào hợp lệ.');
    }

    return questions;
  }
}
