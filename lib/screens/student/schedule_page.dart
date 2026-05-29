// lib/screens/student/schedule_page.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SchedulePage extends StatefulWidget {
  final String studentId;
  const SchedulePage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _focusedMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedMonth = DateTime(_today.year, _today.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Header
                      const Text(
                        'Lịch học & Thi sắp tới',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Quản lý lịch trình ôn tập và các kỳ thi quan trọng của bạn.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppConstants.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Body: 8-col events + 4-col calendar
                      LayoutBuilder(builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 640;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 8, child: _buildEventsColumn()),
                              const SizedBox(width: 24),
                              SizedBox(width: 260, child: _buildCalendarWidget()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildEventsColumn(),
                              const SizedBox(height: 24),
                              _buildCalendarWidget(),
                            ],
                          );
                        }
                      }),
                      const SizedBox(height: 32),
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
      decoration: const BoxDecoration(
        color: AppConstants.surface,
        border: Border(bottom: BorderSide(color: AppConstants.outlineVariant)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded, color: AppConstants.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.calendar_month_outlined, color: AppConstants.primary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Lịch trình',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsColumn() {
    return Column(
      children: [
        // Today's Events
        _buildSection(
          icon: Icons.today_outlined,
          iconColor: AppConstants.primary,
          title: 'Sự kiện hôm nay',
          badge: '2 sự kiện',
          child: Column(
            children: [
              _buildEventCard(
                time: '09:00',
                period: 'Sáng',
                title: 'Thi thử: Toán Cao Cấp A1',
                desc: 'Kỳ thi giữa kỳ mô phỏng. Thời gian: 90 phút.',
                tags: ['Phòng thi ảo 01'],
                urgentTag: 'Bắt buộc',
                isHighlight: true,
              ),
              const SizedBox(height: 12),
              _buildEventCard(
                time: '14:30',
                period: 'Chiều',
                title: 'Ôn tập nhóm: Lịch sử Đảng',
                desc: 'Thảo luận chuyên đề 3 & 4.',
                tags: ['Online Meet'],
                urgentTag: null,
                isHighlight: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // This Week
        _buildSection(
          icon: Icons.view_week_outlined,
          iconColor: AppConstants.secondary,
          title: 'Sắp tới trong tuần',
          badge: null,
          child: _buildTimeline(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
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
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.onSurface,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String time,
    required String period,
    required String title,
    required String desc,
    required List<String> tags,
    String? urgentTag,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight ? AppConstants.surfaceContainerLow : AppConstants.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? AppConstants.primary.withValues(alpha: 0.4) : AppConstants.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Container(
            width: 60,
            padding: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppConstants.outlineVariant)),
            ),
            child: Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isHighlight ? AppConstants.primary : AppConstants.onSurface,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppConstants.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ...tags.map((t) => _buildTag(t, AppConstants.surfaceContainerHigh, AppConstants.onSurfaceVariant)),
                    if (urgentTag != null)
                      _buildTag(urgentTag, AppConstants.errorContainer, AppConstants.error),
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

  Widget _buildTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          dateLabel: 'Thứ Tư, ${_getDateStr(3)}',
          dateColor: AppConstants.secondary,
          dotColor: AppConstants.secondary,
          title: 'Nộp bài tập lớn C++',
          desc: 'Hạn chót lúc 23:59. Đảm bảo commit code lên Git.',
          isUrgent: false,
        ),
        const SizedBox(height: 20),
        _buildTimelineItem(
          dateLabel: 'Thứ Sáu, ${_getDateStr(5)}',
          dateColor: AppConstants.error,
          dotColor: AppConstants.error,
          title: 'Thi Cuối Kỳ: Tiếng Anh B2',
          desc: 'Kỳ thi quan trọng - 120 phút',
          isUrgent: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String dateLabel,
    required Color dateColor,
    required Color dotColor,
    required String title,
    required String desc,
    required bool isUrgent,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppConstants.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 2),
                ),
              ),
              Expanded(
                child: Container(width: 2, color: AppConstants.outlineVariant),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: dateColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? AppConstants.errorContainer.withValues(alpha: 0.25)
                          : AppConstants.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUrgent
                            ? AppConstants.errorContainer
                            : AppConstants.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isUrgent)
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 14, color: AppConstants.error),
                              const SizedBox(width: 4),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppConstants.error,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            desc,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppConstants.onSurfaceVariant,
                            ),
                          ),
                      ],
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

  Widget _buildCalendarWidget() {
    final daysOfWeek = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final firstDayOfMonth = _focusedMonth;
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    // Weekday: 1=Mon, 7=Sun. Grid starts Monday
    int startOffset = firstDayOfMonth.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthLabel(_focusedMonth),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.onSurface,
                ),
              ),
              Row(
                children: [
                  _calNavBtn(Icons.chevron_left, () {
                    setState(() {
                      _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month - 1, 1);
                    });
                  }),
                  const SizedBox(width: 4),
                  _calNavBtn(Icons.chevron_right, () {
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
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.onSurfaceVariant,
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
              final isToday = _today.year == _focusedMonth.year &&
                  _today.month == _focusedMonth.month &&
                  _today.day == day;
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? AppConstants.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                      color: isToday
                          ? Colors.white
                          : AppConstants.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: AppConstants.outlineVariant),
          const SizedBox(height: 12),
          // Legend
          _buildLegendItem(AppConstants.primary, 'Hôm nay'),
          const SizedBox(height: 6),
          _buildLegendItem(AppConstants.secondary, 'Bài tập / Tiểu luận'),
          const SizedBox(height: 6),
          _buildLegendItem(AppConstants.error, 'Kỳ thi quan trọng'),
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
        child: Icon(icon, size: 20, color: AppConstants.onSurfaceVariant),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return '${months[dt.month]}, ${dt.year}';
  }

  String _getDateStr(int weekday) {
    final now = DateTime.now();
    final diff = weekday - now.weekday;
    final target = now.add(Duration(days: diff < 0 ? diff + 7 : diff));
    return '${target.day}/${target.month}';
  }
}
