// lib/screens/student/setting_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_provider.dart';
import '../../utils/constants.dart';

enum _SettingTab { profile, notifications, security, appearance }

class SettingPage extends StatefulWidget {
  final String studentId;
  final bool showTopBar;

  const SettingPage({
    super.key,
    required this.studentId,
    this.showTopBar = true,
  });

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  _SettingTab _activeTab = _SettingTab.profile;

  // Notification toggles
  bool _notifyExam = true;
  bool _notifyResult = true;
  bool _notifySystem = false;

  Future<void> _pickImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;

        if (fileBytes != null) {
          final uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_$fileName';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('avatars/${user.uid}/$uniqueFileName');

          final uploadTask = await storageRef.putData(fileBytes);
          final downloadUrl = await uploadTask.ref.getDownloadURL();

          await user.updatePhotoURL(downloadUrl);

          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ảnh đại diện thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh lên: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Column(
        children: [
          if (widget.showTopBar) _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page header
                      Text(
                        'Cài đặt hệ thống',
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
                        'Quản lý hồ sơ, thông báo, bảo mật và tùy chọn giao diện hiển thị.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Layout: sidebar + content
                      LayoutBuilder(builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 560;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 220, child: _buildTabNav(isDark)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTabContent(isDark)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildTabNavHorizontal(isDark),
                              const SizedBox(height: 16),
                              _buildTabContent(isDark),
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
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        border: Border(bottom: BorderSide(color: AppConstants.border(context))),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_outlined,
              color: AppConstants.brand(context), size: 24),
          const SizedBox(width: 8),
          Text(
            'Cài đặt',
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

  Widget _buildTabNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Column(
        children: _SettingTab.values
            .map((t) => _buildTabNavItem(t, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildTabNavHorizontal(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _SettingTab.values
            .map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTabChip(t, isDark),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTabChip(_SettingTab tab, bool isDark) {
    final isActive = _activeTab == tab;
    final activeBg = isDark
        ? AppConstants.darkSurfaceContainerHigh
        : AppConstants.surfaceContainerHigh;
    final activeColor = AppConstants.brand(context);

    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : AppConstants.surf(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : AppConstants.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _tabIcon(tab),
              size: 16,
              color: isActive ? activeColor : AppConstants.txtMuted(context),
            ),
            const SizedBox(width: 6),
            Text(
              _tabLabel(tab),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppConstants.txtMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavItem(_SettingTab tab, bool isDark) {
    final isActive = _activeTab == tab;
    final activeBg = isDark
        ? AppConstants.darkSurfaceContainerHigh
        : AppConstants.surfaceContainerHigh;
    final activeColor = AppConstants.brand(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _tabIcon(tab),
                size: 20,
                color: isActive ? activeColor : AppConstants.txtMuted(context),
              ),
              const SizedBox(width: 10),
              Text(
                _tabLabel(tab),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : AppConstants.txt(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _tabIcon(_SettingTab tab) {
    switch (tab) {
      case _SettingTab.profile:
        return Icons.person_outlined;
      case _SettingTab.notifications:
        return Icons.notifications_active_outlined;
      case _SettingTab.security:
        return Icons.lock_outlined;
      case _SettingTab.appearance:
        return Icons.palette_outlined;
    }
  }

  String _tabLabel(_SettingTab tab) {
    switch (tab) {
      case _SettingTab.profile:
        return 'Hồ sơ cá nhân';
      case _SettingTab.notifications:
        return 'Thông báo';
      case _SettingTab.security:
        return 'Bảo mật';
      case _SettingTab.appearance:
        return 'Giao diện';
    }
  }

  Widget _buildTabContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildActiveTab(isDark),
      ),
    );
  }

  Widget _buildActiveTab(bool isDark) {
    switch (_activeTab) {
      case _SettingTab.profile:
        return _buildProfileTab(isDark);
      case _SettingTab.notifications:
        return _buildNotificationsTab(isDark);
      case _SettingTab.security:
        return _buildSecurityTab(isDark);
      case _SettingTab.appearance:
        return _buildAppearanceTab(isDark);
    }
  }

  // =================== PROFILE TAB ===================
  Widget _buildProfileTab(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : 'Sinh viên';

    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hồ sơ cá nhân',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.txt(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF064E3B)
                    : AppConstants.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF059669)
                      : AppConstants.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : AppConstants.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đã xác thực bởi Trường',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : AppConstants.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Banner thông báo không chỉnh sửa
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262B36) : const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF3B4354) : const Color(0xFFD6DCE7),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_person_outlined,
                size: 20,
                color: AppConstants.brand(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Họ tên và mã số sinh viên được đồng bộ tự động từ tài khoản email của Nhà trường và không thể chỉnh sửa.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppConstants.txt(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Avatar
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppConstants.brand(context),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        _initials(user),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppConstants.brand(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.surf(context),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Form các ô xám không thể chỉnh sửa
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 440;
          final nameField = _buildDisabledField(
            label: 'Họ và tên sinh viên',
            value: name,
            icon: Icons.person_outline,
            isDark: isDark,
          );
          final idField = _buildDisabledField(
            label: 'Mã số sinh viên (MSSV)',
            value: widget.studentId,
            icon: Icons.badge_outlined,
            isDark: isDark,
          );
          final emailField = _buildDisabledField(
            label: 'Email sinh viên (Trường cấp)',
            value: user?.email ?? '${widget.studentId}@sv.dut.udn.vn',
            icon: Icons.email_outlined,
            isDark: isDark,
          );
          final schoolField = _buildDisabledField(
            label: 'Trường học / Cơ sở đào tạo',
            value: 'Trường Đại Học Bách Khoa - Đại học Đà Nẵng',
            icon: Icons.school_outlined,
            isDark: isDark,
          );

          if (isWide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 16),
                    Expanded(child: idField),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: emailField),
                    const SizedBox(width: 16),
                    Expanded(child: schoolField),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                nameField,
                const SizedBox(height: 14),
                idField,
                const SizedBox(height: 14),
                emailField,
                const SizedBox(height: 14),
                schoolField,
              ],
            );
          }
        }),
      ],
    );
  }

  // Widget ô xám không thể chỉnh sửa (Disabled Box)
  Widget _buildDisabledField({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    // Màu box xám chuẩn read-only
    final boxBg = isDark ? const Color(0xFF232730) : const Color(0xFFECEFF4);
    final boxBorder =
        isDark ? const Color(0xFF353C49) : const Color(0xFFD4D9E2);
    final textColor =
        isDark ? const Color(0xFFDDE2ED) : const Color(0xFF333A48);
    final iconColor =
        isDark ? const Color(0xFF8B94A5) : const Color(0xFF6B7280);
    final badgeBg = isDark ? const Color(0xFF1B1E26) : const Color(0xFFDEE2E8);
    final badgeText =
        isDark ? const Color(0xFF9EABC0) : const Color(0xFF5B6370);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.txtMuted(context),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.lock_outline_rounded, size: 13, color: iconColor),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: boxBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: boxBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 11, color: badgeText),
                    const SizedBox(width: 3),
                    Text(
                      'Cố định',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== NOTIFICATIONS TAB ===================
  Widget _buildNotificationsTab(bool isDark) {
    return Column(
      key: const ValueKey('notifications'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cài đặt thông báo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.txt(context),
          ),
        ),
        const SizedBox(height: 20),
        _buildToggleRow(
          title: 'Thông báo kỳ thi sắp tới',
          desc: 'Nhận email nhắc nhở 24h trước khi bắt đầu bài thi',
          value: _notifyExam,
          onChanged: (v) => setState(() => _notifyExam = v),
          hasDivider: true,
        ),
        _buildToggleRow(
          title: 'Kết quả bài thi',
          desc: 'Thông báo ngay khi giáo viên công bố điểm số',
          value: _notifyResult,
          onChanged: (v) => setState(() => _notifyResult = v),
          hasDivider: true,
        ),
        _buildToggleRow(
          title: 'Cập nhật hệ thống',
          desc: 'Tin tức và tính năng mới từ hệ thống thi QuizMaster',
          value: _notifySystem,
          onChanged: (v) => setState(() => _notifySystem = v),
          hasDivider: false,
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool hasDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.txt(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppConstants.txtMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppConstants.brand(context),
              ),
            ],
          ),
        ),
        if (hasDivider) Divider(height: 1, color: AppConstants.border(context)),
      ],
    );
  }

  // =================== SECURITY TAB ===================
  Widget _buildSecurityTab(bool isDark) {
    return Column(
      key: const ValueKey('security'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bảo mật tài khoản',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.txt(context),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262B36) : const Color(0xFFF1F4F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF3B4354) : const Color(0xFFD6DCE7),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: AppConstants.brand(context), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tài khoản đăng nhập qua hệ thống trường Đại học. Mật khẩu được bảo mật và quản lý tập trung bởi Nhà trường, sinh viên không cần và không thể đổi mật khẩu tại đây.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.txt(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDisabledField(
                label: 'Mật khẩu hiện tại',
                value: '••••••••••••••••',
                icon: Icons.key_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildDisabledField(
                label: 'Mật khẩu mới',
                value: '••••••••••••••••',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildDisabledField(
                label: 'Xác nhận mật khẩu mới',
                value: '••••••••••••••••',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.darkSurfaceContainerLow
                      : AppConstants.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: AppConstants.txtMuted(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nếu bạn quên mật khẩu trường, vui lòng liên hệ Trung tâm CNTT hoặc Phòng Đào tạo để được cấp lại.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppConstants.txtMuted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== APPEARANCE TAB ===================
  Widget _buildAppearanceTab(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      key: const ValueKey('appearance'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giao diện hiển thị',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.txt(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tùy chỉnh chế độ màu sáng hoặc tối cho toàn bộ ứng dụng web.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppConstants.txtMuted(context),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: () {
                AppConstants.isDark = false;
                themeProvider.setDarkMode(false);
              },
              child: _buildThemeCard(
                label: 'Sáng (Mặc định)',
                icon: Icons.light_mode_outlined,
                bg: const Color(0xFFF9FAFB),
                isSelected: !isDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                AppConstants.isDark = true;
                themeProvider.setDarkMode(true);
              },
              child: _buildThemeCard(
                label: 'Tối (Dark Mode)',
                icon: Icons.dark_mode_outlined,
                bg: const Color(0xFF181A20),
                isSelected: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Divider(color: AppConstants.border(context)),
        const SizedBox(height: 20),
        Text(
          'Kích thước cỡ chữ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.txt(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            GestureDetector(
              onTap: () => themeProvider.setFontSize('Nhỏ'),
              child: _buildFontOption('Nhỏ', themeProvider.fontSize == 'Nhỏ'),
            ),
            GestureDetector(
              onTap: () => themeProvider.setFontSize('Mặc định'),
              child: _buildFontOption(
                  'Mặc định', themeProvider.fontSize == 'Mặc định'),
            ),
            GestureDetector(
              onTap: () => themeProvider.setFontSize('Lớn'),
              child: _buildFontOption('Lớn', themeProvider.fontSize == 'Lớn'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontOption(String label, bool isSelected) {
    final activeColor = AppConstants.brand(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? activeColor.withValues(alpha: 0.12)
            : AppConstants.surf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? activeColor : AppConstants.border(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? activeColor : AppConstants.txt(context),
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String label,
    required IconData icon,
    required Color bg,
    required bool isSelected,
  }) {
    final activeColor = AppConstants.brand(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? activeColor : AppConstants.border(context),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppConstants.border(context)),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: bg.computeLuminance() > 0.5
                        ? const Color(0xFF1E2128)
                        : Colors.white,
                    size: 26,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.check_circle, color: activeColor, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : AppConstants.txt(context),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return user.displayName![0].toUpperCase();
    }
    return 'SV';
  }
}
