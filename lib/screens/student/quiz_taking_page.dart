// lib/screens/student/quiz_taking_page.dart
import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final String classId;
  final String quizTitle;
  final int duration;
  final String studentId;

  const QuizTakingPage({
    Key? key,
    required this.quizId,
    required this.classId,
    required this.quizTitle,
    required this.duration,
    required this.studentId,
  }) : super(key: key);

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  // State variables
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Data
  List<QueryDocumentSnapshot> _questions = [];
  final Map<String, dynamic> _answers = {};

  // ============================================
  // CHEATING DETECTION VARIABLES
  // ============================================
  int _suspiciousActionCount = 0;
  int _maxSuspiciousActions = 5;
  bool _hasShownWarning = false;
  DateTime? _lastFocusLossTime;
  bool _isInitialFullscreenEntry = true;
  bool _isCurrentlyAway = false;

  // ============================================
  // FULLSCREEN & WINDOW MONITORING VARIABLES
  // ============================================
  bool _isFullscreen = false;
  bool _isEnteringFullscreen = false;
  Size? _initialWindowSize;
  Timer? _windowMonitorTimer;
  html.EventListener? _fullscreenChangeListener;
  html.EventListener? _windowResizeListener;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration * 60;
    _loadQuestions();
    _startTimer();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enforceFullscreen();
      _startWindowMonitoring();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _windowMonitorTimer?.cancel();
    _pageController.dispose();
    _cleanupFullscreenListeners();
    if (_isFullscreen) {
      html.document.exitFullscreen();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============================================
  // FULLSCREEN LOGIC
  // ============================================
  void _enforceFullscreen() {
    try {
      _isEnteringFullscreen = true;
      html.document.documentElement?.requestFullscreen();
      _fullscreenChangeListener = (html.Event event) => _onFullscreenChange();
      html.document.addEventListener(
        'fullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.addEventListener(
        'webkitfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.addEventListener(
        'mozfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.addEventListener(
        'msfullscreenchange',
        _fullscreenChangeListener!,
      );
      setState(() => _isFullscreen = true);
    } catch (e) {
      _isEnteringFullscreen = false;
    }
  }

  void _showReenterFullscreenDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Vào lại chế độ fullscreen'),
          content: const Text('Bạn phải làm bài trong chế độ fullscreen.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _isEnteringFullscreen = true;
                html.document.documentElement?.requestFullscreen();
              },
              child: const Text('Vào fullscreen'),
            ),
          ],
        ),
      ),
    );
  }

  void _onFullscreenChange() {
    final isCurrentlyFullscreen = html.document.fullscreenElement != null;
    if (isCurrentlyFullscreen) {
      if (mounted) setState(() => _isFullscreen = true);
      _isEnteringFullscreen = false;
      _isInitialFullscreenEntry = false;
      _initialWindowSize = Size(
        html.window.innerWidth!.toDouble(),
        html.window.innerHeight!.toDouble(),
      );
    } else if (!isCurrentlyFullscreen && !_isSubmitting && !_isLoading) {
      if (_isEnteringFullscreen && !_isFullscreen) return;
      _isEnteringFullscreen = false;
      if (mounted) setState(() => _isFullscreen = false);
      _handleSuspiciousAction('Exited fullscreen mode');
      if (mounted && _suspiciousActionCount < _maxSuspiciousActions) {
        _showReenterFullscreenDialog();
      }
    }
  }

  void _cleanupFullscreenListeners() {
    if (_fullscreenChangeListener != null) {
      html.document.removeEventListener(
        'fullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.removeEventListener(
        'webkitfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.removeEventListener(
        'mozfullscreenchange',
        _fullscreenChangeListener!,
      );
      html.document.removeEventListener(
        'msfullscreenchange',
        _fullscreenChangeListener!,
      );
    }
  }

  // ============================================
  // WINDOW MONITORING LOGIC
  // ============================================
  void _startWindowMonitoring() {
    _initialWindowSize = Size(
      html.window.innerWidth!.toDouble(),
      html.window.innerHeight!.toDouble(),
    );
    _windowResizeListener = (html.Event event) => _onWindowResize();
    html.window.addEventListener('resize', _windowResizeListener!);
    _windowMonitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isSubmitting && !_isLoading) _checkWindowSize();
    });
  }

  void _onWindowResize() {
    if (_isSubmitting ||
        _isLoading ||
        _isEnteringFullscreen ||
        _isInitialFullscreenEntry)
      return;
    _checkWindowSize();
  }

  void _checkWindowSize() {
    if (_initialWindowSize == null ||
        _isEnteringFullscreen ||
        _isInitialFullscreenEntry)
      return;
    final isCurrentlyFullscreen = html.document.fullscreenElement != null;
    if (!isCurrentlyFullscreen) return;

    final currentSize = Size(
      html.window.innerWidth!.toDouble(),
      html.window.innerHeight!.toDouble(),
    );
    final widthDiff = (currentSize.width - _initialWindowSize!.width).abs();
    final heightDiff = (currentSize.height - _initialWindowSize!.height).abs();

    if (widthDiff > 10 || heightDiff > 10) {
      _handleSuspiciousAction('Window resize detected');
      _initialWindowSize = currentSize;
    }
  }

  // ============================================
  // LIFECYCLE LOGIC
  // ============================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitting || _isLoading) return;
    if ((state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden)) {
      if (_isEnteringFullscreen || _isInitialFullscreenEntry) return;
      if (!_isCurrentlyAway) {
        _isCurrentlyAway = true;
        _handleSuspiciousAction('Tab/Window switch detected');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isEnteringFullscreen || _isInitialFullscreenEntry) return;
      _isCurrentlyAway = false;
      if (!_isFullscreen) _enforceFullscreen();
    }
  }

  // ============================================
  // VIOLATION HANDLING
  // ============================================
  void _handleSuspiciousAction(String reason) {
    final now = DateTime.now();
    if (_lastFocusLossTime != null &&
        now.difference(_lastFocusLossTime!).inSeconds < 2)
      return;
    _lastFocusLossTime = now;

    setState(() => _suspiciousActionCount++);

    if (_suspiciousActionCount >= _maxSuspiciousActions) {
      _autoSubmitForCheating();
    } else if (_suspiciousActionCount == _maxSuspiciousActions - 1 &&
        !_hasShownWarning) {
      _showFinalWarning();
    } else {
      _showViolationNotification();
    }
  }

  void _showViolationNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cảnh báo vi phạm! Lần $_suspiciousActionCount/$_maxSuspiciousActions',
        ),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }

  void _showFinalWarning() {
    if (!mounted || _hasShownWarning) return;
    _hasShownWarning = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cảnh báo cuối cùng!'),
        content: Text(
          'Bạn đã vi phạm $_suspiciousActionCount lần. Lần tới bài thi sẽ tự nộp.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tôi hiểu'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SUBMISSION LOGIC
  // ============================================
  Future<void> _autoSubmitForCheating() async {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Bài thi tự động nộp do vi phạm quá nhiều lần!'),
        backgroundColor: Colors.red,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    await _submitQuizWithCheatingFlag();
  }

  Future<void> _submitQuizWithCheatingFlag() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      double score = _calculateTotalScore();

      await FirebaseFirestore.instance.collection('submissions').add({
        'studentId': widget.studentId,
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': (widget.duration * 60) - _secondsRemaining,
        'cheatingDetected': true,
        'suspiciousActionCount': _suspiciousActionCount,
        'autoSubmitted': true,
        'submissionReason': 'Auto-submitted due to excessive violations',
      });

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Bài thi đã nộp'),
            content: Text(
              'Bài thi đã tự động nộp do vi phạm. Điểm: $score/${_questions.length}',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  void _forceSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      double score = _calculateTotalScore();

      await FirebaseFirestore.instance.collection('submissions').add({
        'studentId': widget.studentId,
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': (widget.duration * 60) - _secondsRemaining,
        'cheatingDetected': false,
        'suspiciousActionCount': _suspiciousActionCount,
        'autoSubmitted': false,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nộp bài thành công! Điểm số: ${score.toStringAsFixed(2)}/${_questions.length}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // --- HÀM TÍNH ĐIỂM (Unit Score / Penalty Score) ---
  double _calculateTotalScore() {
    double totalScore = 0.0;
    for (var doc in _questions) {
      final data = doc.data() as Map<String, dynamic>;
      final qId = doc.id;
      final rawCorrect = data['correctAnswer'];
      final rawStudent = _answers[qId];

      if (rawStudent == null) continue;

      double questionScore = 0.0;

      if (rawCorrect is List) {
        // Multiple Choice logic
        List<String> correctList = List<String>.from(
          rawCorrect.map((e) => e.toString()),
        );
        List<String> studentList = rawStudent is List
            ? List<String>.from(rawStudent.map((e) => e.toString()))
            : [rawStudent.toString()];

        if (correctList.isNotEmpty) {
          double unitScore = 1.0 / correctList.length;
          double penaltyScore = 2.0 * unitScore;
          for (var ans in studentList) {
            if (correctList.contains(ans))
              questionScore += unitScore;
            else
              questionScore -= penaltyScore;
          }
        }
        if (questionScore < 0) questionScore = 0.0;
      } else {
        // Single Choice logic
        if (rawStudent.toString() == rawCorrect.toString()) questionScore = 1.0;
      }
      totalScore += questionScore;
    }
    return totalScore;
  }

  // ============================================
  // OTHER HELPERS
  // ============================================
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _forceSubmit();
      }
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final quizDoc = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .get();
      if (quizDoc.exists) {
        final quizData = quizDoc.data() as Map<String, dynamic>;
        _maxSuspiciousActions = quizData['maxSuspiciousActions'] ?? 5;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .collection('questions')
          .get();
      setState(() {
        _questions = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // --- LOGIC CHỌN ĐÁP ÁN (ĐÃ SỬA: KHÔNG TỰ CỘNG INDEX) ---
  void _selectAnswer(String questionId, String answer, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        List<String> currentAnswers = [];
        if (_answers[questionId] is List) {
          currentAnswers = List<String>.from(_answers[questionId]);
        } else if (_answers[questionId] != null) {
          currentAnswers = [_answers[questionId].toString()];
        }

        if (currentAnswers.contains(answer)) {
          currentAnswers.remove(answer);
        } else {
          currentAnswers.add(answer);
        }
        currentAnswers.sort();
        _answers[questionId] = currentAnswers;
      } else {
        _answers[questionId] = answer;

        // Tự động chuyển trang nhưng KHÔNG tự cộng _currentIndex
        // PageView.onPageChanged sẽ làm việc đó
        int qIndex = _questions.indexWhere((doc) => doc.id == questionId);
        if (qIndex == _currentIndex && _currentIndex < _questions.length - 1) {
          Future.delayed(const Duration(milliseconds: 250), () {
            // Kiểm tra lại nếu người dùng chưa tự chuyển trang
            if (mounted &&
                _pageController.hasClients &&
                _pageController.page?.round() == qIndex) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }
    });
  }

  void _jumpToQuestion(int index) {
    _pageController.jumpToPage(index);
    Navigator.pop(context);
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp bài?'),
        content: Text(
          'Bạn đã làm ${_answers.length}/${_questions.length} câu hỏi.\nBạn có chắc chắn muốn nộp bài không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kiểm tra lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _forceSubmit();
            },
            child: const Text('Nộp ngay'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    final isTimeRunningOut = _secondsRemaining < 300;

    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không thể thoát khi đang làm bài!'),
          ),
        );
        return false;
      },
      child: Scaffold(
        endDrawer: _buildQuestionPaletteDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(isTimeRunningOut),

                // Question PageView
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue.shade600,
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          physics:
                              const NeverScrollableScrollPhysics(), // Người dùng phải dùng nút để chuyển
                          itemCount: _questions.length,
                          // --- QUAN TRỌNG: Cập nhật index tại đây ---
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return _buildQuestionPage(index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTimeRunningOut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isTimeRunningOut
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isTimeRunningOut
                    ? Colors.red.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: isTimeRunningOut ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isTimeRunningOut ? Colors.red : Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Violation counter
          if (_suspiciousActionCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_suspiciousActionCount/$_maxSuspiciousActions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút TRƯỚC: Chỉ điều khiển PageController
                  TextButton.icon(
                    onPressed: _currentIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Câu trước'),
                  ),

                  // Nút SAU: Chỉ điều khiển PageController
                  ElevatedButton.icon(
                    onPressed: _currentIndex < _questions.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : _confirmSubmit,
                    icon: Icon(
                      _currentIndex < _questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Câu sau'
                          : 'Hoàn thành',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex < _questions.length - 1
                          ? Colors.blue.shade50
                          : Colors.green.shade600,
                      foregroundColor: _currentIndex < _questions.length - 1
                          ? Colors.blue.shade700
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          Builder(
            builder: (context) => InkWell(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_answers.length}/${_questions.length} câu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _confirmSubmit,
            child: const Text('Nộp bài'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final doc = _questions[index];
    final data = doc.data() as Map<String, dynamic>;
    final questionId = doc.id;
    final options = List<String>.from(data['options'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Câu ${index + 1}',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '/${_questions.length}',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data['question'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ...List.generate(options.length, (i) {
            final letter = String.fromCharCode(65 + i);
            final rawCorrect = data['correctAnswer'];
            final isMultiple = rawCorrect is List;
            bool isSelected = false;
            if (isMultiple) {
              if (_answers[questionId] is List)
                isSelected = (_answers[questionId] as List).contains(letter);
            } else {
              isSelected = _answers[questionId] == letter;
            }

            return GestureDetector(
              onTap: () => _selectAnswer(questionId, letter, isMultiple),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.white,
                        shape: isMultiple
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius: isMultiple
                            ? BorderRadius.circular(6)
                            : null,
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade400, width: 2),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${options[i]}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? Colors.blue.shade900
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionPaletteDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tổng quan bài thi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildLegendItem(Colors.blue.shade600, 'Đã làm'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.grey.shade300, 'Chưa làm'),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      Colors.orange.shade400,
                      'Đang chọn',
                      isBorder: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final questionId = _questions[index].id;
                final isAnswered = _answers.containsKey(questionId);
                final isCurrent = index == _currentIndex;
                return InkWell(
                  onTap: () => _jumpToQuestion(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? Colors.blue.shade600
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(color: Colors.orange.shade400, width: 3)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isAnswered
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmSubmit();
                },
                child: const Text('Nộp bài thi'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isBorder ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isBorder ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
