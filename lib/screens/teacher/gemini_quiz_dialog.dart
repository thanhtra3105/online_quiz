import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/gemini_service.dart';
import '../../utils/constants.dart';

class GeminiQuizDialog extends StatefulWidget {
  final Function(List<Map<String, dynamic>> questions, String? suggestedTitle)? onQuizGenerated;

  const GeminiQuizDialog({super.key, this.onQuizGenerated});

  @override
  State<GeminiQuizDialog> createState() => _GeminiQuizDialogState();
}

class _GeminiQuizDialogState extends State<GeminiQuizDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _topicController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _countController = TextEditingController(text: '5');

  int _questionCount = 5;
  String _difficulty = 'Trung bình';
  String _questionType = 'Tổng hợp (1 đáp án & Nhiều đáp án)';

  bool _isLoading = false;
  bool _obscureApiKey = true;
  String? _errorMessage;
  List<Map<String, dynamic>>? _generatedQuestions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentApiKey();
  }

  Future<void> _loadCurrentApiKey() async {
    final key = await GeminiService.getApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _apiKeyController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _onPromptChanged(String val) {
    // Tự động trích xuất số câu hỏi từ lời chat tự nhiên (ví dụ: "với 9 câu hỏi")
    final detected = GeminiService.extractQuestionCount(val);
    if (detected != null && detected != _questionCount) {
      setState(() {
        _questionCount = detected;
        _countController.text = detected.toString();
      });
    }
  }

  void _setQuestionCount(int count) {
    if (count < 1) count = 1;
    if (count > 100) count = 100;
    setState(() {
      _questionCount = count;
      _countController.text = count.toString();
    });
  }

  Future<void> _generateQuestions() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập chủ đề hoặc yêu cầu tạo đề.');
      return;
    }

    final parsedCount = int.tryParse(_countController.text.trim()) ?? _questionCount;
    final finalCount = parsedCount.clamp(1, 100);

    setState(() {
      _questionCount = finalCount;
      _isLoading = true;
      _errorMessage = null;
      _generatedQuestions = null;
    });

    try {
      final questions = await GeminiService.generateQuiz(
        topic: topic,
        questionCount: finalCount,
        difficulty: _difficulty,
        questionType: _questionType,
      );

      if (mounted) {
        setState(() {
          _generatedQuestions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await GeminiService.saveApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu Gemini API Key thành công!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppConstants.border(context)),
      ),
      backgroundColor: AppConstants.surf(context),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 780),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top App Bar / Header đồng bộ phong cách EditQuizPage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppConstants.border(context))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: AppConstants.brand(context), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo đề thi bằng Gemini AI',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tự động phân tích sâu & soạn đề thi chuẩn với Gemini 3.8 Flash',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppConstants.txtMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(context), size: 20),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                border: Border(bottom: BorderSide(color: AppConstants.border(context))),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppConstants.brand(context),
                indicatorWeight: 2.5,
                labelColor: AppConstants.brand(context),
                unselectedLabelColor: AppConstants.txtMuted(context),
                labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: const [
                  Tab(icon: Icon(Icons.psychology_outlined, size: 18), text: 'Tạo đề thi'),
                  Tab(icon: Icon(Icons.key_rounded, size: 18), text: 'Cài đặt API Key'),
                ],
              ),
            ),

            // Tab Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGenerateTab(context, isDark),
                  _buildApiKeyTab(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab(BuildContext context, bool isDark) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppConstants.brand(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gemini 3.8 Flash đang phân tích sâu và soạn đề...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.txt(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Đang tạo $_questionCount câu hỏi học thuật chất lượng cao...',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_generatedQuestions != null) {
      return _buildPreviewSection(context, isDark);
    }

    final detectedCount = GeminiService.extractQuestionCount(_topicController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic/Chat Prompt Input
          Row(
            children: [
              Expanded(
                child: Text(
                  'Yêu cầu hoặc chủ đề đề thi *',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                  ),
                ),
              ),
              if (detectedCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Đã nhận diện: $detectedCount câu',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _topicController,
            minLines: 2,
            maxLines: 4,
            onChanged: _onPromptChanged,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
            decoration: InputDecoration(
              hintText: 'Bạn có thể chat tự nhiên như: "Hãy tạo đề thi cho môn lập trình C++ với 9 câu hỏi về mảng và con trỏ"...',
              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context), height: 1.4),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(Icons.chat_outlined, size: 20, color: AppConstants.brand(context)),
              ),
              filled: true,
              fillColor: AppConstants.surfLow(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Topic Suggestions Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              'Lập trình C++ với 9 câu hỏi về OOP & con trỏ',
              'Flutter & Dart cơ bản 10 câu',
              'Toán giải tích 12 với 5 câu hỏi khó',
              'Tiếng Anh ngữ pháp TOEIC 10 câu',
            ].map((tag) {
              return ActionChip(
                avatar: Icon(Icons.auto_awesome_rounded, size: 14, color: AppConstants.brand(context)),
                label: Text(tag, style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                labelStyle: TextStyle(color: isDark ? Colors.white : AppConstants.brand(context), fontWeight: FontWeight.w500),
                side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFDBEAFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  setState(() {
                    _topicController.text = tag;
                    _onPromptChanged(tag);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Question Count & Difficulty & Format Row
          Text(
            'Tùy chỉnh thông số đề thi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppConstants.txt(context),
            ),
          ),
          const SizedBox(height: 10),

          // Row 1: Number of questions (Freeform input + stepper)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.surfLow(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.numbers_rounded, size: 18, color: AppConstants.brand(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Số lượng câu hỏi (tự nhập số bất kỳ):',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
                    const Spacer(),
                    // Decrement button
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                      color: AppConstants.brand(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Giảm 1 câu',
                      onPressed: () => _setQuestionCount(_questionCount - 1),
                    ),
                    const SizedBox(width: 8),
                    // Editable number field
                    SizedBox(
                      width: 65,
                      child: TextFormField(
                        controller: _countController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.brand(context),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          filled: true,
                          fillColor: AppConstants.surf(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.border(context))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val.trim());
                          if (parsed != null && parsed > 0) {
                            setState(() => _questionCount = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Increment button
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                      color: AppConstants.brand(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Tăng 1 câu',
                      onPressed: () => _setQuestionCount(_questionCount + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick preset chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [3, 5, 9, 10, 15, 20, 30].map((count) {
                    final isSelected = _questionCount == count;
                    return InkWell(
                      onTap: () => _setQuestionCount(count),
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppConstants.brand(context)
                              : (isDark ? AppConstants.surfHigh(context) : Colors.white),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? AppConstants.brand(context) : AppConstants.border(context),
                          ),
                        ),
                        child: Text(
                          '$count câu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppConstants.txt(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Row 2: Difficulty & Question Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mức độ khó',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppConstants.surfLow(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConstants.border(context)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _difficulty,
                          isExpanded: true,
                          dropdownColor: AppConstants.surf(context),
                          items: ['Dễ', 'Trung bình', 'Khó', 'Tổng hợp'].map((diff) {
                            return DropdownMenuItem(
                              value: diff,
                              child: Text(diff, style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: AppConstants.txt(context))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _difficulty = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dạng câu hỏi',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppConstants.surfLow(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConstants.border(context)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _questionType,
                          isExpanded: true,
                          dropdownColor: AppConstants.surf(context),
                          items: [
                            'Tổng hợp (1 đáp án & Nhiều đáp án)',
                            'Chỉ câu hỏi 1 đáp án duy nhất',
                            'Có cả câu Đúng/Sai và 4 lựa chọn',
                          ].map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: AppConstants.txt(context)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _questionType = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Error Message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit Button đồng bộ tông màu Brand
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generateQuestions,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                'Tạo $_questionCount câu hỏi với Gemini AI',
                style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppConstants.brand(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, bool isDark) {
    final questions = _generatedQuestions!;

    return Column(
      children: [
        // Preview Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
            border: Border(bottom: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFF86EFAC))),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã tạo thành công ${questions.length} câu hỏi bằng Gemini AI',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                    fontSize: 13.5,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _generatedQuestions = null),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Tạo lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.brand(context),
                  side: BorderSide(color: AppConstants.border(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Questions List đồng bộ hoàn toàn với QuestionCardItem trong EditQuizPage
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final q = questions[i];
              final isMultiple = q['type'] == 'multiple';
              final options = (q['options'] as List).cast<String>();
              final correctAns = q['correctAnswer'];

              return Container(
                decoration: BoxDecoration(
                  color: AppConstants.surf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Card Header (như EditQuizPage)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppConstants.surfLow(context),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? AppConstants.border(context) : const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              'Câu ${i + 1}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.brand(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isMultiple)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Text(
                                'Nhiều đáp án',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Text(
                                '1 đáp án',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Question Content
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q['question'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.txt(context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Option rows styled like EditQuizPage
                          ...List.generate(options.length, (optIdx) {
                            final char = String.fromCharCode(65 + optIdx);
                            final isCorrect = correctAns is List
                                ? correctAns.contains(char)
                                : correctAns == char;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4))
                                    : AppConstants.surfLow(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCorrect ? const Color(0xFF86EFAC) : AppConstants.border(context),
                                  width: isCorrect ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Circle letter
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isCorrect ? const Color(0xFF16A34A) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isCorrect ? const Color(0xFF16A34A) : AppConstants.border(context),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        char,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isCorrect ? Colors.white : AppConstants.txt(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      options[optIdx],
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                                        color: isCorrect
                                            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                            : AppConstants.txt(context),
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppConstants.surf(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border(top: BorderSide(color: AppConstants.border(context))),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: BorderSide(color: AppConstants.border(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Đóng',
                  style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onQuizGenerated?.call(questions, _topicController.text.trim());
                    Navigator.pop(context, questions);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    'Sử dụng ${questions.length} câu hỏi này',
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppConstants.brand(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.brand(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.key_rounded, color: AppConstants.brand(context), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Cấu hình Google Gemini API Key',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'API Key được sử dụng để gọi mô hình Gemini 3.8 Flash phân tích sâu nhằm tạo đề thi chất lượng cao và chuẩn hóa tài liệu.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
          ),
          const SizedBox(height: 20),

          Text(
            'Gemini API Key',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
            decoration: InputDecoration(
              hintText: 'Dán mã API Key vào đây',
              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
              prefixIcon: Icon(Icons.vpn_key_outlined, size: 20, color: AppConstants.brand(context)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppConstants.txtMuted(context),
                  size: 20,
                ),
                tooltip: _obscureApiKey ? 'Hiện API Key để chỉnh sửa' : 'Ẩn API Key',
                onPressed: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
              ),
              filled: true,
              fillColor: AppConstants.surfLow(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfLow(context) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppConstants.border(context) : const Color(0xFFDBEAFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppConstants.brand(context), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bạn có thể lấy Google Gemini API Key hoàn toàn miễn phí tại Google AI Studio (aistudio.google.com). Key sẽ được lưu trên trình duyệt của bạn hoặc cấu hình sẵn trong file gemini_service.dart.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? AppConstants.txt(context) : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveApiKey,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Lưu API Key',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: AppConstants.brand(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
