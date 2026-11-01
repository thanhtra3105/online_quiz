// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Trích xuất 9 chữ số đầu từ email làm studentId/userId
  static String extractStudentId(String? email) {
    if (email == null || email.isEmpty) return '';

    final parts = email.split('@');
    if (parts.isEmpty) return '';

    // Lấy phần trước @
    final username = parts[0];

    // Trích xuất 9 chữ số đầu tiên
    final digits = username.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 9) {
      return digits.substring(0, 9);
    }

    return digits;
  }

  /// 🆕 Tạo userId từ email - dùng cho cả SV và GV
  /// - Sinh viên: 9 chữ số từ email
  /// - Giáo viên: email hoặc phần username
  static String createUserId(String? email) {
    if (email == null || email.isEmpty) return '';

    // Thử extract studentId trước (cho sinh viên)
    final studentId = extractStudentId(email);
    if (studentId.isNotEmpty && studentId.length >= 9) {
      return studentId;
    }

    // Nếu không có 9 chữ số -> là giáo viên
    // Dùng email làm userId (hoặc có thể dùng username)
    return email.replaceAll('@', '_').replaceAll('.', '_');
  }

  /// 🆕 Xác định role từ email TRƯỚC KHI sync
  /// ƯU TIÊN: Kiểm tra Giảng viên trước -> rồi mới đến Sinh viên
  static String determineRoleFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'student';

    final emailLower = email.toLowerCase().trim();

    // ==========================================================
    // BƯỚC 1: KIỂM TRA TÀI KHOẢN GIẢNG VIÊN TRƯỚC
    // ==========================================================

    // 1.1. Check các từ khóa giảng viên trong email (ưu tiên cao)
    final teacherKeywords = [
      'teacher',
      'admin',
      'gv',
      'giangvien',
      'giaovien',
      'instructor',
      'professor',
      'nvhieu.dtvt', // Thầy Hiếu
      'ddtuan',      // Thầy Tuấn
    ];

    for (var keyword in teacherKeywords) {
      if (emailLower.contains(keyword)) {
        print('👨‍🏫 [1/Teacher] Phát hiện từ khóa giảng viên "$keyword" -> teacher');
        return 'teacher';
      }
    }

    final studentId = extractStudentId(emailLower);
    final hasStudentId = studentId.isNotEmpty && studentId.length >= 9;

    // 1.2. Check domain email giảng viên trường UDN (@dut.udn.vn, @ued.udn.vn, @udn.vn...)
    // Email giảng viên có domain trực tiếp, không chứa sub-domain sinh viên @sv. hay @sv1.
    final isTeacherDomain = (emailLower.endsWith('@dut.udn.vn') ||
                             emailLower.endsWith('@ued.udn.vn')) &&
                            !emailLower.contains('@sv.') &&
                            !emailLower.contains('@sv1.');

    if (isTeacherDomain) {
      print('Phát hiện domain giảng viên');
      if (!hasStudentId) {
        print('🎓 [1/Teacher] Email domain giảng viên ($emailLower) -> teacher');
        return 'teacher';
      }
    }

    // ==========================================================
    // BƯỚC 2: MỚI ĐẾN KIỂM TRA TÀI KHOẢN SINH VIÊN
    // ==========================================================
    // Sinh viên DUT/UED có 9 chữ số MSSV trong email hoặc có @sv. / @sv1.
    if (hasStudentId || emailLower.contains('@sv.') || emailLower.contains('@sv1.')) {
      print('👨‍🎓 [2/Student] Tài khoản sinh viên ($studentId) -> student');
      return 'student';
    }

    // ==========================================================
    // BƯỚC 3: MẶC ĐỊNH
    // ==========================================================
    // Nếu không có 9 chữ số MSSV -> Mặc định là giảng viên
    print('👨‍🏫 [3/Fallback] Không có mã sinh viên 9 chữ số -> assuming teacher');
    return 'teacher';
  }

  /// Đồng bộ user từ Authentication sang Firestore
  /// SỬ DỤNG userId (9 chữ số cho SV, email cho GV) LÀM DOCUMENT ID
  static Future<String?> syncUserAndGetRole(User user) async {
    try {
      print('🔄 [UserService] Syncing user: ${user.uid}');
      print('📧 Email: ${user.email}');

      // 🆕 Xác định role TRƯỚC để biết cách xử lý
      final detectedRole = determineRoleFromEmail(user.email);
      print('🎭 Detected role: $detectedRole');

      // 🆕 Tạo userId phù hợp
      final userId = createUserId(user.email);

      if (userId.isEmpty) {
        print('❌ Cannot create userId from email: ${user.email}');
        throw Exception('Email không hợp lệ');
      }

      print('🆔 User ID: $userId');

      // Sử dụng userId làm document ID
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      String role;

      // Chuẩn bị data đồng bộ từ Authentication
      final authData = {
        'authUid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? _extractDisplayName(user),
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'phoneNumber': user.phoneNumber,
        'isActive': true,
        'lastLogin': FieldValue.serverTimestamp(),
        'lastSyncAt': FieldValue.serverTimestamp(),
      };

      if (doc.exists) {
        // Document đã tồn tại - cập nhật data từ Authentication
        final data = doc.data()!;
        role = data['role'] as String? ?? detectedRole;

        print('✅ User exists in Firestore with role: $role');
        print('🔄 Updating with latest Authentication data...');

        // Cập nhật thông tin từ Authentication + giữ nguyên role và metadata
        await docRef.update({
          ...authData,
          'role': role, // Giữ nguyên role từ Firestore
          'userId': userId, // Giữ nguyên userId
        });

        print('✅ Synced from Authentication → Firestore');
      } else {
        // Document chưa tồn tại - tạo mới
        print('🆕 Creating new user document in Firestore');
        print('   User ID (Document ID): $userId');
        print('   Auth UID: ${user.uid}');
        print('   Email: ${user.email}');

        // Sử dụng role đã detect
        role = detectedRole;

        // 🆕 Thêm field để phân biệt SV và GV
        final studentId = extractStudentId(user.email);
        final isStudent = studentId.isNotEmpty && studentId.length >= 9;

        try {
          await docRef.set({
            ...authData,
            'userId': userId, // Trùng với document ID
            'studentId': isStudent
                ? studentId
                : null, // Chỉ có khi là sinh viên
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });

          print('✅ User document created successfully!');
          print('   Document ID (User ID): $userId');
          print('   Role: $role');
          print('   Is Student: $isStudent');
          print('   ✨ Future changes in Authentication will auto-sync');

          // Verify document was created
          final verifyDoc = await docRef.get();
          if (verifyDoc.exists) {
            print('✅ Document verified in Firestore');
          } else {
            print(
              '⚠️ Document not found after creation - possible permissions issue',
            );
          }
        } catch (createError) {
          print('❌ Error creating user document: $createError');
          print('   This might be a Firestore rules issue');
          rethrow;
        }
      }

      // Cache vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      await prefs.setString('user_id', userId);
      await prefs.setString('auth_uid', user.uid);
      await prefs.setString('user_email', user.email ?? '');

      // Cache studentId nếu có
      final studentId = extractStudentId(user.email);
      if (studentId.isNotEmpty && studentId.length >= 9) {
        await prefs.setString('student_id', studentId);
      }

      print('💾 Role and IDs cached locally');
      print('✨ Auto-sync is active: Authentication ↔️ Firestore');

      return role;
    } catch (e) {
      print('❌ Error syncing user: $e');

      // Thử lấy từ cache nếu có lỗi
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString('user_role');
        final cachedEmail = prefs.getString('user_email');

        if (cachedRole != null && cachedEmail == user.email) {
          print('⚠️ Using cached role due to error: $cachedRole');
          return cachedRole;
        }
      } catch (_) {}

      return null;
    }
  }

  /// Trích xuất tên hiển thị từ email hoặc displayName
  static String _extractDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null) {
      // Lấy phần trước @ làm tên
      final username = user.email!.split('@')[0];
      // Capitalize chữ cái đầu
      return username.substring(0, 1).toUpperCase() + username.substring(1);
    }

    return 'User';
  }

  /// Lấy role từ Firestore bằng userId
  static Future<String?> getUserRole(String userId) async {
    try {
      print('🔍 Getting role for user: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final role = doc.data()?['role'] as String?;
        print('✅ Role found: $role');

        // Cache
        if (role != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);
          await prefs.setString('user_id', userId);
        }

        return role;
      }

      print('⚠️ User document not found');

      // Thử lấy từ cache
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('user_role');
      final cachedUserId = prefs.getString('user_id');

      if (cachedRole != null && cachedUserId == userId) {
        print('📦 Using cached role: $cachedRole');
        return cachedRole;
      }

      return null;
    } catch (e) {
      print('❌ Error getting user role: $e');

      // Fallback: cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRole = prefs.getString('user_role');
        final cachedUserId = prefs.getString('user_id');

        if (cachedRole != null && cachedUserId == userId) {
          print('📦 Returning cached role despite error: $cachedRole');
          return cachedRole;
        }
      } catch (_) {}

      return null;
    }
  }

  /// 🆕 Lấy userId từ Auth User
  static Future<String?> getUserId(User user) async {
    final userId = createUserId(user.email);
    return userId.isNotEmpty ? userId : null;
  }

  /// Lấy studentId từ Auth User (chỉ cho sinh viên)
  static Future<String?> getStudentId(User user) async {
    final studentId = extractStudentId(user.email);
    return (studentId.isNotEmpty && studentId.length >= 9) ? studentId : null;
  }

  /// Lấy userId từ AuthUID (tìm trong Firestore)
  static Future<String?> getUserIdFromAuthUid(String authUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('authUid', isEqualTo: authUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // Document ID = userId
      }

      return null;
    } catch (e) {
      print('❌ Error getting userId from authUid: $e');
      return null;
    }
  }

  /// Set role cho user (cho admin)
  static Future<void> setUserRole(String userId, String role) async {
    try {
      print('🔧 Setting role for user: $userId to $role');

      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật cache
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('user_id') == userId) {
        await prefs.setString('user_role', role);
      }

      print('✅ Role updated successfully');
    } catch (e) {
      print('❌ Error setting role: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user đầy đủ
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        print('📋 User profile loaded:');
        print('   User ID: ${data['userId']}');
        print('   Email: ${data['email']}');
        print('   Role: ${data['role']}');
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Cập nhật profile user
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Loại bỏ các field được sync từ Authentication
      final updatableData = Map<String, dynamic>.from(data);
      updatableData.remove('authUid');
      updatableData.remove('email');
      updatableData.remove('displayName');
      updatableData.remove('photoURL');
      updatableData.remove('emailVerified');
      updatableData.remove('phoneNumber');

      print('📝 Updating user profile (non-auth fields only)');

      await _firestore.collection('users').doc(userId).update({
        ...updatableData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User profile updated');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Đánh dấu user inactive khi đăng xuất
  static Future<void> markUserInactive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'lastLogout': FieldValue.serverTimestamp(),
      });
      print('✅ User marked as inactive');
    } catch (e) {
      print('⚠️ Could not mark user inactive: $e');
    }
  }

  /// Xóa cache local khi đăng xuất
  static Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      // Đánh dấu inactive trong Firestore
      if (userId != null) {
        await markUserInactive(userId);
      }

      // Xóa cache
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('auth_uid');
      await prefs.remove('user_email');
      await prefs.remove('student_id');

      print('✅ User cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Kiểm tra user có tồn tại trong Firestore không
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  /// Tạo hoặc cập nhật user document (dùng cho admin)
  static Future<void> createOrUpdateUser({
    required String email,
    required String role,
    String? displayName,
    String? authUid,
  }) async {
    try {
      final userId = createUserId(email);

      if (userId.isEmpty) {
        throw Exception('Cannot create userId from email: $email');
      }

      final studentId = extractStudentId(email);
      final isStudent = studentId.isNotEmpty && studentId.length >= 9;

      await _firestore.collection('users').doc(userId).set({
        'authUid': authUid,
        'userId': userId,
        'studentId': isStudent ? studentId : null,
        'email': email,
        'role': role,
        'displayName': displayName ?? email.split('@')[0],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User created/updated successfully');
      print('   Document ID (User ID): $userId');
      print('   Role: $role');
    } catch (e) {
      print('❌ Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Lấy sync status của user
  static Future<Map<String, dynamic>> getSyncStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return {'synced': false, 'message': 'User document not found'};
      }

      final data = doc.data()!;
      final lastSync = data['lastSyncAt'] as Timestamp?;
      final lastLogin = data['lastLogin'] as Timestamp?;

      return {
        'synced': true,
        'lastSyncAt': lastSync?.toDate().toString() ?? 'Never',
        'lastLogin': lastLogin?.toDate().toString() ?? 'Never',
        'email': data['email'],
        'emailVerified': data['emailVerified'] ?? false,
        'role': data['role'],
        'isActive': data['isActive'] ?? false,
      };
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {'synced': false, 'error': e.toString()};
    }
  }
}
