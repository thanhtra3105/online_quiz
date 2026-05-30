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
        backgroundColor: Theme.of(context).colorScheme.background,
        endDrawer: MediaQuery.of(context).size.width <= 800 ? _buildMobileDrawer() : null,
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(),
              _buildTopBar(isTimeRunningOut),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            // Desktop layout: Main Question Area + Sidebar Grid
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildQuestionCanvas(),
                                ),
                                Container(
                                  width: 320,
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                  child: _buildSidebarGrid(),
                                ),
                              ],
                            );
                          } else {
                            // Mobile Layout
                            return _buildQuestionCanvas();
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: double.infinity,
      height: 4,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _questions.isEmpty ? 0 : ((_currentIndex + 1) / _questions.length),
        child: Container(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isTimeRunningOut) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.quizTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (MediaQuery.of(context).size.width > 600)
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Q ${_currentIndex + 1} of ${_questions.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (_suspiciousActionCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, size: 16, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        '$_suspiciousActionCount/$_maxSuspiciousActions',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isTimeRunningOut ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isTimeRunningOut ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: isTimeRunningOut ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isTimeRunningOut ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (MediaQuery.of(context).size.width > 800)
                ElevatedButton(
                  onPressed: _confirmSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('End Exam'),
                )
              else
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCanvas() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return _buildQuestionPage(index);
            },
          ),
        ),
        _buildBottomNav(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentIndex > 0
              ? OutlinedButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                )
              : const SizedBox.shrink(),
          ElevatedButton.icon(
            onPressed: _currentIndex < _questions.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : _confirmSubmit,
            icon: Icon(_currentIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.check, size: 20),
            label: Text(_currentIndex < _questions.length - 1 ? 'Next' : 'Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
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
    final isMultiple = data['correctAnswer'] is List;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Question ${index + 1}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (isMultiple) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Multiple Answers',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  data['question'] ?? '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 32),
                ...List.generate(options.length, (i) {
                  final letter = String.fromCharCode(65 + i);
                  bool isSelected = false;
                  if (isMultiple) {
                    if (_answers[questionId] is List) {
                      isSelected = (_answers[questionId] as List).contains(letter);
                    }
                  } else {
                    isSelected = _answers[questionId] == letter;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _selectAnswer(questionId, letter, isMultiple),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                                shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                                borderRadius: isMultiple ? BorderRadius.circular(6) : null,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                options[i],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarGrid() {
    int answeredCount = _answers.keys.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Navigator',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildLegendItem(Theme.of(context).colorScheme.primary, 'Answered', true),
                  const SizedBox(width: 16),
                  _buildLegendItem(Theme.of(context).colorScheme.surface, 'Unanswered', false),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final questionId = _questions[index].id;
              final isAnswered = _answers.containsKey(questionId) &&
                  (_answers[questionId] is List ? (_answers[questionId] as List).isNotEmpty : true);
              final isCurrent = index == _currentIndex;

              return InkWell(
                onTap: () {
                  if (MediaQuery.of(context).size.width <= 800) {
                    Navigator.pop(context);
                  }
                  _jumpToQuestion(index);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isAnswered ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.onSurface
                          : (isAnswered ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isAnswered ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '$answeredCount/${_questions.length} completed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _questions.isEmpty ? 0 : (answeredCount / _questions.length),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width <= 800) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text('End Exam'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(child: _buildSidebarGrid()),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isFilled) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: isFilled ? color : Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
