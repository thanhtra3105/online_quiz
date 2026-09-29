// lib/screens/student/quiz_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/quiz_schedule_service.dart';
import '../../models/quiz_schedule_model.dart';
import '../../utils/constants.dart';
import 'quiz_taking_page.dart';

class QuizListPage extends StatefulWidget {
  final String studentId;
  final String classId;
  final String? className;

  const QuizListPage({
    Key? key,
    required this.studentId,
    required this.classId,
    this.className,
  }) : super(key: key);

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  String _selectedFilter = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getClassQuizzes(widget.classId),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.hasError) {
          return _buildErrorWidget(quizSnapshot.error);
        }

        if (!quizSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.getStudentClassSubmissions(
            widget.studentId,
            widget.classId,
          ),
          builder: (context, submissionSnapshot) {
            if (!submissionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final completedQuizIds = submissionSnapshot.data!.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['quizId']?.toString();
                })
                .where((id) => id != null && id.isNotEmpty)
                .cast<String>()
                .toSet();

            // Lọc quiz: chưa hoàn thành
            final availableQuizzes = quizSnapshot.data!.docs
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .toList();

            // Thu thập các môn học / chủ đề có trong bài thi của lớp
            final detectedSubjects = <String>{};
            for (var quiz in availableQuizzes) {
              final data = quiz.data() as Map<String, dynamic>;
              final rawSub = data['subject'] ?? data['category'] ?? data['topic'];
              if (rawSub != null) {
                final sub = rawSub.toString().trim();
                if (sub.isNotEmpty) {
                  detectedSubjects.add(sub);
                }
              }
            }

            // Danh sách bộ lọc phù hợp với học sinh / sinh viên
            final List<String> filterList = [
              'Tất cả',
              'Đang mở',
              if (detectedSubjects.isNotEmpty)
                ...detectedSubjects
              else ...[
                'Toán học',
                'Tin học',
                'Tiếng Anh',
                'Khoa học',
              ],
            ];

            // Nếu bộ lọc hiện tại không còn trong danh sách, đặt lại về 'Tất cả'
            if (!filterList.contains(_selectedFilter)) {
              _selectedFilter = 'Tất cả';
            }

            // Áp dụng bộ lọc và từ khóa tìm kiếm cho danh sách bài thi
            final filteredQuizzes = availableQuizzes.where((quiz) {
              final data = quiz.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();

              // Lọc theo từ khóa tìm kiếm
              if (_searchQuery.trim().isNotEmpty) {
                final query = _searchQuery.toLowerCase().trim();
                if (!title.contains(query)) {
                  return false;
                }
              }

              if (_selectedFilter == 'Tất cả') return true;

              final rawSub = data['subject'] ?? data['category'] ?? data['topic'];
              final sub = rawSub != null ? rawSub.toString().toLowerCase().trim() : '';

              if (_selectedFilter == 'Đang mở') {
                return data['status'] == null ||
                    data['status'] == 'available' ||
                    data['status'] == 'open';
              }

              if (_selectedFilter == 'Toán học') {
                return sub.contains('toán') ||
                    title.contains('toán') ||
                    title.contains('math');
              }

              if (_selectedFilter == 'Tin học') {
                return sub.contains('tin') ||
                    sub.contains('lập trình') ||
                    title.contains('tin') ||
                    title.contains('lập trình') ||
                    title.contains('code') ||
                    title.contains('cntt') ||
                    title.contains('web') ||
                    title.contains('python') ||
                    title.contains('java');
              }

              if (_selectedFilter == 'Tiếng Anh') {
                return sub.contains('anh') ||
                    sub.contains('english') ||
                    title.contains('anh') ||
                    title.contains('english');
              }

              if (_selectedFilter == 'Khoa học') {
                return sub.contains('khoa học') ||
                    sub.contains('lý') ||
                    sub.contains('hóa') ||
                    sub.contains('sinh') ||
                    title.contains('khoa học') ||
                    title.contains('vật lý') ||
                    title.contains('hóa học') ||
                    title.contains('sinh học') ||
                    title.contains('lý') ||
                    title.contains('hóa') ||
                    title.contains('sinh');
              }

              return sub == _selectedFilter.toLowerCase() ||
                  title.contains(_selectedFilter.toLowerCase());
            }).toList();

            return Container(
              color: AppConstants.bg(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner tên lớp học
                    _buildClassBanner(context),

                    // Tiêu đề trang & Mô tả
                    Text(
                      'Danh sách bài thi',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppConstants.txt(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xem và chọn các bài kiểm tra, bài thi của lớp để luyện tập và hoàn thành.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppConstants.txtMuted(context),
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Thanh tìm kiếm bài thi
                    Container(
                      decoration: BoxDecoration(
                        color: AppConstants.surf(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.border(context)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppConstants.txt(context),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài thi theo tên...',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppConstants.txtMuted(context),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppConstants.txtMuted(context),
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, size: 18, color: AppConstants.txtMuted(context)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thanh bộ lọc môn học / trạng thái
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterList.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return _buildFilterChip(
                            context,
                            filter,
                            isSelected,
                            () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (availableQuizzes.isEmpty)
                      _buildEmptyState(context)
                    else if (filteredQuizzes.isEmpty)
                      _buildFilterEmptyState(context)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 1200
                              ? 3
                              : constraints.maxWidth > 800
                                  ? 2
                                  : 1;
                          final cardWidth =
                              (constraints.maxWidth - (crossAxisCount - 1) * 24) /
                                  crossAxisCount;

                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: filteredQuizzes.map((quiz) {
                              final quizId = quiz.id;
                              final data = quiz.data() as Map<String, dynamic>;

                              return FutureBuilder<QuizSchedule?>(
                                future: QuizScheduleService.getSchedule(
                                    widget.classId, quizId),
                                builder: (context, scheduleSnapshot) {
                                  if (scheduleSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: _buildLoadingCard(context),
                                    );
                                  }

                                  final schedule = scheduleSnapshot.data;
                                  final canTake = _checkCanTakeQuiz(schedule);
                                  final statusInfo = _getStatusInfo(schedule);

                                  // Không hiển thị nếu bài thi đã đóng
                                  if (schedule != null && schedule.isClosed) {
                                    return const SizedBox.shrink();
                                  }

                                  return SizedBox(
                                    width: cardWidth,
                                    child: _buildQuizCard(
                                      context,
                                      quizId,
                                      data,
                                      canTake,
                                      statusInfo,
                                      schedule,
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassBanner(BuildContext context) {
    final name = widget.className?.isNotEmpty == true ? widget.className! : 'Lớp học';
    final brandColor = AppConstants.brand(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.school_rounded, color: brandColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppConstants.txt(context),
                ),
                children: [
                  TextSpan(
                    text: 'Bạn đang ở lớp học: ',
                    style: TextStyle(color: AppConstants.txtMuted(context)),
                  ),
                  TextSpan(
                    text: name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.brand(context)
                  : AppConstants.surfContainer(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppConstants.brand(context)
                    : AppConstants.border(context),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isSelected ? Colors.white : AppConstants.txt(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.brand(context).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 64,
                color: AppConstants.brand(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bạn đã hoàn thành tất cả bài thi!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hiện tại không có bài thi nào mới dành cho bạn trong lớp này.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppConstants.txtMuted(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(BuildContext context) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    final message = isSearching
        ? 'Không tìm thấy bài thi nào phù hợp với từ khóa "$_searchQuery".'
        : 'Không có bài thi nào phù hợp với bộ lọc "$_selectedFilter".';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surfHigh(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.filter_list_off_rounded,
                size: 48,
                color: AppConstants.txtMuted(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy bài thi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.txtMuted(context),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedFilter = 'Tất cả';
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Xem tất cả bài thi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    BuildContext context,
    String quizId,
    Map<String, dynamic> data,
    bool canTake,
    Map<String, dynamic> statusInfo,
    QuizSchedule? schedule,
  ) {
    final Color statusColor = (statusInfo['color'] as Color?) ?? Colors.grey;
    final String statusText = (statusInfo['text']?.toString()) ?? 'Chưa xác định';

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canTake
              ? AppConstants.border(context)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.surfHigh(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BÀI THI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppConstants.txtMuted(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(
                Icons.assignment_outlined,
                color: AppConstants.txtMuted(context),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['title'] ?? 'Bài thi chưa được đặt tên',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppConstants.txt(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Bài kiểm tra đánh giá kiến thức.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppConstants.txtMuted(context),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppConstants.border(context),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted,
                      size: 16,
                      color: AppConstants.txtMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data['questionCount'] ?? 0} câu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppConstants.txtMuted(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppConstants.txtMuted(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data['duration'] ?? 0} phút',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppConstants.txtMuted(context),
                      ),
                    ),
                  ],
                ),
                canTake
                    ? TextButton(
                        onPressed: () => _startQuiz(context, quizId, data),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Bắt đầu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppConstants.brand(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LOGIC KIỂM TRA SCHEDULE
  // ============================================

  bool _checkCanTakeQuiz(QuizSchedule? schedule) {
    if (schedule == null) return true;
    final now = DateTime.now();
    if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
      return false;
    }
    if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
      return false;
    }
    return schedule.status == 'open';
  }

  Map<String, dynamic> _getStatusInfo(QuizSchedule? schedule) {
    if (schedule == null) {
      return {
        'text': 'Sẵn sàng',
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      };
    }

    final now = DateTime.now();

    if (schedule.closeTime != null && now.isAfter(schedule.closeTime!)) {
      return {'text': 'Đã đóng', 'color': Colors.red, 'icon': Icons.lock};
    }

    if (schedule.openTime != null && now.isBefore(schedule.openTime!)) {
      final timeUntil = schedule.openTime!.difference(now);
      String timeText;
      if (timeUntil.inDays > 0) {
        timeText = 'Mở sau ${timeUntil.inDays} ngày';
      } else if (timeUntil.inHours > 0) {
        timeText = 'Mở sau ${timeUntil.inHours} giờ';
      } else {
        final minutes = (timeUntil.inSeconds / 60).ceil();
        timeText = 'Mở sau $minutes phút';
      }
      return {'text': timeText, 'color': Colors.orange, 'icon': Icons.schedule};
    }

    if (schedule.status == 'open') {
      if (schedule.closeTime != null) {
        final timeLeft = schedule.closeTime!.difference(now);
        String timeText;
        if (timeLeft.inDays > 0) {
          timeText = 'Còn ${timeLeft.inDays} ngày';
        } else if (timeLeft.inHours > 0) {
          timeText = 'Còn ${timeLeft.inHours} giờ';
        } else {
          final minutes = (timeLeft.inSeconds / 60).ceil();
          timeText = 'Còn $minutes phút';
        }
        return {
          'text': timeText,
          'color': Colors.green,
          'icon': Icons.lock_open,
        };
      }

      return {
        'text': 'Đang mở',
        'color': Colors.green,
        'icon': Icons.lock_open,
      };
    }

    return {
      'text': 'Đã lên lịch',
      'color': Colors.orange,
      'icon': Icons.schedule,
    };
  }

  // ============================================
  // BẮT ĐẦU LÀM BÀI
  // ============================================

  Future<void> _startQuiz(
    BuildContext context,
    String quizId,
    Map<String, dynamic> data,
  ) async {
    final canTake = await QuizScheduleService.canTakeQuiz(widget.classId, quizId);

    if (!canTake) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Bài thi chưa mở hoặc đã đóng'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTakingPage(
          quizId: quizId,
          classId: widget.classId,
          quizTitle: data['title'] ?? 'Bài thi',
          duration: data['duration'] ?? 30,
          studentId: widget.studentId,
        ),
      ),
    );
  }

  // ============================================
  // UI HELPERS
  // ============================================

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppConstants.brand(context),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Lỗi: $error', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
