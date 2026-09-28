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
  bool _isCurrentlyAway = false;
  bool _hasEnteredFullscreenOnce = false;

  // ============================================
  // FULLSCREEN & MONITORING VARIABLES
  // ============================================
  bool _isFullscreen = false;
  bool _isEnteringFullscreen = false;
  bool _isReenterDialogShowing = false;
  html.EventListener? _fullscreenChangeListener;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration * 60;
    _loadQuestions();
    _startTimer();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enforceFullscreen();
      // Nếu sau 800ms mà trình duyệt không cho tự động fullscreen, hiện hộp thoại yêu cầu người dùng bấm vào
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isFullscreen && html.document.fullscreenElement == null) {
          _showReenterFullscreenDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _cleanupFullscreenListeners();
    if (_isFullscreen) {
      try {
        html.document.exitFullscreen();
      } catch (_) {}
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
    if (_isReenterDialogShowing || !mounted || _isSubmitting) return;
    _isReenterDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.fullscreen_exit_rounded, color: Theme.of(context).colorScheme.error, size: 28),
              const SizedBox(width: 8),
              const Text('Yêu cầu toàn màn hình'),
            ],
          ),
          content: Text(
            _hasEnteredFullscreenOnce
                ? 'Bạn vừa thoát khỏi chế độ toàn màn hình.\n\nĐể đảm bảo tính công bằng và chống gian lận, bạn bắt buộc phải làm bài ở chế độ toàn màn hình.'
                : 'Bài thi yêu cầu làm trong chế độ toàn màn hình.\nVui lòng bấm nút bên dưới để bắt đầu làm bài.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _isReenterDialogShowing = false;
                _isEnteringFullscreen = true;
                try {
                  html.document.documentElement?.requestFullscreen();
                } catch (_) {
                  _isEnteringFullscreen = false;
                }
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('Vào toàn màn hình'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _isReenterDialogShowing = false;
    });
  }

  void _onFullscreenChange() {
    final isCurrentlyFullscreen = html.document.fullscreenElement != null;
    if (isCurrentlyFullscreen) {
      if (mounted) setState(() => _isFullscreen = true);
      _isEnteringFullscreen = false;
      _hasEnteredFullscreenOnce = true;
    } else if (!isCurrentlyFullscreen && !_isSubmitting && !_isLoading) {
      if (_isEnteringFullscreen) return;
      if (mounted) setState(() => _isFullscreen = false);

      // Nếu đã từng vào toàn màn hình mà người dùng bấm Esc hoặc F11 để thoát
      if (_hasEnteredFullscreenOnce) {
        _handleSuspiciousAction('Thoát chế độ toàn màn hình');
      }

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
  // LIFECYCLE LOGIC (TAB SWITCHING / MINIMIZING)
  // ============================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitting || _isLoading || _isEnteringFullscreen) {
      return;
    }
    // Chỉ bắt khi rời khỏi tab hoặc ẩn trình duyệt (không bắt inactive vì tooltip fullscreen của trình duyệt gây ra)
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      if (!_isCurrentlyAway) {
        _isCurrentlyAway = true;
        _handleSuspiciousAction('Chuyển tab hoặc rời cửa sổ bài thi');
      }
    } else if (state == AppLifecycleState.resumed) {
      _isCurrentlyAway = false;
      final isCurrentlyFullscreen = html.document.fullscreenElement != null;
      if (!isCurrentlyFullscreen && !_isSubmitting && mounted && _suspiciousActionCount < _maxSuspiciousActions) {
        _showReenterFullscreenDialog();
      }
    }
  }

  // ============================================
  // VIOLATION HANDLING
  // ============================================
  void _handleSuspiciousAction(String reason) {
    if (_isSubmitting || _isLoading || _isEnteringFullscreen) {
      return;
    }

    final now = DateTime.now();
    if (_lastFocusLossTime != null &&
        now.difference(_lastFocusLossTime!).inSeconds < 2) {
      return;
    }
    _lastFocusLossTime = now;

    setState(() => _suspiciousActionCount++);

    if (_suspiciousActionCount >= _maxSuspiciousActions) {
      _autoSubmitForCheating();
    } else if (_suspiciousActionCount == _maxSuspiciousActions - 1 &&
        !_hasShownWarning) {
      _showFinalWarning();
    } else {
      _showViolationNotification(reason);
    }
  }

  void _showViolationNotification(String reason) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cảnh báo vi phạm! Lần $_suspiciousActionCount/$_maxSuspiciousActions: $reason',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          'Bạn đã vi phạm $_suspiciousActionCount lần. Nếu tiếp tục rời màn hình bài thi, hệ thống sẽ tự động nộp bài.',
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
    _timer?.cancel();

    try {
      double score = _calculateTotalScore();
      final double score10 =
          _questions.isEmpty ? 0.0 : (score / _questions.length) * 10;
      final String formattedScore =
          score10.toStringAsFixed(score10 % 1 == 0 ? 1 : 2);
      final int timeSpent = (widget.duration * 60) - _secondsRemaining;

      await FirebaseFirestore.instance.collection('submissions').add({
        'studentId': widget.studentId,
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': timeSpent,
        'cheatingDetected': true,
        'suspiciousActionCount': _suspiciousActionCount,
        'autoSubmitted': true,
        'submissionReason':
            'Tự động nộp do vi phạm quy chế thi quá số lần quy định',
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bài thi đã tự động nộp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hệ thống tự động nộp do bạn vi phạm quy chế thi.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Điểm số đạt được',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formattedScore,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ 10 điểm',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Đóng và quay lại',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
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
    _timer?.cancel();

    try {
      double score = _calculateTotalScore();
      final double score10 =
          _questions.isEmpty ? 0.0 : (score / _questions.length) * 10;
      final String formattedScore =
          score10.toStringAsFixed(score10 % 1 == 0 ? 1 : 2);
      final int timeSpent = (widget.duration * 60) - _secondsRemaining;

      await FirebaseFirestore.instance.collection('submissions').add({
        'studentId': widget.studentId,
        'quizId': widget.quizId,
        'classId': widget.classId,
        'quizTitle': widget.quizTitle,
        'answers': _answers,
        'score': score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'timeSpent': timeSpent,
        'cheatingDetected': false,
        'suspiciousActionCount': _suspiciousActionCount,
        'autoSubmitted': false,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nộp bài thành công!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Điểm số đạt được',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formattedScore,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/ 10 điểm',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thời gian làm bài: ${_formatTime(timeSpent)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Về danh sách bài thi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
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
            if (correctList.contains(ans)) {
              questionScore += unitScore;
            } else {
              questionScore -= penaltyScore;
            }
          }
        }
        if (questionScore < 0) questionScore = 0.0;
      } else {
        // Single Choice logic
        if (rawStudent.toString() == rawCorrect.toString()) {
          questionScore = 1.0;
        }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không thể thoát khi đang làm bài!'),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                      'Câu ${_currentIndex + 1}/${_questions.length}',
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
                  child: const Text('Nộp bài'),
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
                  label: const Text('Câu trước'),
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
            label: Text(_currentIndex < _questions.length - 1 ? 'Câu tiếp theo' : 'Nộp bài'),
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
    final rawOptions = data['options'];
    final List<String> options = rawOptions is List
        ? rawOptions.map((e) => e?.toString() ?? '').toList()
        : [];
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
                            'Câu ${index + 1}',
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
                              'Nhiều đáp án',
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
                'Danh sách câu hỏi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildLegendItem(Theme.of(context).colorScheme.primary, 'Đã làm', true),
                  const SizedBox(width: 16),
                  _buildLegendItem(Theme.of(context).colorScheme.surface, 'Chưa làm', false),
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
                    'Tiến độ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '$answeredCount/${_questions.length} đã hoàn thành',
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    child: const Text('Nộp bài'),
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
