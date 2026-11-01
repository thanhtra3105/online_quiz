// lib/screens/teacher/manage_classes_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_detail_page.dart';
import '../../utils/constants.dart';

class ManageClassesPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const ManageClassesPage({super.key, this.onNavigate});

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  String _searchQuery = '';

  static const List<IconData> _subjectIcons = [
    Icons.science_outlined,
    Icons.biotech_outlined,
    Icons.calculate_outlined,
    Icons.public_outlined,
    Icons.history_edu_outlined,
    Icons.computer_outlined,
    Icons.psychology_outlined,
    Icons.architecture_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppConstants.bg(context),
      body: Column(
        children: [
          _buildTopAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 28),
                    _buildBentoStats(teacherId),
                    const SizedBox(height: 36),
                    _buildClassGridHeader(),
                    const SizedBox(height: 16),
                    _buildClassGrid(teacherId),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final searchField = Container(
      width: isMobile ? double.infinity : 300,
      height: 42,
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txt(context)),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm lớp, phòng, tiết...',
          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
          prefixIcon: Icon(Icons.search_rounded, color: AppConstants.txtMuted(context), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: 12),
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
      child: isMobile
          ? searchField
          : Row(
              children: [
                searchField,
                const SizedBox(width: 32),
                // Nav links
                Row(
                  children: [
                    InkWell(
                      onTap: () => widget.onNavigate?.call(0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppConstants.brand(context), width: 2.5)),
                        ),
                        child: Text(
                          'Quản lý lớp học',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.brand(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => widget.onNavigate?.call(1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Bài thi',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => widget.onNavigate?.call(2),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Ngân hàng câu hỏi',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.txtMuted(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Actions
                Row(
                  children: [
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
              ],
            ),
    );
  }

  Widget _buildPageHeader() {
    final isDark = AppConstants.isDarkMode(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final headerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.surfHigh(context) : const Color(0xFF003D9B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.groups_rounded, color: AppConstants.brand(context), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quản lý lớp học',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Quản lý danh sách các lớp học phần, thông tin phòng học, thời khóa biểu và sinh viên.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppConstants.txtMuted(context)),
        ),
      ],
    );

    final actionButton = FilledButton.icon(
      onPressed: _showCreateClassDialog,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Tạo lớp học mới',
        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppConstants.brand(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerInfo,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: actionButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: headerInfo),
        const SizedBox(width: 16),
        actionButton,
      ],
    );
  }

  Widget _buildBentoStats(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots(),
      builder: (context, snapshot) {
        int totalStudents = 0;
        int activeClasses = 0;

        if (snapshot.hasData) {
          final classes = snapshot.data!.docs;
          activeClasses = classes.length;
          for (var doc in classes) {
            final data = doc.data() as Map<String, dynamic>;
            totalStudents += (data['studentCount'] as num?)?.toInt() ?? 0;
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1080;

            if (isMobile) {
              return Column(
                children: [
                  _buildStatCard(
                    title: 'Tổng sinh viên',
                    value: '$totalStudents',
                    subtitle: 'Sinh viên đã tham gia các lớp',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    title: 'Số lớp học phần',
                    value: '$activeClasses',
                    subtitle: 'Lớp học đang hoạt động',
                    icon: Icons.school_rounded,
                    accentColor: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                  const SizedBox(height: 16),
                  _buildUpcomingExamCard(),
                ],
              );
            } else if (isTablet) {
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tổng sinh viên',
                            value: '$totalStudents',
                            subtitle: 'Sinh viên đã tham gia các lớp',
                            icon: Icons.people_alt_rounded,
                            accentColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Số lớp học phần',
                            value: '$activeClasses',
                            subtitle: 'Lớp học đang hoạt động',
                            icon: Icons.school_rounded,
                            accentColor: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildUpcomingExamCard(),
                ],
              );
            } else {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Tổng sinh viên',
                        value: '$totalStudents',
                        subtitle: 'Sinh viên đã tham gia',
                        icon: Icons.people_alt_rounded,
                        accentColor: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Số lớp học phần',
                        value: '$activeClasses',
                        subtitle: 'Lớp đang hoạt động',
                        icon: Icons.school_rounded,
                        accentColor: const Color(0xFF059669),
                        bgColor: const Color(0xFFECFDF5),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildUpcomingExamCard(),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    final isDark = AppConstants.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txtMuted(context),
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfHigh(context) : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppConstants.txt(context),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.txtMuted(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003D9B), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D9B).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -20,
            child: Icon(
              Icons.quiz_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFFDE047)),
                        SizedBox(width: 4),
                        Text(
                          'KHO BÀI THI & ĐỀ THI',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Tạo và giao bài thi cho các lớp học',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thiết lập bài thi trắc nghiệm, thời gian làm bài và theo dõi kết quả của sinh viên.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => widget.onNavigate?.call(1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'Xem kho bài thi',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF003D9B),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassGridHeader() {
    final isDark = AppConstants.isDarkMode(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Danh sách lớp học phần',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.txt(context),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lọc: "$_searchQuery"',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.brand(context)),
            ),
          ),
      ],
    );
  }

  Widget _buildClassGrid(String teacherId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppConstants.brand(context))),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        var classes = snapshot.data?.docs ?? [];

        if (_searchQuery.isNotEmpty) {
          classes = classes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final className = (data['name'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            final room = (data['room'] ?? '').toString().toLowerCase();
            final period = (data['period'] ?? '').toString().toLowerCase();
            return className.contains(_searchQuery) ||
                description.contains(_searchQuery) ||
                room.contains(_searchQuery) ||
                period.contains(_searchQuery);
          }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;
            final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 1024;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 295,
              ),
              itemCount: classes.length + 1,
              itemBuilder: (context, index) {
                if (index == classes.length) {
                  return _buildCreateNewClassPlaceholder();
                }

                final classDoc = classes[index];
                final data = classDoc.data() as Map<String, dynamic>;
                return _buildClassCard(classDoc.id, data, index);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreateNewClassPlaceholder() {
    final isDark = AppConstants.isDarkMode(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCreateClassDialog,
        borderRadius: BorderRadius.circular(16),
        hoverColor: isDark ? AppConstants.surfHigh(context) : const Color(0xFFF1F5F9),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppConstants.border(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            color: AppConstants.surf(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: AppConstants.brand(context), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Tạo lớp học mới',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.txt(context),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Khởi tạo lớp học phần, phòng học và tiết học mới cho sinh viên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(String classId, Map<String, dynamic> data, int index) {
    final icon = _subjectIcons[index % _subjectIcons.length];
    final className = data['name'] ?? 'Lớp học';
    final description = (data['description'] ?? '').toString().trim();
    final room = (data['room'] ?? '').toString().trim();
    final period = (data['period'] ?? '').toString().trim();
    final studentCount = (data['studentCount'] as num?)?.toInt() ?? 0;
    final quizCount = (data['quizCount'] as num?)?.toInt() ?? 0;
    final isDark = AppConstants.isDarkMode(context);

    // Schedule line: e.g. "Phòng F.302 • Tiết 1-3" or "T3 8-10"
    String scheduleText = '';
    if (room.isNotEmpty && period.isNotEmpty) {
      scheduleText = 'Phòng $room • $period';
    } else if (room.isNotEmpty) {
      scheduleText = 'Phòng $room';
    } else if (period.isNotEmpty) {
      scheduleText = period;
    } else {
      scheduleText = 'Chưa có phòng & tiết học';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDetailPage(
                  classId: classId,
                  className: className,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Subject Icon + Active Badge + Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppConstants.brand(context), size: 24),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEBECF0),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppConstants.txt(context) : const Color(0xFF42526E),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Popup Menu
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: AppConstants.surf(context),
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert_rounded, color: AppConstants.txtMuted(context), size: 20),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: AppConstants.brand(context), size: 18),
                                  const SizedBox(width: 10),
                                  Text('Chỉnh sửa', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppConstants.txt(context))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                  SizedBox(width: 10),
                                  Text('Xóa lớp', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditClassDialog(classId, data);
                            } else if (value == 'delete') {
                              _deleteClass(classId, data);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Class Name
                Text(
                  className,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.txt(context),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),

                // Description
                Text(
                  description.isNotEmpty ? description : 'Chưa có mô tả',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Room & Period line
                Text(
                  scheduleText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: (room.isNotEmpty || period.isNotEmpty) ? FontWeight.w500 : FontWeight.normal,
                    color: AppConstants.txtMuted(context),
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Stat pills
                Row(
                  children: [
                    _buildStatPill(
                      icon: Icons.quiz_outlined,
                      label: '$quizCount bài thi',
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      icon: Icons.group_outlined,
                      label: '$studentCount HS',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailPage(
                            classId: classId,
                            className: className,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.brand(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Truy cập lớp học'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppConstants.surfLow(context),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppConstants.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.txtMuted(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppConstants.txt(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ClassFormDialog(
        title: 'Tạo lớp học mới',
        subtitle: 'Điền thông tin lớp học phần và lịch giảng dạy',
        icon: Icons.school_rounded,
        submitText: 'Tạo lớp',
        onSubmit: (name, description, room, period) async {
          final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';
          await FirebaseFirestore.instance.collection('classes').add({
            'name': name,
            'description': description,
            'room': room,
            'period': period,
            'teacherId': teacherId,
            'studentCount': 0,
            'quizCount': 0,
            'averageScore': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Tạo lớp học thành công!'),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditClassDialog(String classId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ClassFormDialog(
        title: 'Chỉnh sửa lớp học',
        subtitle: 'Cập nhật thông tin lớp, phòng học và tiết học',
        icon: Icons.edit_note_rounded,
        submitText: 'Lưu thay đổi',
        initialName: data['name'] ?? '',
        initialDescription: data['description'] ?? '',
        initialRoom: data['room'] ?? '',
        initialPeriod: data['period'] ?? '',
        onSubmit: (name, description, room, period) async {
          await FirebaseFirestore.instance.collection('classes').doc(classId).update({
            'name': name,
            'description': description,
            'room': room,
            'period': period,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Cập nhật lớp học thành công!'),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteClass(String classId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = AppConstants.isDarkMode(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppConstants.surf(context),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppConstants.surf(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF4A1010) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xác nhận xóa lớp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.txt(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn có chắc chắn muốn xóa lớp "${data['name']}" không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppConstants.txtMuted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppConstants.border(context) : const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lưu ý quan trọng:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Xóa toàn bộ sinh viên đã tham gia lớp\n• Xóa các bài thi thuộc lớp này\n• Hành động này không thể hoàn tác!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isDark ? AppConstants.txtMuted(context) : const Color(0xFF9A3412),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppConstants.border(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.txt(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Xóa lớp',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      // Delete all students in class
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      for (var doc in studentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all quizzes in class
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .get();

      for (var doc in quizzesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete class document
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa lớp học thành công'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi khi xóa: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _ClassFormDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String submitText;
  final String initialName;
  final String initialDescription;
  final String initialRoom;
  final String initialPeriod;
  final Future<void> Function(String name, String description, String room, String period) onSubmit;

  const _ClassFormDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.submitText,
    this.initialName = '',
    this.initialDescription = '',
    this.initialRoom = '',
    this.initialPeriod = '',
    required this.onSubmit,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _classNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _roomController;
  late final TextEditingController _periodController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _classNameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _roomController = TextEditingController(text: widget.initialRoom);
    _periodController = TextEditingController(text: widget.initialPeriod);
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _descriptionController.dispose();
    _roomController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        _classNameController.text.trim(),
        _descriptionController.text.trim(),
        _roomController.text.trim(),
        _periodController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDarkMode(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppConstants.surf(context),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.surf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppConstants.surfHigh(context) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: AppConstants.brand(context), size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.txt(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppConstants.txtMuted(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Class Name
              TextFormField(
                controller: _classNameController,
                style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                decoration: InputDecoration(
                  labelText: 'Tên lớp học *',
                  labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                  hintText: 'VD: Kỹ thuật Robot, Giải tích 1...',
                  hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                  prefixIcon: Icon(Icons.class_rounded, color: AppConstants.txtMuted(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                  filled: true,
                  fillColor: AppConstants.surfLow(context),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên lớp học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description / Class Code
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                decoration: InputDecoration(
                  labelText: 'Mô tả / Mã lớp',
                  labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                  hintText: 'VD: Lớp học phần 22N44, Học kỳ 1...',
                  hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                  prefixIcon: Icon(Icons.badge_outlined, color: AppConstants.txtMuted(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                  filled: true,
                  fillColor: AppConstants.surfLow(context),
                ),
              ),
              const SizedBox(height: 16),
              // Room & Period in Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomController,
                      style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                      decoration: InputDecoration(
                        labelText: 'Phòng học',
                        labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                        hintText: 'VD: F.302, A205...',
                        hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                        prefixIcon: Icon(Icons.meeting_room_outlined, color: AppConstants.txtMuted(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                        filled: true,
                        fillColor: AppConstants.surfLow(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _periodController,
                      style: TextStyle(fontFamily: 'Inter', color: AppConstants.txt(context)),
                      decoration: InputDecoration(
                        labelText: 'Tiết học',
                        labelStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                        hintText: 'VD: T3 8-10, Tiết 1-3...',
                        hintStyle: TextStyle(fontFamily: 'Inter', color: AppConstants.txtMuted(context)),
                        prefixIcon: Icon(Icons.schedule_rounded, color: AppConstants.txtMuted(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.border(context))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppConstants.brand(context), width: 2)),
                        filled: true,
                        fillColor: AppConstants.surfLow(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppConstants.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Hủy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.txt(context))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.brand(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(widget.submitText, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
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
