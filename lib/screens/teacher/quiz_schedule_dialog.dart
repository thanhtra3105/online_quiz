// lib/screens/teacher/quiz_schedule_dialog.dart
import 'package:flutter/material.dart';
import '../../models/quiz_schedule_model.dart';
import '../../services/quiz_schedule_service.dart';
import '../../utils/constants.dart';

class QuizScheduleDialog extends StatefulWidget {
  final String classId;
  final String quizId;
  final String quizTitle;
  final QuizSchedule? existingSchedule;

  const QuizScheduleDialog({
    super.key,
    required this.classId,
    required this.quizId,
    required this.quizTitle,
    this.existingSchedule,
  });

  @override
  State<QuizScheduleDialog> createState() => _QuizScheduleDialogState();
}

class _QuizScheduleDialogState extends State<QuizScheduleDialog> {
  DateTime? _openTime;
  DateTime? _closeTime;
  bool _autoOpen = true;
  bool _autoClose = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _openTime = widget.existingSchedule!.openTime;
      _closeTime = widget.existingSchedule!.closeTime;
      _autoOpen = widget.existingSchedule!.autoOpen;
      _autoClose = widget.existingSchedule!.autoClose;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppConstants.border(context)),
      ),
      backgroundColor: AppConstants.surf(context),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                border: Border(bottom: BorderSide(color: AppConstants.border(context))),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: AppConstants.brand(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lên lịch đề thi',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.quizTitle,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppConstants.txtMuted(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppConstants.txtMuted(context), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Open Time Section
                    _buildSectionTitle('Thời gian mở đề thi', Icons.lock_open_rounded),
                    const SizedBox(height: 10),
                    _buildTimeCard(
                      label: 'Thời gian mở',
                      time: _openTime,
                      onTap: () => _selectDateTime(true),
                      onClear: () => setState(() => _openTime = null),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _autoOpen,
                      onChanged: (val) => setState(() => _autoOpen = val),
                      title: Text(
                        'Tự động mở',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txt(context),
                        ),
                      ),
                      subtitle: Text(
                        'Tự động mở đề thi cho học sinh khi đến thời gian đã đặt',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                      activeThumbColor: AppConstants.brand(context),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 20),

                    // Close Time Section
                    _buildSectionTitle('Thời gian đóng đề thi', Icons.lock_outline_rounded),
                    const SizedBox(height: 10),
                    _buildTimeCard(
                      label: 'Thời gian đóng',
                      time: _closeTime,
                      onTap: () => _selectDateTime(false),
                      onClear: () => setState(() => _closeTime = null),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _autoClose,
                      onChanged: (val) => setState(() => _autoClose = val),
                      title: Text(
                        'Tự động đóng',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txt(context),
                        ),
                      ),
                      subtitle: Text(
                        'Tự động đóng đề thi và kết thúc lượt làm bài khi hết hạn',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                      activeThumbColor: AppConstants.brand(context),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 20),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppConstants.border(context) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppConstants.brand(context),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Học sinh chỉ có thể làm bài trong khoảng thời gian đã đặt. Giáo viên có thể mở hoặc đóng đề thi thủ công bất cứ lúc nào.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? AppConstants.txt(context) : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Validation warning
                    if (_openTime != null && _closeTime != null && _closeTime!.isBefore(_openTime!))
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Thời gian đóng phải sau thời gian mở!',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surf(context),
                border: Border(top: BorderSide(color: AppConstants.border(context))),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: isMobile && widget.existingSchedule != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppConstants.border(context)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  'Hủy',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.txtMuted(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _isSaving || !_isValid() ? null : _saveSchedule,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppConstants.brand(context),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'Lưu lịch thi',
                                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _deleteSchedule,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Xóa lịch'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (widget.existingSchedule != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : _deleteSchedule,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              label: const Text('Xóa lịch'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        if (widget.existingSchedule != null) const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppConstants.border(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: AppConstants.txtMuted(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isSaving || !_isValid() ? null : _saveSchedule,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppConstants.brand(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Lưu lịch thi',
                                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConstants.brand(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppConstants.txt(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard({
    required String label,
    required DateTime? time,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasTime = time != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.surfLow(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime
                ? AppConstants.brand(context).withValues(alpha: 0.4)
                : AppConstants.border(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasTime ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
              size: 20,
              color: hasTime ? AppConstants.brand(context) : AppConstants.txtMuted(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.txtMuted(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasTime ? _formatDateTime(time) : 'Chưa đặt (Bấm để chọn ngày & giờ)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: hasTime ? FontWeight.w700 : FontWeight.w500,
                      color: hasTime ? AppConstants.txt(context) : AppConstants.txtMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            if (hasTime)
              IconButton(
                icon: Icon(Icons.clear_rounded, size: 18, color: AppConstants.txtMuted(context)),
                onPressed: onClear,
                tooltip: 'Xóa',
              )
            else
              Icon(Icons.chevron_right_rounded, size: 20, color: AppConstants.txtMuted(context)),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isValid() {
    if (_openTime != null && _closeTime != null) {
      return _closeTime!.isAfter(_openTime!);
    }
    return true;
  }

  Future<void> _selectDateTime(bool isOpenTime) async {
    final initialDate = (isOpenTime ? _openTime : _closeTime) ?? DateTime.now();
    final isDark = AppConstants.isDarkMode(context);

    // Bước 1: Chọn ngày với giao diện lịch hiện đại
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => ModernDatePickerDialog(
        title: isOpenTime ? 'Chọn ngày mở đề thi' : 'Chọn ngày đóng đề thi',
        initialDate: initialDate,
      ),
    );

    if (selectedDate == null || !mounted) return;

    // Bước 2: Tiếp tục chọn giờ với giao diện đồng hồ
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: isOpenTime ? 'CHỌN GIỜ MỞ ĐỀ THI' : 'CHỌN GIỜ ĐÓNG ĐỀ THI',
      cancelText: 'HỦY',
      confirmText: 'XÁC NHẬN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF003D9B),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Color(0xFFF1F5F9),
                    surfaceContainerHighest: Color(0xFF334155),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF003D9B),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                    surfaceContainerHighest: Color(0xFFF1F5F9),
                  ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF003D9B);
                }
                return isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return isDark ? Colors.white : const Color(0xFF0F172A);
              }),
              hourMinuteTextStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF003D9B);
                }
                return isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
              }),
              dayPeriodBorderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dialHandColor: const Color(0xFF003D9B),
              dialBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return isDark ? Colors.white : const Color(0xFF0F172A);
              }),
              dialTextStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              entryModeIconColor: const Color(0xFF003D9B),
              helpTextStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              confirmButtonStyle: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF003D9B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      final combined = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (isOpenTime) {
        _openTime = combined;
      } else {
        _closeTime = combined;
      }
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    try {
      if (widget.existingSchedule == null) {
        await QuizScheduleService.createSchedule(
          quizId: widget.quizId,
          classId: widget.classId,
          openTime: _openTime,
          closeTime: _closeTime,
          autoOpen: _autoOpen,
          autoClose: _autoClose,
        );
      } else {
        await QuizScheduleService.updateSchedule(
          scheduleId: widget.existingSchedule!.id,
          openTime: _openTime,
          closeTime: _closeTime,
          autoOpen: _autoOpen,
          autoClose: _autoClose,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã lưu lịch đề thi thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSchedule() async {
    if (widget.existingSchedule == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppConstants.surf(dialogCtx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.border(dialogCtx)),
        ),
        title: Text(
          'Xác nhận xóa',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppConstants.txt(dialogCtx),
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa lịch đề thi này? Đề thi sẽ trở về trạng thái bình thường.',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppConstants.txtMuted(dialogCtx),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppConstants.border(dialogCtx)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hủy', style: TextStyle(color: AppConstants.txtMuted(dialogCtx))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await QuizScheduleService.deleteSchedule(widget.existingSchedule!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa lịch đề thi'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Modern Date Picker Dialog
/// Displays the Vietnamese calendar with clear contrast, custom styling,
/// no clipped numbers (day 30 is crystal clear), and a button to proceed to time selection.
class ModernDatePickerDialog extends StatefulWidget {
  final String title;
  final DateTime initialDate;

  const ModernDatePickerDialog({
    super.key,
    required this.title,
    required this.initialDate,
  });

  @override
  State<ModernDatePickerDialog> createState() => _ModernDatePickerDialogState();
}

class _ModernDatePickerDialogState extends State<ModernDatePickerDialog> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  List<DateTime> _generateCalendarDays() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

    // Weekday: 1 = Monday, 7 = Sunday
    final leadingDays = firstDayOfMonth.weekday - 1;
    final List<DateTime> days = [];

    // Leading days from previous month
    for (int i = leadingDays; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }

    // Days in current month
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month, i + 1));
    }

    // Trailing days from next month to complete rows of 7
    final remaining = (7 - (days.length % 7)) % 7;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month + 1, i));
    }

    return days;
  }

  String _formatFullDate() {
    const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final weekdayStr = weekdays[_selectedDate.weekday - 1];
    final dayStr = _selectedDate.day.toString().padLeft(2, '0');
    final monthStr = _selectedDate.month.toString().padLeft(2, '0');
    final yearStr = _selectedDate.year.toString();
    return '$weekdayStr, $dayStr/$monthStr/$yearStr';
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateCalendarDays();
    final now = DateTime.now();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppConstants.surf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppConstants.border(context)),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit_calendar_rounded, color: AppConstants.brand(context), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.txt(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chọn ngày thi rồi bấm Tiếp tục chọn giờ',
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
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Selection preview badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.brand(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.brand(context).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today_rounded, color: AppConstants.brand(context), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatFullDate(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.brand(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Month Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 18, color: AppConstants.brand(context)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tháng ${_displayedMonth.month}, ${_displayedMonth.year}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.txt(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          final today = DateTime.now();
                          setState(() {
                            _displayedMonth = DateTime(today.year, today.month, 1);
                            _selectedDate = DateTime(today.year, today.month, today.day);
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Hôm nay',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.brand(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.surfLow(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppConstants.border(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                                });
                              },
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.chevron_left_rounded, size: 20, color: AppConstants.txt(context)),
                              ),
                            ),
                            Container(width: 1, height: 16, color: AppConstants.border(context)),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                                });
                              },
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.chevron_right_rounded, size: 20, color: AppConstants.txt(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weekdays Header
              Row(
                children: const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((w) {
                  final isSunday = w == 'CN';
                  return Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSunday ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isCurrentMonth = day.month == _displayedMonth.month;
                  final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                  final isSelected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(day.year, day.month, day.day);
                        if (!isCurrentMonth) {
                          _displayedMonth = DateTime(day.year, day.month, 1);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppConstants.brand(context) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: (isToday && !isSelected)
                            ? Border.all(color: AppConstants.brand(context), width: 1.5)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppConstants.brand(context).withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (!isCurrentMonth
                                  ? AppConstants.txtMuted(context).withValues(alpha: 0.35)
                                  : (isToday ? AppConstants.brand(context) : AppConstants.txt(context))),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Actions Footer
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: AppConstants.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _selectedDate),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tiếp tục chọn giờ',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                        backgroundColor: AppConstants.brand(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
