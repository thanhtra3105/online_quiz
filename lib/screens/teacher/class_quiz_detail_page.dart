// lib/screens/teacher/class_quiz_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_quiz_page.dart';
import 'quiz_schedule_dialog.dart';
import '../../services/quiz_schedule_service.dart';
import '../../models/quiz_schedule_model.dart';
import '../../utils/constants.dart';
import '../../widgets/question_image_view.dart';

class ClassQuizDetailPage extends StatefulWidget {
  final String? classId;
  final String quizId;
  final Map<String, dynamic> quizData;
  final String? className;

  const ClassQuizDetailPage({
    super.key,
    this.classId,
    required this.quizId,
    required this.quizData,
    this.className,
  });

  @override
  State<ClassQuizDetailPage> createState() => _ClassQuizDetailPageState();
}

class _ClassQuizDetailPageState extends State<ClassQuizDetailPage> {
  QuizSchedule? _currentSchedule;
  bool _isLoadingSchedule = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    if (widget.classId == null || widget.classId!.isEmpty) {
      if (mounted) {
        setState(() {
          _currentSchedule = null;
          _isLoadingSchedule = false;
        });
      }
      return;
    }
    try {
      final schedule = await QuizScheduleService.getSchedule(
        widget.classId!,
        widget.quizId,
      );
      if (mounted) {
        setState(() {
          _currentSchedule = schedule;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchedule = false);
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar đồng bộ breadcrumbs
            _buildTopAppBar(),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card & Info
                          _buildHeaderCard(),
                          const SizedBox(height: 20),

                          // Bento Stats
                          _buildBentoStats(),
                          const SizedBox(height: 20),

                          // Schedule Banner (nếu có)
                          if (!_isLoadingSchedule && _currentSchedule != null) ...[
                            _buildScheduleBanner(_currentSchedule!),
                            const SizedBox(height: 24),
                          ],

                          // Questions List
                          _buildQuestionsSection(),
                        ],
                      ),
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
    final bool hasClass = widget.classId != null && widget.classId!.isNotEmpty;
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Breadcrumbs
              if (hasClass) ...[
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 16, color: AppConstants.txtMuted(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Lớp học',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.txtMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: AppConstants.border(context)),
                const SizedBox(width: 2),
                Tooltip(
                  message: 'Quay lại Chi tiết lớp',
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        widget.className != null && widget.className!.isNotEmpty
                            ? widget.className!
                            : 'Chi tiết lớp',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Tooltip(
                  message: 'Quay lại Bài thi',
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 16, color: AppConstants.txtMuted(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Bài thi',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.txtMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppConstants.border(context)),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                ),
                child: Text(
                  'Chi tiết đề thi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.brand(context),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Action Buttons
              OutlinedButton.icon(
                onPressed: () => _manageSchedule(context),
                icon: Icon(Icons.calendar_month_rounded, size: 15, color: AppConstants.brand(context)),
                label: Text(
                  'Lên lịch',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.brand(context)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE)),
                  backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _editQuiz(context),
                icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFFD97706)),
                label: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFFDE68A)),
                  backgroundColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
      child: Row(
        children: [
          // Breadcrumbs
          if (hasClass) ...[
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
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.txtMuted(context),
                        ),
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
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    widget.className != null && widget.className!.isNotEmpty
                        ? widget.className!
                        : 'Chi tiết lớp',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.txtMuted(context),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Tooltip(
              message: 'Quay lại Bài thi',
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
                        'Bài thi',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.border(context)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
            ),
            child: Text(
              'Chi tiết đề thi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppConstants.brand(context),
              ),
            ),
          ),
          const Spacer(),
          // Action Buttons
          OutlinedButton.icon(
            onPressed: () => _manageSchedule(context),
            icon: Icon(Icons.calendar_month_rounded, size: 16, color: AppConstants.brand(context)),
            label: Text(
              'Lên lịch',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.brand(context)),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE)),
              backgroundColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _editQuiz(context),
            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFD97706)),
            label: const Text(
              'Chỉnh sửa',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? AppConstants.border(context) : const Color(0xFFFDE68A)),
              backgroundColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
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

  Widget _buildHeaderCard() {
    final title = widget.quizData['title'] ?? 'Chi tiết bài thi';
    final qCount = widget.quizData['questionCount'] ?? 0;
    final duration = widget.quizData['duration'] ?? 0;
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: AppConstants.brand(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.assignment_rounded, color: AppConstants.brand(context), size: isMobile ? 26 : 32),
          ),
          SizedBox(width: isMobile ? 14 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.txt(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusPill(),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusPill(),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '$qCount câu hỏi • Thời lượng: $duration phút${(widget.className != null && widget.className!.isNotEmpty) ? ' • Lớp: ${widget.className}' : ''}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    if (_isLoadingSchedule) {
      return const SizedBox.shrink();
    }

    String label = 'Đang khả dụng';
    Color bgColor = const Color(0xFFF1F5F9);
    Color textColor = const Color(0xFF475569);
    Color dotColor = const Color(0xFF94A3B8);

    if (_currentSchedule != null) {
      if (_currentSchedule!.isClosed) {
        label = 'Đã đóng';
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        dotColor = const Color(0xFFEF4444);
      } else if (_currentSchedule!.isOpen) {
        label = 'Đang mở';
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF059669);
        dotColor = const Color(0xFF10B981);
      } else {
        label = 'Đã lên lịch';
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        dotColor = const Color(0xFFF59E0B);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStats() {
    final qCount = widget.quizData['questionCount'] ?? 0;
    final duration = widget.quizData['duration'] ?? 0;

    String statusText = 'Khả dụng';
    if (_currentSchedule != null) {
      if (_currentSchedule!.isClosed) {
        statusText = 'Đã đóng';
      } else if (_currentSchedule!.isOpen) {
        statusText = 'Đang mở';
      } else {
        statusText = 'Đã lên lịch';
      }
    }

    final isMobile = MediaQuery.of(context).size.width < 768;

    final card1 = _buildBentoStatCard(
      title: 'Tổng số câu hỏi',
      value: '$qCount câu hỏi',
      icon: Icons.quiz_outlined,
      iconColor: const Color(0xFF003D9B),
      iconBg: const Color(0xFFEFF6FF),
    );
    final card2 = _buildBentoStatCard(
      title: 'Thời gian làm bài',
      value: '$duration phút',
      icon: Icons.timer_outlined,
      iconColor: const Color(0xFF0284C7),
      iconBg: const Color(0xFFF0F9FF),
    );
    final card3 = _buildBentoStatCard(
      title: 'Trạng thái phòng thi',
      value: statusText,
      icon: Icons.event_available_rounded,
      iconColor: const Color(0xFF16A34A),
      iconBg: const Color(0xFFECFDF5),
    );

    if (isMobile) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: card1),
        const SizedBox(width: 16),
        Expanded(child: card2),
        const SizedBox(width: 16),
        Expanded(child: card3),
      ],
    );
  }

  Widget _buildBentoStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: isMobile ? 14 : 20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfHigh(context) : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.txtMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleBanner(QuizSchedule schedule) {
    Color bannerColor;
    Color bgColor;
    IconData bannerIcon;
    String bannerText;
    List<String> details = [];

    if (schedule.isClosed) {
      bannerColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
      bannerIcon = Icons.lock_outline_rounded;
      bannerText = 'Đề thi hiện đang đóng';
      if (schedule.closeTime != null) {
        details.add('Đóng lúc: ${_formatDateTime(schedule.closeTime!)}');
      }
    } else if (schedule.isOpen) {
      bannerColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFF0FDF4);
      bannerIcon = Icons.lock_open_rounded;
      bannerText = 'Đề thi đang mở cho học sinh làm bài';
      if (schedule.closeTime != null) {
        details.add('Dự kiến đóng lúc: ${_formatDateTime(schedule.closeTime!)}');
      }
    } else {
      bannerColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      bannerIcon = Icons.schedule_rounded;
      bannerText = 'Đề thi đã lên lịch mở tự động';
      if (schedule.openTime != null) {
        details.add('Mở lúc: ${_formatDateTime(schedule.openTime!)}');
      }
      if (schedule.closeTime != null) {
        details.add('Đóng lúc: ${_formatDateTime(schedule.closeTime!)}');
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bannerText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quick action buttons
              if (schedule.isScheduled)
                FilledButton.icon(
                  onPressed: () => _openQuizNow(schedule),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Mở ngay', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (schedule.isOpen)
                FilledButton.icon(
                  onPressed: () => _closeQuizNow(schedule),
                  icon: const Icon(Icons.lock_rounded, size: 16),
                  label: const Text('Đóng ngay', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: bannerColor),
                    const SizedBox(width: 6),
                    Text(
                      detail,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: bannerColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    final isDark = AppConstants.isDarkMode(context);

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('quiz')
          .doc(widget.quizId)
          .collection('questions')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context)),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12),
                  const Text(
                    'Không thể tải câu hỏi',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context))),
                ],
              ),
            ),
          );
        }

        final questions = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
        questions.sort((a, b) {
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

        if (questions.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.border(context)),
              ),
              child: Column(
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: AppConstants.txtMuted(context)),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có câu hỏi nào trong đề thi này',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppConstants.txtMuted(context)),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
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
                  child: Icon(Icons.format_list_bulleted_rounded, color: AppConstants.brand(context), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Danh sách câu hỏi (${questions.length})',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.txt(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final questionDoc = questions[index];
                final questionData = (questionDoc.data() as Map<String, dynamic>?) ?? {};
                final options = List<String>.from(questionData['options'] ?? []);
                final rawCorrect = questionData['correctAnswer'];

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppConstants.surf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.border(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question badge & number
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Question text
                      Text(
                        questionData['question'] ?? '',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txt(context),
                          height: 1.5,
                        ),
                      ),
                      () {
                        List<String> imgs = [];
                        if (questionData['imageUrls'] is List) {
                          imgs = (questionData['imageUrls'] as List)
                              .map((e) => e.toString().trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                        } else if (questionData['imageUrl'] != null &&
                            questionData['imageUrl'].toString().trim().isNotEmpty) {
                          imgs = [questionData['imageUrl'].toString().trim()];
                        }
                        if (imgs.isNotEmpty) {
                          return QuestionImageView(
                            imageUrls: imgs,
                            maxHeight: 280,
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
                      const SizedBox(height: 16),

                      // Options
                      ...options.asMap().entries.map((optEntry) {
                        final letter = String.fromCharCode(65 + optEntry.key);
                        bool isCorrect = false;

                        if (rawCorrect is List) {
                          isCorrect = rawCorrect.map((e) => e.toString()).contains(letter);
                        } else {
                          isCorrect = rawCorrect.toString() == letter;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
                                : AppConstants.surfLow(context),
                            border: Border.all(
                              color: isCorrect
                                  ? (isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC))
                                  : AppConstants.border(context),
                              width: isCorrect ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? const Color(0xFF16A34A)
                                      : (isDark ? AppConstants.surfHigh(context) : const Color(0xFFE2E8F0)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? Colors.white : AppConstants.txt(context),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optEntry.value,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                                    color: isCorrect
                                        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                        : AppConstants.txt(context),
                                  ),
                                ),
                              ),
                              if (isCorrect)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 20,
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _manageSchedule(BuildContext context) async {
    String? targetClassId = widget.classId;
    if (targetClassId == null || targetClassId.isEmpty) {
      // Pick a class first
      final user = FirebaseAuth.instance.currentUser;
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: user?.uid)
          .get();

      if (!context.mounted) return;
      if (classesSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bạn chưa có lớp học nào để lên lịch thi'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      targetClassId = await showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppConstants.surf(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppConstants.border(ctx)),
          ),
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 560),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.surf(ctx),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppConstants.brand(ctx).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school_rounded, color: AppConstants.brand(ctx), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn lớp học để lên lịch',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppConstants.txt(ctx),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chọn lớp học phần bạn muốn áp dụng lịch thi',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppConstants.txtMuted(ctx),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(ctx), size: 20),
                      onPressed: () => Navigator.pop(ctx, null),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: classesSnapshot.docs.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = classesSnapshot.docs[index];
                      final cData = doc.data();
                      final cName = cData['name'] ?? 'Lớp không tên';
                      final cCode = (cData['classCode'] ?? cData['code'] ?? cData['courseCode'] ?? cData['description'] ?? '').toString().trim();
                      final room = (cData['room'] ?? '').toString().trim();
                      final period = (cData['period'] ?? '').toString().trim();

                      return InkWell(
                        onTap: () => Navigator.pop(ctx, doc.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConstants.surfLow(ctx),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.border(ctx)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppConstants.brand(ctx).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.menu_book_rounded, color: AppConstants.brand(ctx), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cName,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppConstants.txt(ctx),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (cCode.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: AppConstants.brand(ctx).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Mã: $cCode',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppConstants.brand(ctx),
                                              ),
                                            ),
                                          ),
                                        if (room.isNotEmpty || period.isNotEmpty)
                                          Text(
                                            [
                                              if (room.isNotEmpty) 'Phòng $room',
                                              if (period.isNotEmpty) period,
                                            ].join(' • '),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: AppConstants.txtMuted(ctx),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppConstants.txtMuted(ctx), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppConstants.border(ctx)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Hủy', style: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(ctx))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (targetClassId == null) return;
    }

    final schedule = await QuizScheduleService.getSchedule(
      targetClassId,
      widget.quizId,
    );

    if (!context.mounted) return;

    final result = await showDialog(
      context: context,
      builder: (context) => QuizScheduleDialog(
        classId: targetClassId!,
        quizId: widget.quizId,
        quizTitle: widget.quizData['title'] ?? 'Đề thi',
        existingSchedule: schedule,
      ),
    );

    if (result == true) {
      if (widget.classId == null || widget.classId!.isEmpty) {
        final newSchedule = await QuizScheduleService.getSchedule(targetClassId, widget.quizId);
        if (mounted) {
          setState(() {
            _currentSchedule = newSchedule;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Đã gán đề thi và thiết lập lịch cho lớp học thành công!'),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        await _loadSchedule();
      }
    }
  }

  Future<void> _openQuizNow(QuizSchedule schedule) async {
    if (widget.classId == null) return;
    try {
      await QuizScheduleService.openQuizNow(widget.classId!, widget.quizId);
      await _loadSchedule();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã mở đề thi thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _closeQuizNow(QuizSchedule schedule) async {
    if (widget.classId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đóng đề thi', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đóng đề thi này ngay lập tức không? Học sinh sẽ không thể làm bài tiếp.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Đóng ngay'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await QuizScheduleService.closeQuizNow(widget.classId!, widget.quizId);
      await _loadSchedule();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã đóng đề thi thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _editQuiz(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuizPage(
          quizId: widget.quizId,
          quizData: widget.quizData,
          className: widget.className,
          classId: widget.classId,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Đề thi đã được cập nhật thành công'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      final doc = await FirebaseFirestore.instance.collection('quiz').doc(widget.quizId).get();
      final freshData = doc.data() ?? widget.quizData;

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClassQuizDetailPage(
            classId: widget.classId,
            quizId: widget.quizId,
            quizData: freshData,
            className: widget.className,
          ),
        ),
      );
    }
  }
}
