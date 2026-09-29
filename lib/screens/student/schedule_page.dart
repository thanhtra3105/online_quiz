// lib/screens/student/schedule_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/firebase_service.dart';

class ScheduleEvent {
  final String id;
  final String quizId;
  final String title;
  final String className;
  final String classId;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final int durationMinutes;
  final int questionCount;
  final bool isCompleted;
  final double? score10;
  final String status; // 'open', 'scheduled', 'completed', 'available'

  ScheduleEvent({
    required this.id,
    required this.quizId,
    required this.title,
    required this.className,
    required this.classId,
    required this.dateTime,
    this.endDateTime,
    required this.durationMinutes,
    required this.questionCount,
    required this.isCompleted,
    this.score10,
    required this.status,
  });
}

class SchedulePage extends StatefulWidget {
  final String studentId;
  final bool showTopBar;

  const SchedulePage({
    super.key,
    required this.studentId,
    this.showTopBar = true,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _focusedMonth;
  late DateTime _today;
  DateTime? _selectedDate;

  bool _isLoading = true;
  List<Map<String, dynamic>> _studentClasses = [];
  List<ScheduleEvent> _allEvents = [];

  StreamSubscription? _classesSub;
  StreamSubscription? _submissionsSub;
  StreamSubscription? _schedulesSub;

  List<Map<String, dynamic>> _cachedSubmissions = [];
  List<Map<String, dynamic>> _cachedSchedules = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(_today.year, _today.month, 1);

    _listenToData();
  }

  @override
  void dispose() {
    _classesSub?.cancel();
    _submissionsSub?.cancel();
    _schedulesSub?.cancel();
    super.dispose();
  }

  void _listenToData() {
    // 1. Lắng nghe danh sách lớp của sinh viên
    _classesSub = FirebaseService.getStudentClasses(widget.studentId).listen((classes) {
      if (!mounted) return;
      _studentClasses = classes;
      _refreshQuizzesAndEvents();
    });

    // 2. Lắng nghe bài nộp của sinh viên
    _submissionsSub = FirebaseFirestore.instance
        .collection('submissions')
        .where('studentId', isEqualTo: widget.studentId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      _cachedSubmissions = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _refreshQuizzesAndEvents();
    });

    // 3. Lắng nghe lịch thi
    _schedulesSub = FirebaseFirestore.instance
        .collection('quiz_schedules')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      _cachedSchedules = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _refreshQuizzesAndEvents();
    });
  }

  Future<void> _refreshQuizzesAndEvents() async {
    if (_studentClasses.isEmpty) {
      if (mounted) {
        setState(() {
          _allEvents = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final List<ScheduleEvent> events = [];

      // Map submissions theo quizId
      final Map<String, Map<String, dynamic>> subByQuiz = {};
      for (var sub in _cachedSubmissions) {
        final qId = (sub['quizId'] ?? '').toString();
        if (qId.isNotEmpty) {
          subByQuiz[qId] = sub;
        }
      }

      // Map schedules theo quizId
      final Map<String, Map<String, dynamic>> schedByQuiz = {};
      for (var sched in _cachedSchedules) {
        final qId = (sched['quizId'] ?? '').toString();
        if (qId.isNotEmpty) {
          schedByQuiz[qId] = sched;
        }
      }

      // Lấy danh sách quizzes trong từng lớp mà sinh viên tham gia
      for (var cls in _studentClasses) {
        final classId = cls['id']?.toString() ?? '';
        final className = cls['name']?.toString() ?? cls['title']?.toString() ?? 'Lớp học';
        if (classId.isEmpty) continue;

        final quizSnap = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('quizzes')
            .get();

        for (var qDoc in quizSnap.docs) {
          final qData = qDoc.data();
          final qId = qDoc.id;
          final title = qData['title']?.toString() ?? 'Bài kiểm tra';
          final duration = (qData['duration'] ?? 15) as int;
          final questionCount = (qData['questionCount'] ?? 10) as int;

          // Kiểm tra xem đã nộp chưa
          final hasSub = subByQuiz.containsKey(qId);
          double? score10;
          DateTime? submissionDate;
          if (hasSub) {
            final sub = subByQuiz[qId]!;
            final rawScore = (sub['score'] ?? 0).toDouble();
            final totalQ = (sub['totalQuestions'] ?? 1).toDouble();
            if (totalQ > 0) {
              score10 = (rawScore / totalQ) * 10;
            }
            if (sub['timestamp'] is Timestamp) {
              submissionDate = (sub['timestamp'] as Timestamp).toDate();
            }
          }

          // Kiểm tra lịch thi
          final sched = schedByQuiz[qId];
          DateTime eventDate;
          DateTime? closeDate;
          String status = 'available';

          if (sched != null) {
            if (sched['openTime'] is Timestamp) {
              eventDate = (sched['openTime'] as Timestamp).toDate();
            } else {
              eventDate = _today;
            }
            if (sched['closeTime'] is Timestamp) {
              closeDate = (sched['closeTime'] as Timestamp).toDate();
            }
            status = sched['status']?.toString() ?? 'scheduled';
          } else {
            // Nếu không có lịch cụ thể, lấy assignedAt hoặc ngày hôm nay
            if (qData['assignedAt'] is Timestamp) {
              eventDate = (qData['assignedAt'] as Timestamp).toDate();
            } else if (qData['createdAt'] is Timestamp) {
              eventDate = (qData['createdAt'] as Timestamp).toDate();
            } else {
              eventDate = _today;
            }
          }

          // Nếu đã nộp rồi thì ưu tiên hiển thị ngày nộp
          if (hasSub && submissionDate != null) {
            eventDate = submissionDate;
            status = 'completed';
          }

          events.add(
            ScheduleEvent(
              id: qId,
              quizId: qId,
              title: title,
              className: className,
              classId: classId,
              dateTime: eventDate,
              endDateTime: closeDate,
              durationMinutes: duration,
              questionCount: questionCount,
              isCompleted: hasSub,
              score10: score10,
              status: hasSub ? 'completed' : status,
            ),
          );
        }
      }

      // Sắp xếp các sự kiện: Sự kiện chưa làm trước, theo ngày gần nhất
      events.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.dateTime.compareTo(b.dateTime);
      });

      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Column(
        children: [
          if (widget.showTopBar) _buildTopBar(context),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppConstants.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lịch học & Thi sắp tới',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: AppConstants.txt(context),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Theo dõi thời gian mở đề, hạn nộp và các bài kiểm tra theo lớp.',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          color: AppConstants.txtMuted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Làm mới dữ liệu',
                                  icon: Icon(Icons.refresh_rounded, color: AppConstants.brand(context)),
                                  onPressed: () {
                                    setState(() => _isLoading = true);
                                    _refreshQuizzesAndEvents();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Body: 8-col events + 4-col calendar
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 720;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: _buildEventsColumn(),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 290,
                                        child: _buildCalendarWidget(),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildCalendarWidget(),
                                      const SizedBox(height: 24),
                                      _buildEventsColumn(),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined,
              color: AppConstants.brand(context), size: 24),
          const SizedBox(width: 8),
          Text(
            'Lịch trình',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.brand(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsColumn() {
    // Nếu có chọn một ngày cụ thể trên lịch
    if (_selectedDate != null) {
      final selectedEvents = _allEvents.where((e) {
        return _isSameDay(e.dateTime, _selectedDate!) ||
            (e.endDateTime != null && _isSameDay(e.endDateTime!, _selectedDate!));
      }).toList();

      final dateFormatted = DateFormat('dd/MM/yyyy').format(_selectedDate!);

      return _buildSection(
        icon: Icons.event_rounded,
        iconColor: AppConstants.brand(context),
        title: 'Sự kiện ngày $dateFormatted',
        badge: '${selectedEvents.length} mục',
        extraAction: TextButton.icon(
          onPressed: () => setState(() => _selectedDate = null),
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Xem tất cả'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: AppConstants.brand(context),
          ),
        ),
        child: selectedEvents.isEmpty
            ? _buildEmptyEvents('Không có sự kiện hoặc bài thi nào diễn ra vào ngày này.')
            : Column(
                children: selectedEvents
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildEventCard(e),
                        ))
                    .toList(),
              ),
      );
    }

    // 1. Sự kiện hôm nay hoặc đang mở chưa làm
    final todayEvents = _allEvents.where((e) {
      final isToday = _isSameDay(e.dateTime, _today);
      final isCurrentlyOpen = !e.isCompleted &&
          (e.status == 'open' || e.status == 'available');
      return isToday || isCurrentlyOpen;
    }).toList();

    // 2. Sắp tới (tương lai > hôm nay)
    final upcomingEvents = _allEvents.where((e) {
      return !e.isCompleted &&
          e.dateTime.isAfter(_today) &&
          !_isSameDay(e.dateTime, _today);
    }).toList();

    // 3. Đã hoàn thành gần đây
    final completedEvents =
        _allEvents.where((e) => e.isCompleted).take(5).toList();

    return Column(
      children: [
        // Today & Active section
        _buildSection(
          icon: Icons.today_rounded,
          iconColor: AppConstants.brand(context),
          title: 'Sự kiện hôm nay & Đang mở',
          badge: '${todayEvents.length} bài thi',
          child: todayEvents.isEmpty
              ? _buildEmptyEvents('Hôm nay bạn không có bài kiểm tra nào cần làm.')
              : Column(
                  children: todayEvents
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildEventCard(e, isHighlight: true),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 20),

        // Upcoming section
        _buildSection(
          icon: Icons.schedule_rounded,
          iconColor: const Color(0xFFD97706),
          title: 'Lịch thi sắp tới',
          badge: upcomingEvents.isNotEmpty ? '${upcomingEvents.length} kỳ thi' : null,
          child: upcomingEvents.isEmpty
              ? _buildEmptyEvents('Chưa có lịch thi nào được lên kế hoạch trong thời gian tới.')
              : Column(
                  children: upcomingEvents
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildEventCard(e),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 20),

        // Completed recently
        if (completedEvents.isNotEmpty)
          _buildSection(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppConstants.secondary,
            title: 'Đã hoàn thành gần đây',
            badge: '${completedEvents.length} bài',
            child: Column(
              children: completedEvents
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEventCard(e),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyEvents(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppConstants.surfHigh(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppConstants.txtMuted(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppConstants.txtMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    Widget? extraAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.txt(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.surfHigh(context),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txt(context),
                        ),
                      ),
                    ),
                  if (extraAction != null) extraAction,
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEventCard(ScheduleEvent event, {bool isHighlight = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(event.dateTime);
    final dateStr = DateFormat('dd/MM').format(event.dateTime);

    Color badgeBg = AppConstants.surfHigh(context);
    Color badgeColor = AppConstants.txtMuted(context);
    String statusText = 'Đang mở';

    if (event.isCompleted) {
      badgeBg = isDark ? const Color(0xFF1B382B) : const Color(0xFFD1FAE5);
      badgeColor = isDark ? const Color(0xFF81C784) : AppConstants.secondary;
      statusText = event.score10 != null
          ? 'Đã làm (${event.score10!.toStringAsFixed(1)} đ)'
          : 'Đã hoàn thành';
    } else if (event.status == 'scheduled') {
      badgeBg = isDark ? const Color(0xFF3E2D1B) : const Color(0xFFFEF3C7);
      badgeColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFD97706);
      statusText = 'Chưa mở';
    } else if (event.status == 'closed') {
      badgeBg = isDark ? const Color(0xFF3E1B1B) : AppConstants.errorContainer;
      badgeColor = isDark ? const Color(0xFFE57373) : AppConstants.error;
      statusText = 'Đã đóng';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight && !event.isCompleted
            ? AppConstants.brand(context).withValues(alpha: 0.08)
            : AppConstants.surf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight && !event.isCompleted
              ? AppConstants.brand(context).withValues(alpha: 0.4)
              : AppConstants.border(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time badge
          Container(
            width: 64,
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppConstants.border(context))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  timeStr != '00:00' ? timeStr : '--:--',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isHighlight && !event.isCompleted
                        ? AppConstants.brand(context)
                        : AppConstants.txt(context),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lớp: ${event.className} • ${event.durationMinutes} phút • ${event.questionCount} câu hỏi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
                if (event.endDateTime != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Hạn chót: ${DateFormat('HH:mm - dd/MM/yyyy').format(event.endDateTime!)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildTag(event.className, AppConstants.surfHigh(context),
                        AppConstants.txtMuted(context)),
                    _buildTag(statusText, badgeBg, badgeColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final firstDayOfMonth = _focusedMonth;
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    // Weekday: 1=Mon, 7=Sun. Grid starts Monday
    int startOffset = firstDayOfMonth.weekday - 1;

    // Lập map các ngày có sự kiện trong tháng
    final Map<int, List<ScheduleEvent>> daysEventsMap = {};
    for (var event in _allEvents) {
      if (event.dateTime.year == _focusedMonth.year &&
          event.dateTime.month == _focusedMonth.month) {
        final d = event.dateTime.day;
        daysEventsMap[d] = (daysEventsMap[d] ?? [])..add(event);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthLabel(_focusedMonth),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                ),
              ),
              Row(
                children: [
                  _calNavBtn(Icons.chevron_left_rounded, () {
                    setState(() {
                      _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month - 1, 1);
                    });
                  }),
                  const SizedBox(width: 4),
                  _calNavBtn(Icons.chevron_right_rounded, () {
                    setState(() {
                      _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month + 1, 1);
                    });
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Day headers
          Row(
            children: daysOfWeek
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + lastDayOfMonth.day,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isToday = _isSameDay(_today, cellDate);
              final isSelected = _selectedDate != null && _isSameDay(_selectedDate!, cellDate);

              final dayEvents = daysEventsMap[day] ?? [];
              final hasEvents = dayEvents.isNotEmpty;
              final hasUncompleted = dayEvents.any((e) => !e.isCompleted);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDate = null;
                    } else {
                      _selectedDate = cellDate;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.brand(context)
                        : (isToday
                            ? AppConstants.brand(context).withValues(alpha: 0.16)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppConstants.brand(context), width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? AppConstants.brand(context)
                                  : AppConstants.txt(context)),
                        ),
                      ),
                      if (hasEvents)
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : (hasUncompleted
                                      ? const Color(0xFFD97706)
                                      : AppConstants.secondary),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: AppConstants.border(context)),
          const SizedBox(height: 10),
          // Legend
          _buildLegendItem(AppConstants.brand(context), 'Hôm nay'),
          const SizedBox(height: 6),
          _buildLegendItem(const Color(0xFFD97706), 'Bài kiểm tra / Kỳ thi'),
          const SizedBox(height: 6),
          _buildLegendItem(AppConstants.secondary, 'Đã hoàn thành'),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: AppConstants.txtMuted(context)),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppConstants.txtMuted(context),
          ),
        ),
      ],
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];
    return '${months[dt.month]}, ${dt.year}';
  }
}
