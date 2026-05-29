// lib/screens/student/setting_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';

enum _SettingTab { profile, notifications, security, appearance }

class SettingPage extends StatefulWidget {
  final String studentId;
  const SettingPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  _SettingTab _activeTab = _SettingTab.profile;

  // Notification toggles
  bool _notifyExam = true;
  bool _notifyResult = true;
  bool _notifySystem = false;

  // Profile
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController(text: 'Đại học Công nghệ');

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
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
                      // Page header
                      const Text(
                        'Cài đặt hệ thống',
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
                        'Quản lý hồ sơ, thông báo và tùy chọn cá nhân.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppConstants.onSurfaceVariant,
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
                              SizedBox(width: 220, child: _buildTabNav()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTabContent()),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildTabNavHorizontal(),
                              const SizedBox(height: 16),
                              _buildTabContent(),
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
          const Icon(Icons.settings_outlined, color: AppConstants.primary, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Cài đặt',
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

  Widget _buildTabNav() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: Column(
        children: _SettingTab.values
            .map((t) => _buildTabNavItem(t))
            .toList(),
      ),
    );
  }

  Widget _buildTabNavHorizontal() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _SettingTab.values
            .map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTabChip(t),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTabChip(_SettingTab tab) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppConstants.surfaceContainerHigh
              : AppConstants.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tabIcon(tab), size: 16,
                color: isActive ? AppConstants.primary : AppConstants.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              _tabLabel(tab),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppConstants.primary : AppConstants.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavItem(_SettingTab tab) {
    final isActive = _activeTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppConstants.surfaceContainerHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_tabIcon(tab), size: 20,
                  color: isActive ? AppConstants.primary : AppConstants.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(
                _tabLabel(tab),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppConstants.primary : AppConstants.onSurfaceVariant,
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
      case _SettingTab.profile: return Icons.person_outlined;
      case _SettingTab.notifications: return Icons.notifications_active_outlined;
      case _SettingTab.security: return Icons.lock_outlined;
      case _SettingTab.appearance: return Icons.palette_outlined;
    }
  }

  String _tabLabel(_SettingTab tab) {
    switch (tab) {
      case _SettingTab.profile: return 'Hồ sơ cá nhân';
      case _SettingTab.notifications: return 'Thông báo';
      case _SettingTab.security: return 'Bảo mật';
      case _SettingTab.appearance: return 'Giao diện';
    }
  }

  Widget _buildTabContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.outlineVariant),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildActiveTab(),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_activeTab) {
      case _SettingTab.profile:
        return _buildProfileTab();
      case _SettingTab.notifications:
        return _buildNotificationsTab();
      case _SettingTab.security:
        return _buildSecurityTab();
      case _SettingTab.appearance:
        return _buildAppearanceTab();
    }
  }

  // =================== PROFILE TAB ===================
  Widget _buildProfileTab() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        // Avatar
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppConstants.primary,
              child: Text(
                _initials(user),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 20),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Đổi ảnh',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Form
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 440;
          final nameField = _buildTextField(
            label: 'Họ và tên',
            controller: _nameCtrl,
            type: TextInputType.name,
          );
          final emailField = _buildTextField(
            label: 'Email',
            controller: TextEditingController(text: user?.email ?? ''),
            type: TextInputType.emailAddress,
            readOnly: true,
          );
          return Column(
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 16),
                    Expanded(child: emailField),
                  ],
                )
              else ...[nameField, const SizedBox(height: 16), emailField],
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Trường học / Tổ chức',
                controller: _schoolCtrl,
                type: TextInputType.text,
              ),
            ],
          );
        }),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã lưu thay đổi!'),
                  backgroundColor: AppConstants.secondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType type,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          readOnly: readOnly,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppConstants.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? AppConstants.surfaceContainerLow
                : AppConstants.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppConstants.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppConstants.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppConstants.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // =================== NOTIFICATIONS TAB ===================
  Widget _buildNotificationsTab() {
    return Column(
      key: const ValueKey('notifications'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt thông báo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        _buildToggleRow(
          title: 'Thông báo kỳ thi sắp tới',
          desc: 'Nhận email nhắc nhở 24h trước khi bắt đầu',
          value: _notifyExam,
          onChanged: (v) => setState(() => _notifyExam = v),
          hasDivider: true,
        ),
        _buildToggleRow(
          title: 'Kết quả bài thi',
          desc: 'Thông báo ngay khi có điểm',
          value: _notifyResult,
          onChanged: (v) => setState(() => _notifyResult = v),
          hasDivider: true,
        ),
        _buildToggleRow(
          title: 'Cập nhật hệ thống',
          desc: 'Tin tức và tính năng mới từ QuizMaster',
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
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppConstants.primary,
              ),
            ],
          ),
        ),
        if (hasDivider)
          const Divider(height: 1, color: AppConstants.outlineVariant),
      ],
    );
  }

  // =================== SECURITY TAB ===================
  Widget _buildSecurityTab() {
    return Column(
      key: const ValueKey('security'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bảo mật tài khoản',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppConstants.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.outlineVariant),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppConstants.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tài khoản Microsoft/Google: mật khẩu được quản lý bởi nhà cung cấp danh tính.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppConstants.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'Mật khẩu hiện tại',
                controller: TextEditingController(),
                type: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Mật khẩu mới',
                controller: TextEditingController(),
                type: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Xác nhận mật khẩu mới',
                controller: TextEditingController(),
                type: TextInputType.visiblePassword,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Cập nhật mật khẩu',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =================== APPEARANCE TAB ===================
  Widget _buildAppearanceTab() {
    return Column(
      key: const ValueKey('appearance'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giao diện hiển thị',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          children: [
            _buildThemeCard(
              label: 'Sáng (Mặc định)',
              icon: Icons.light_mode_outlined,
              bg: const Color(0xFFF4F5F7),
              isSelected: true,
            ),
            _buildThemeCard(
              label: 'Tối',
              icon: Icons.dark_mode_outlined,
              bg: const Color(0xFF1A1A1A),
              isSelected: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppConstants.outlineVariant),
        const SizedBox(height: 16),
        const Text(
          'Kích thước chữ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['Nhỏ', 'Mặc định', 'Lớn'].map((size) {
            final isActive = size == 'Mặc định';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppConstants.surfaceContainerHigh
                    : AppConstants.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? AppConstants.primary
                      : AppConstants.outlineVariant,
                ),
              ),
              child: Text(
                size,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppConstants.primary : AppConstants.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String label,
    required IconData icon,
    required Color bg,
    required bool isSelected,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppConstants.primary : AppConstants.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppConstants.outlineVariant),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: bg.computeLuminance() > 0.5
                        ? AppConstants.onSurface
                        : Colors.white,
                    size: 24,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.check_circle,
                      color: AppConstants.primary, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.onSurface,
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
    return 'S';
  }
}
