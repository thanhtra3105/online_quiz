// lib/screens/teacher/edit_quiz_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/question_image_view.dart';

class EditQuizPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;
  final String? className;
  final String? classId;

  final bool isQuestionBank;

  const EditQuizPage({
    super.key,
    required this.quizId,
    required this.quizData,
    this.className,
    this.classId,
    this.isQuestionBank = false,
  });

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _maxViolationsController;

  List<Map<String, dynamic>> _questions = [];
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quizData['title'] ?? '');
    _durationController = TextEditingController(
      text: (widget.quizData['duration'] ?? 30).toString(),
    );
    _maxViolationsController = TextEditingController(
      text: (widget.quizData['maxSuspiciousActions'] ?? 5).toString(),
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _durationController.dispose();
    _maxViolationsController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final collectionName = widget.isQuestionBank ? 'quiz_banks' : 'quiz';
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.quizId)
          .collection('questions')
          .get();

      setState(() {
        final docs = List<QueryDocumentSnapshot>.from(questionsSnapshot.docs);
        docs.sort((a, b) {
          try {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aRaw = aData?['order'];
            final bRaw = bData?['order'];
            final num? aOrder = aRaw is num ? aRaw : (aRaw != null ? num.tryParse(aRaw.toString()) : null);
            final num? bOrder = bRaw is num ? bRaw : (bRaw != null ? num.tryParse(bRaw.toString()) : null);
            if (aOrder != null && bOrder != null) {
              return aOrder.compareTo(bOrder);
            }
            if (aOrder != null) return -1;
            if (bOrder != null) return 1;
          } catch (_) {}
          return a.id.compareTo(b.id);
        });

        _questions = docs.map((doc) {
          final data = (doc.data() as Map<String, dynamic>?) ?? {};
          List<String> imgs = [];
          if (data['imageUrls'] is List) {
            imgs = (data['imageUrls'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else if (data['imageUrl'] != null && data['imageUrl'].toString().trim().isNotEmpty) {
            imgs = [data['imageUrl'].toString().trim()];
          }
          return {
            'id': doc.id,
            'question': data['question'] ?? '',
            'options': List<String>.from(data['options'] ?? []),
            'correctAnswer': data['correctAnswer'] ?? 'A',
            'imageUrls': imgs,
            'imageUrl': imgs.isNotEmpty ? imgs.first : null,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải câu hỏi: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav / Header đồng bộ breadcrumbs
            _buildTopAppBar(),

            // Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Đang tải dữ liệu câu hỏi...',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppConstants.txtMuted(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Form(
                          key: _formKey,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 24,
                              vertical: 24,
                            ),
                            itemCount: 3 + _questions.length,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildInfoCard(),
                                );
                              }
                              if (index == 1) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildQuestionsHeader(),
                                );
                              }
                              if (index == 2 + _questions.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 48),
                                  child: _buildBottomActions(),
                                );
                              }
                              final qIndex = index - 2;
                              final qData = _questions[qIndex];
                              final qId = qData['id']?.toString() ?? 'q_$qIndex';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _QuestionCardItem(
                                  key: ValueKey(qId),
                                  index: qIndex,
                                  question: qData,
                                  onDelete: () => _deleteQuestion(qIndex),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    final hasClass = widget.className != null && widget.className!.isNotEmpty;
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppConstants.txt(context)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isQuestionBank ? 'Chỉnh sửa ngân hàng' : 'Chỉnh sửa đề thi',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.txt(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveQuiz,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSaving ? 'Lưu...' : 'Lưu',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.brand(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                if (widget.isQuestionBank) ...[
                  Tooltip(
                    message: 'Quay lại Ngân hàng câu hỏi',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 16, color: AppConstants.txtMuted(context)),
                            const SizedBox(width: 6),
                            Text(
                              'Ngân hàng câu hỏi',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.border(context)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                    ),
                    child: Text(
                      'Chỉnh sửa ngân hàng',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.brand(context)),
                    ),
                  ),
                ] else if (hasClass) ...[
                  Tooltip(
                    message: 'Quay lại Quản lý lớp học',
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context)
                          ..pop()
                          ..pop();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 16, color: AppConstants.txtMuted(context)),
                            const SizedBox(width: 6),
                            Text(
                              'Quản lý lớp học',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.border(context)),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Quay lại Chi tiết lớp',
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          widget.className!,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.border(context)),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Quay lại Chi tiết đề thi',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          'Chi tiết đề thi',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.border(context)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                    ),
                    child: Text(
                      'Chỉnh sửa đề thi',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.brand(context)),
                    ),
                  ),
                ] else ...[
                  Tooltip(
                    message: 'Quay lại',
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 16, color: AppConstants.txtMuted(context)),
                            const SizedBox(width: 6),
                            Text(
                              'Quay lại',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.border(context)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                    ),
                    child: Text(
                      'Chỉnh sửa đề thi',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.brand(context)),
                    ),
                  ),
                ],
                const Spacer(),
                // Nút Lưu thay đổi
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveQuiz,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.brand(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Thông báo',
                  onPressed: () {},
                  icon: Icon(Icons.notifications_none_rounded, color: AppConstants.txtMuted(context)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Tài khoản',
                  onPressed: () {},
                  icon: Icon(Icons.account_circle_outlined, color: AppConstants.txtMuted(context)),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    final isBank = widget.isQuestionBank;
    final isDark = AppConstants.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.brand(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBank ? Icons.inventory_2_outlined : Icons.info_outline_rounded,
                  color: AppConstants.brand(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBank ? 'Thông tin chung về ngân hàng câu hỏi' : 'Thông tin chung về đề thi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.txt(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBank
                          ? 'Cập nhật tên ngân hàng và quản lý các câu hỏi bên trong'
                          : 'Cập nhật tên đề thi, thời gian làm bài và số lần vi phạm tối đa cho phép',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
            decoration: InputDecoration(
              labelText: isBank ? 'Tên ngân hàng câu hỏi' : 'Tên đề thi',
              labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
              prefixIcon: Icon(
                isBank ? Icons.inventory_2_outlined : Icons.title_rounded,
                color: AppConstants.brand(context),
                size: 20,
              ),
              filled: true,
              fillColor: AppConstants.surfLow(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
            ),
            validator: (v) => v!.isEmpty ? (isBank ? 'Vui lòng nhập tên ngân hàng' : 'Vui lòng nhập tên đề thi') : null,
          ),
          if (!isBank) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                final durationField = TextFormField(
                  controller: _durationController,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
                  decoration: InputDecoration(
                    labelText: 'Thời gian làm bài (phút)',
                    labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    prefixIcon: Icon(Icons.timer_outlined, color: AppConstants.brand(context), size: 20),
                    filled: true,
                    fillColor: AppConstants.surfLow(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập thời gian' : null,
                );
                final violationsField = TextFormField(
                  controller: _maxViolationsController,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txt(context)),
                  decoration: InputDecoration(
                    labelText: 'Số lần vi phạm tối đa',
                    labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    prefixIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                    filled: true,
                    fillColor: AppConstants.surfLow(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập số lần' : null,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      durationField,
                      const SizedBox(height: 16),
                      violationsField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: durationField),
                    const SizedBox(width: 16),
                    Expanded(child: violationsField),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsHeader() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final titleWidget = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.brand(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.quiz_rounded, color: AppConstants.brand(context), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Danh sách câu hỏi (${_questions.length})',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.txt(context),
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );

    final btnWidget = FilledButton.icon(
      onPressed: _addNewQuestion,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text(
        'Thêm câu hỏi',
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppConstants.brand(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleWidget,
          const SizedBox(height: 12),
          btnWidget,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleWidget),
        const SizedBox(width: 12),
        btnWidget,
      ],
    );
  }

  Widget _buildBottomActions() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cancelBtn = OutlinedButton(
      onPressed: _isSaving ? null : () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: AppConstants.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        'Hủy bỏ',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppConstants.txtMuted(context),
        ),
      ),
    );

    final saveBtn = FilledButton.icon(
      onPressed: _isSaving ? null : _saveQuiz,
      icon: _isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_rounded, size: 18),
      label: Text(
        _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppConstants.brand(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (isMobile) {
      return Row(
        children: [
          Expanded(child: cancelBtn),
          const SizedBox(width: 12),
          Expanded(child: saveBtn),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cancelBtn,
        const SizedBox(width: 14),
        saveBtn,
      ],
    );
  }

  void _addNewQuestion() {
    setState(() {
      _questions.insert(0, {
        'id': 'new_${DateTime.now().microsecondsSinceEpoch}',
        'question': '',
        'options': ['', '', '', ''],
        'correctAnswer': 'A',
        'imageUrl': null,
        'imageUrls': <String>[],
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          widget.isQuestionBank ? 80.0 : 180.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm ô câu hỏi mới lên đầu danh sách (Câu 1)'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.border(context)),
        ),
        title: Text(
          'Xác nhận xóa',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: AppConstants.txt(context)),
        ),
        content: Text(
          'Bạn có chắc muốn xóa câu ${index + 1}?',
          style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.border(context)),
              foregroundColor: AppConstants.txt(context),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _questions.removeAt(index));
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin các câu hỏi'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = AppConstants.isDarkMode(context);

    // 1. Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surf(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.border(ctx)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfHigh(ctx) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.help_outline_rounded, color: AppConstants.brand(ctx), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              widget.isQuestionBank ? 'Xác nhận lưu ngân hàng' : 'Xác nhận lưu đề thi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppConstants.txt(ctx),
              ),
            ),
          ],
        ),
        content: Text(
          widget.isQuestionBank
              ? 'Bạn có chắc chắn muốn lưu các thay đổi cho ngân hàng câu hỏi này (${_questions.length} câu hỏi)?'
              : 'Bạn có chắc chắn muốn lưu các thay đổi cho đề thi này (${_questions.length} câu hỏi)?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppConstants.txtMuted(ctx),
            height: 1.4,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.border(ctx)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Hủy bỏ',
              style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(ctx)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.brand(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Xác nhận lưu',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final collectionName = widget.isQuestionBank ? 'quiz_banks' : 'quiz';
      final targetRef = FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.quizId);

      // 2. Update Info
      if (widget.isQuestionBank) {
        await targetRef.update({
          'title': _titleController.text.trim(),
          'questionCount': _questions.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await targetRef.update({
          'title': _titleController.text.trim(),
          'duration': int.tryParse(_durationController.text.trim()) ?? 30,
          'maxSuspiciousActions': int.tryParse(_maxViolationsController.text.trim()) ?? 5,
          'questionCount': _questions.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Update Questions in a single batch
      final existingQuestions = await targetRef.collection('questions').get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in existingQuestions.docs) {
        batch.delete(doc.reference);
      }

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final docId = 'q_${i.toString().padLeft(4, '0')}';
        final newDoc = targetRef.collection('questions').doc(docId);
        final qData = <String, dynamic>{
          'order': i,
          'question': question['question'].toString().trim(),
          'options': (question['options'] as List<dynamic>)
              .map((opt) => opt.toString().trim())
              .toList(),
          'correctAnswer': question['correctAnswer'],
        };

        final List<String> imgs = [];
        if (question['imageUrls'] is List) {
          imgs.addAll((question['imageUrls'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty));
        } else if (question['imageUrl'] != null && question['imageUrl'].toString().trim().isNotEmpty) {
          imgs.add(question['imageUrl'].toString().trim());
        }

        if (imgs.isNotEmpty) {
          qData['imageUrls'] = imgs;
          qData['imageUrl'] = imgs.first;
        }
        batch.set(newDoc, qData);
      }

      await batch.commit();

      // 4. Show success dialog and pop
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppConstants.surf(dialogCtx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppConstants.border(dialogCtx)),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isQuestionBank ? 'Lưu ngân hàng thành công!' : 'Lưu đề thi thành công!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.txt(dialogCtx),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isQuestionBank
                        ? 'Dữ liệu ngân hàng và ${_questions.length} câu hỏi đã được lưu thành công vào hệ thống.'
                        : 'Dữ liệu đề thi và ${_questions.length} câu hỏi đã được lưu thành công vào hệ thống.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      color: AppConstants.txtMuted(dialogCtx),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.brand(dialogCtx),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Xong & Quay lại',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _QuestionCardItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> question;
  final VoidCallback onDelete;

  const _QuestionCardItem({
    super.key,
    required this.index,
    required this.question,
    required this.onDelete,
  });

  @override
  State<_QuestionCardItem> createState() => _QuestionCardItemState();
}

class _QuestionCardItemState extends State<_QuestionCardItem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _addOption() {
    setState(() {
      final opts = widget.question['options'];
      if (opts is List) {
        opts.add('');
      }
    });
  }

  void _removeOption(int optIndex) {
    setState(() {
      final opts = widget.question['options'];
      if (opts is List) {
        if (opts.length > 2) {
          opts.removeAt(optIndex);
          widget.question['correctAnswer'] = 'A';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Câu hỏi cần ít nhất 2 đáp án')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final question = widget.question;
    final index = widget.index;
    final options = (question['options'] as List<dynamic>).map((e) => e.toString()).toList();
    final qId = question['id']?.toString() ?? 'q_$index';
    final isDark = AppConstants.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppConstants.surfLow(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppConstants.border(context))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppConstants.border(context) : const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.brand(context),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  tooltip: 'Xóa câu hỏi',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Input
                TextFormField(
                  key: ValueKey('${qId}_question'),
                  initialValue: question['question'],
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.txt(context)),
                  decoration: InputDecoration(
                    labelText: 'Nội dung câu hỏi',
                    labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                    prefixIcon: Icon(Icons.help_outline_rounded, color: AppConstants.brand(context), size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 1.5)),
                    filled: true,
                    fillColor: AppConstants.surfLow(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                  onChanged: (val) => question['question'] = val,
                  validator: (val) => val!.isEmpty ? 'Vui lòng nhập câu hỏi' : null,
                ),

                // Question Images (Single or Multiple)
                () {
                  List<String> currentImgs = [];
                  if (question['imageUrls'] is List) {
                    currentImgs = (question['imageUrls'] as List)
                        .map((e) => e.toString().trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                  } else if (question['imageUrl'] != null &&
                      question['imageUrl'].toString().trim().isNotEmpty) {
                    currentImgs = [question['imageUrl'].toString().trim()];
                  }

                  if (currentImgs.isNotEmpty) {
                    return QuestionImageView(
                      imageUrls: currentImgs,
                      isEditable: true,
                      onAddMore: () async {
                        final newUrl = await QuestionImageHelper.pickOrEnterImageUrl(context);
                        if (newUrl != null && newUrl.isNotEmpty) {
                          setState(() {
                            currentImgs.add(newUrl);
                            question['imageUrls'] = currentImgs;
                            question['imageUrl'] = currentImgs.first;
                          });
                        }
                      },
                      onChangeIndex: (imgIdx) async {
                        final newUrl = await QuestionImageHelper.pickOrEnterImageUrl(context);
                        if (newUrl != null && newUrl.isNotEmpty) {
                          setState(() {
                            currentImgs[imgIdx] = newUrl;
                            question['imageUrls'] = currentImgs;
                            question['imageUrl'] = currentImgs.first;
                          });
                        }
                      },
                      onDeleteIndex: (imgIdx) {
                        setState(() {
                          currentImgs.removeAt(imgIdx);
                          question['imageUrls'] = currentImgs;
                          question['imageUrl'] = currentImgs.isNotEmpty ? currentImgs.first : null;
                        });
                      },
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final url = await QuestionImageHelper.pickOrEnterImageUrl(context);
                          if (url != null && url.isNotEmpty) {
                            setState(() {
                              question['imageUrls'] = [url];
                              question['imageUrl'] = url;
                            });
                          }
                        },
                        icon: Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppConstants.brand(context)),
                        label: Text(
                          'Thêm hình ảnh minh họa',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.brand(context),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE)),
                          backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    );
                  }
                }(),

                const SizedBox(height: 18),
                Text(
                  'Các phương án lựa chọn (Bấm vào chữ cái để chọn đáp án đúng):',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Options
                ...List.generate(options.length, (optIndex) {
                  final letter = String.fromCharCode(65 + optIndex);
                  final rawCorrect = question['correctAnswer'];

                  bool isSelected = false;
                  if (rawCorrect is List) {
                    isSelected = rawCorrect.map((e) => e.toString()).contains(letter);
                  } else {
                    isSelected = rawCorrect.toString() == letter;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        // Selection Bubble
                        InkWell(
                          onTap: () {
                            setState(() {
                              List<String> currentAnswers;
                              if (rawCorrect is List) {
                                currentAnswers = List<String>.from(rawCorrect);
                              } else {
                                currentAnswers = [rawCorrect.toString()];
                              }

                              if (!currentAnswers.contains(letter)) {
                                currentAnswers.add(letter);
                                currentAnswers.sort();
                              } else {
                                currentAnswers.remove(letter);
                              }

                              if (currentAnswers.isEmpty) {
                                currentAnswers.add('A');
                              }

                              if (currentAnswers.length == 1) {
                                question['correctAnswer'] = currentAnswers.first;
                              } else {
                                question['correctAnswer'] = currentAnswers;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF16A34A) : AppConstants.surfLow(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF16A34A) : AppConstants.border(context),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: isSelected ? Colors.white : AppConstants.txt(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Option Text Input
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('${qId}_opt_$optIndex'),
                            initialValue: options[optIndex],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                  : AppConstants.txt(context),
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: isSelected
                                  ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
                                  : AppConstants.surf(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isSelected ? const Color(0xFF86EFAC) : AppConstants.border(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isSelected ? const Color(0xFF86EFAC) : AppConstants.border(context),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppConstants.brand(context),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              (question['options'] as List)[optIndex] = val;
                            },
                            validator: (val) => val!.isEmpty ? 'Vui lòng nhập nội dung đáp án' : null,
                          ),
                        ),

                        // Remove Option Button (chỉ hiện khi > 2 đáp án)
                        if (options.length > 2) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(context), size: 20),
                            onPressed: () => _removeOption(optIndex),
                            tooltip: 'Xóa đáp án này',
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 6),
                // Add Option Button
                OutlinedButton.icon(
                  onPressed: _addOption,
                  icon: Icon(Icons.add_rounded, size: 16, color: AppConstants.brand(context)),
                  label: Text(
                    'Thêm đáp án khác',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.brand(context)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE)),
                    backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
