// lib/screens/teacher/manage_classes_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'class_detail_page.dart';
import 'dart:math' as math;

class ManageClassesPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const ManageClassesPage({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _classNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          _buildTopAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 32),
                    _buildBentoStats(teacherId),
                    const SizedBox(height: 64),
                    _buildClassGrid(teacherId),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF).withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: Color(0xFFC3C6D6))),
      ),
      child: Row(
        children: [
          // Search Bar
          Container(
            width: 256,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lớp học...',
                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF434654), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Nav links
          Row(
            children: [
              InkWell(
                onTap: () => widget.onNavigate?.call(0),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF003D9B), width: 2))),
                  child: const Text('Quản lí lớp học', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003D9B))),
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () => widget.onNavigate?.call(1),
                child: const Text('Bài thi', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF434654))),
              ),
            ],
          ),
          const Spacer(),
          // Actions
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF434654))),
              IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF434654))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Quản lí lớp học', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF041B3C), letterSpacing: -0.5)),
            SizedBox(height: 8),
            Text('Quản lí các lớp học và sinh viên đăng ký.', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654))),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, size: 20),
              label: const Text('Filter', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF041B3C),
                side: const BorderSide(color: Color(0xFFC3C6D6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: const Color(0xFFF9F9FF),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _showCreateClassDialog,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text('Tạo lớp học mới', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF003D9B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
              ),
            ),
          ],
        ),
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
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
            
            if (isMobile) {
              return Column(
                children: [
                  _buildStatCard('Tổng học sinh', '$totalStudents', 'Số sinh viên đã đăng ký học', Icons.people_outline, true),
                  const SizedBox(height: 24),
                  _buildStatCard('Số lớp học', '$activeClasses', 'Số lớp đang hoạt động', null, false),
                  const SizedBox(height: 24),
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
                        Expanded(child: _buildStatCard('Tổng học sinh', '$totalStudents', 'Số sinh viên đã đăng ký học', Icons.people_outline, true)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildStatCard('Số lớp học', '$activeClasses', 'Số lớp đang hoạt động', null, false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildUpcomingExamCard(),
                ],
              );
            } else {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard('Tổng học sinh', '$totalStudents', 'Số sinh viên đã đăng ký học', Icons.people_outline, true),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStatCard('Số lớp học', '$activeClasses', 'Số lớp đang hoạt động', null, false),
                    ),
                    const SizedBox(width: 24),
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

  Widget _buildStatCard(String title, String value, String subtitle, IconData? icon, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF434654), letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF003D9B), letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: isPositive ? const Color(0xFF006C47) : const Color(0xFF434654)),
              if (icon != null) const SizedBox(width: 4),
              Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: isPositive ? const Color(0xFF006C47) : const Color(0xFF434654))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0052CC),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.event_rounded, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Upcoming Exam: Bio 301', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Final Term Assessment starts in 48 hours.', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC4D2FF),
                    foregroundColor: const Color(0xFF0052CC),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Review Exam Material', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
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
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D9B))));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        var classes = snapshot.data?.docs ?? [];
        
        if (_searchQuery.isNotEmpty) {
          classes = classes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final className = (data['name'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            return className.contains(_searchQuery) || description.contains(_searchQuery);
          }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
            final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                mainAxisExtent: 320, // Adjusted height to look more natural and remove excessive white space
              ),
              itemCount: classes.length + 1,
              itemBuilder: (context, index) {
                if (index == classes.length) {
                  return _buildCreateNewClassPlaceholder();
                }

                final classDoc = classes[index];
                final data = classDoc.data() as Map<String, dynamic>;
                return _buildClassCard(classDoc.id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreateNewClassPlaceholder() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCreateClassDialog,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFFF1F3FF),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC3C6D6), width: 2),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF9F9FF),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EDFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF434654), size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Create New Class', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF434654))),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Start a new semester or section for your students.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF434654), height: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  } 

  Widget _buildClassCard(String classId, Map<String, dynamic> data) {
    final isAlternate = classId.hashCode % 2 == 0;
    final headerColor = isAlternate ? const Color(0xFF1D3052) : const Color(0xFF0052CC);
    final headerTextColor = isAlternate ? const Color(0xFFEDF0FF) : const Color(0xFFC4D2FF);
    final headerTitleColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDetailPage(
                  classId: classId,
                  className: data['name'] ?? 'Lớp học',
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 128,
                padding: const EdgeInsets.all(16),
                color: headerColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF82F9BE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006C47), letterSpacing: 0.5)),
                        ),
                        PopupMenuButton(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                                  SizedBox(width: 12),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                  SizedBox(width: 12),
                                  Text('Xóa', style: TextStyle(color: Colors.red)),
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
                    const Spacer(),
                    Text(
                      data['name'] ?? 'Lớp học',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20, color: headerTitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((data['description'] ?? '').toString().isNotEmpty)
                      Text(
                        data['description'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: headerTextColor),
                      ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STUDENTS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF434654))),
                              Text('${data['studentCount'] ?? 0}', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF041B3C))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('AVG. SCORE', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF434654))),
                              Text('${(data['averageScore'] as num?)?.toInt() ?? 0}%', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF006C47))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EDFF),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text('+${data['studentCount'] ?? 0}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF434654))),
                          ),
                        ],
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassDetailPage(
                                classId: classId,
                                className: data['name'] ?? 'Lớp học',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF003D9B)),
                          foregroundColor: const Color(0xFF003D9B),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Manage Class', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateClassDialog() {
    _classNameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
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
                        color: const Color(0xFFE8EDFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.class_outlined, color: Color(0xFF003D9B), size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Tạo lớp học mới',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF041B3C),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _classNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên lớp',
                    labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654)),
                    hintText: 'VD: Toán 10A1',
                    hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF737685)),
                    prefixIcon: const Icon(Icons.class_rounded, color: Color(0xFF737685)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 2)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FF),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên lớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654)),
                    hintText: 'VD: Lớp học Toán nâng cao',
                    hintStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF737685)),
                    prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF737685)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 2)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FF),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFC3C6D6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Hủy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF041B3C))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _createClass,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF003D9B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tạo lớp', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditClassDialog(String classId, Map<String, dynamic> data) {
    _classNameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
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
                        color: const Color(0xFFE8EDFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined, color: Color(0xFF003D9B), size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa lớp học',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF041B3C),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _classNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên lớp',
                    labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654)),
                    prefixIcon: const Icon(Icons.class_rounded, color: Color(0xFF737685)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 2)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FF),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên lớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF434654)),
                    prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF737685)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC3C6D6))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003D9B), width: 2)),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FF),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFC3C6D6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Hủy', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF041B3C))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _updateClass(classId),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF003D9B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Lưu', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';

      await FirebaseFirestore.instance.collection('classes').add({
        'name': _classNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'teacherId': teacherId,
        'studentCount': 0,
        'quizCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Tạo lớp học thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateClass(String classId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({
        'name': _classNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cập nhật lớp học thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteClass(String classId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác nhận xóa',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc muốn xóa lớp "${data['name']}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hành động này sẽ:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Xóa lớp học\n'
                      '• Xóa tất cả học sinh trong lớp\n'
                      '• Không thể hoàn tác!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF9A3412),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
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
      ),
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
                Text('Đã xóa lớp học'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

}

class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({this.color = Colors.black, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = size.width;
    double y = size.height;

    Path _topPath = _getDashedPath(
      a: const Offset(0, 0),
      b: Offset(x, 0),
      gap: gap,
    );

    Path _rightPath = _getDashedPath(
      a: Offset(x, 0),
      b: Offset(x, y),
      gap: gap,
    );

    Path _bottomPath = _getDashedPath(
      a: Offset(x, y),
      b: Offset(0, y),
      gap: gap,
    );

    Path _leftPath = _getDashedPath(
      a: Offset(0, y),
      b: const Offset(0, 0),
      gap: gap,
    );

    canvas.drawPath(_topPath, dashedPaint);
    canvas.drawPath(_rightPath, dashedPaint);
    canvas.drawPath(_bottomPath, dashedPaint);
    canvas.drawPath(_leftPath, dashedPaint);
  }

  Path _getDashedPath({required Offset a, required Offset b, required double gap}) {
    Size size = Size(b.dx - a.dx, b.dy - a.dy);
    Path path = Path();
    path.moveTo(a.dx, a.dy);

    bool shouldDraw = true;
    math.Point currentPoint = math.Point(a.dx, a.dy);

    num radians = math.atan(size.height / size.width);

    num dx = math.cos(radians) * gap < 0
        ? math.cos(radians) * gap * -1
        : math.cos(radians) * gap;

    num dy = math.sin(radians) * gap < 0
        ? math.sin(radians) * gap * -1
        : math.sin(radians) * gap;

    while (currentPoint.x <= b.dx && currentPoint.y <= b.dy) {
      shouldDraw
          ? path.lineTo(currentPoint.x.toDouble(), currentPoint.y.toDouble())
          : path.moveTo(currentPoint.x.toDouble(), currentPoint.y.toDouble());
      shouldDraw = !shouldDraw;
      currentPoint = math.Point(
        currentPoint.x + dx,
        currentPoint.y + dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
