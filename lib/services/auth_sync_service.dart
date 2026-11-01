// lib/services/auth_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'user_service.dart';

/// Service đồng bộ thay đổi từ Firebase Authentication sang Firestore
/// Mọi thay đổi ở Authentication sẽ tự động sync sang Firestore
class AuthSyncService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static StreamSubscription<User?>? _authStateSubscription;
  static StreamSubscription<User?>? _userChangesSubscription;

  /// Khởi động service đồng bộ
  /// Gọi hàm này trong main() để bắt đầu lắng nghe thay đổi
  static void initialize() {
    print('🔄 Initializing Auth Sync Service...');

    // Lắng nghe auth state changes (login/logout)
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

    // Lắng nghe user changes (email, displayName, etc.)
    _userChangesSubscription = _auth.userChanges().listen(_onUserChanged);

    print('✅ Auth Sync Service initialized');
  }

  /// Dừng service đồng bộ
  static Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    await _userChangesSubscription?.cancel();
    print('🛑 Auth Sync Service disposed');
  }

  /// Xử lý khi auth state thay đổi (login/logout)
  static Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      print('🚪 User logged out - no sync needed');
      return;
    }

    print('🔐 Auth state changed for user: ${user.uid}');
    print('📧 Email: ${user.email}');

    try {
      // Đồng bộ ngay khi user đăng nhập
      await syncAuthToFirestore(user);
    } catch (e) {
      print('❌ Error in auth state sync: $e');
    }
  }

  /// Xử lý khi thông tin user thay đổi (email, displayName, photoURL, etc.)
  static Future<void> _onUserChanged(User? user) async {
    if (user == null) {
      print('🚪 User logged out - no sync needed');
      return;
    }

    print('🔄 User data changed: ${user.uid}');
    print('   Email: ${user.email}');
    print('   Display Name: ${user.displayName}');
    print('   Email Verified: ${user.emailVerified}');

    try {
      // Đồng bộ thay đổi sang Firestore
      await syncAuthToFirestore(user, isUpdate: true);
    } catch (e) {
      print('❌ Error in user change sync: $e');
    }
  }

  /// Đồng bộ dữ liệu từ Authentication sang Firestore
  /// Đây là hàm chính thực hiện việc sync
  static Future<void> syncAuthToFirestore(User user, {bool isUpdate = false}) async {
    try {
      print('📋 Syncing auth to Firestore...');
      print('   Auth UID: ${user.uid}');
      print('   Email: ${user.email}');

      // Trích xuất userId từ email (SV dùng mã SV 9 số, GV dùng email)
      final userId = UserService.createUserId(user.email);

      if (userId.isEmpty) {
        print('⚠️ Cannot extract user ID from email: ${user.email}');
        return;
      }

      final studentId = UserService.extractStudentId(user.email);
      final isStudent = studentId.isNotEmpty && studentId.length >= 9;

      print('   User ID: $userId (isStudent: $isStudent)');

      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();

      // Chuẩn bị dữ liệu đồng bộ từ Authentication
      final syncData = {
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
        // Document đã tồn tại - chỉ cập nhật các field từ Authentication
        print('🔄 Updating existing user document');

        final currentData = doc.data()!;

        // Giữ nguyên các field quan trọng từ Firestore (không ghi đè)
        final preservedData = {
          'role': currentData['role'], // Giữ nguyên role
          if (currentData.containsKey('studentId')) 'studentId': currentData['studentId'],
          'createdAt': currentData['createdAt'], // Giữ nguyên createdAt
        };

        // Merge dữ liệu: Auth data + Preserved data
        await docRef.update({
          ...syncData,
          ...preservedData,
        });

        print('✅ User document updated from Authentication');
      } else {
        // Document chưa tồn tại - tạo mới
        print('🆕 Creating new user document from Authentication');

        // Xác định role mặc định
        final role = UserService.determineRoleFromEmail(user.email);

        await docRef.set({
          ...syncData,
          'userId': userId,
          if (isStudent) 'studentId': studentId,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✅ User document created from Authentication');
        print('   Role: $role');
      }

    } catch (e) {
      print('❌ Error syncing auth to Firestore: $e');
      rethrow;
    }
  }

  /// Đồng bộ thủ công cho một user cụ thể
  static Future<void> forceSyncUser(User user) async {
    print('🔄 Force syncing user: ${user.uid}');
    await syncAuthToFirestore(user, isUpdate: true);
  }

  /// Đồng bộ thủ công cho current user
  static Future<void> forceSyncCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await forceSyncUser(user);
    } else {
      print('⚠️ No current user to sync');
    }
  }

  /// Trích xuất display name từ user
  static String _extractDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null) {
      final username = user.email!.split('@')[0];
      return username.substring(0, 1).toUpperCase() + username.substring(1);
    }

    return 'User';
  }

  /// Xác định role mặc định từ email
  static String _determineDefaultRole(String? email) {
    if (email == null) return 'student';

    final emailLower = email.toLowerCase();

    final teacherKeywords = [
      'teacher',
      'admin',
      'gv',
      'giangvien',
      'giaovien',
      'instructor',
      'professor',
      'giảng_viên',
    ];

    for (var keyword in teacherKeywords) {
      if (emailLower.contains(keyword)) {
        print('👨‍🏫 Detected teacher keyword: $keyword');
        return 'teacher';
      }
    }

    print('👨‍🎓 Default role: student');
    return 'student';
  }

  /// Lắng nghe thay đổi của một user cụ thể trong Authentication
  /// và tự động sync sang Firestore
  static StreamSubscription<User?> watchUserChanges(
      String authUid,
      Function(User?) onChanged,
      ) {
    print('👀 Watching changes for user: $authUid');

    return _auth.userChanges().listen((user) {
      if (user != null && user.uid == authUid) {
        print('🔔 Detected change for watched user: $authUid');
        syncAuthToFirestore(user, isUpdate: true);
        onChanged(user);
      }
    });
  }

  /// Kiểm tra và đồng bộ nếu data trong Firestore cũ hơn Authentication
  static Future<bool> checkAndSyncIfOutdated(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final currentUserId = UserService.createUserId(user.email);
      if (currentUserId != userId) return false;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        // Document không tồn tại - sync ngay
        await syncAuthToFirestore(user);
        return true;
      }

      final data = doc.data()!;

      // So sánh dữ liệu
      bool needsSync = false;

      if (data['email'] != user.email) {
        print('📧 Email changed: ${data['email']} → ${user.email}');
        needsSync = true;
      }

      if (data['displayName'] != user.displayName) {
        print('👤 Display name changed: ${data['displayName']} → ${user.displayName}');
        needsSync = true;
      }

      if (data['emailVerified'] != user.emailVerified) {
        print('✉️ Email verified status changed: ${data['emailVerified']} → ${user.emailVerified}');
        needsSync = true;
      }

      if (needsSync) {
        print('🔄 Data outdated - syncing...');
        await syncAuthToFirestore(user, isUpdate: true);
        return true;
      }

      print('✅ Firestore data is up to date');
      return false;
    } catch (e) {
      print('❌ Error checking sync status: $e');
      return false;
    }
  }

  /// Đồng bộ tất cả users từ Authentication sang Firestore
  /// CHỈ DÙNG CHO ADMIN/DEBUG
  static Future<void> syncAllUsersFromAuth() async {
    print('⚠️ WARNING: Syncing all users from Authentication to Firestore');
    print('   This should only be used by administrators');

    try {
      // Note: Firestore Admin SDK cần thiết để list tất cả users
      // Trong Flutter app, chỉ có thể sync current user
      final user = _auth.currentUser;

      if (user != null) {
        print('📋 Syncing current user only: ${user.uid}');
        await syncAuthToFirestore(user);
        print('✅ Current user synced');
      } else {
        print('⚠️ No user logged in to sync');
      }

      print('💡 TIP: To sync all users, use Firebase Admin SDK in Cloud Functions');
      print('   See the Cloud Function example in the comments below');

    } catch (e) {
      print('❌ Error syncing all users: $e');
    }
  }
}

// ============================================
// CLOUD FUNCTION ĐỂ ĐỒNG BỘ TỰ ĐỘNG
// ============================================
//
// Đặt code này trong Cloud Functions để tự động đồng bộ:
//
// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// admin.initializeApp();
//
// // Trigger khi user được tạo trong Authentication
// exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
//   console.log('New user created:', user.uid);
//
//   const email = user.email || '';
//   const studentId = extractStudentId(email);
//
//   if (!studentId) {
//     console.log('Cannot extract student ID from email:', email);
//     return;
//   }
//
//   const userData = {
//     authUid: user.uid,
//     studentId: studentId,
//     email: user.email || '',
//     displayName: user.displayName || email.split('@')[0],
//     photoURL: user.photoURL || null,
//     emailVerified: user.emailVerified,
//     phoneNumber: user.phoneNumber || null,
//     role: determineRole(email),
//     isActive: true,
//     createdAt: admin.firestore.FieldValue.serverTimestamp(),
//     lastLogin: admin.firestore.FieldValue.serverTimestamp(),
//   };
//
//   await admin.firestore()
//     .collection('users')
//     .doc(studentId)
//     .set(userData);
//
//   console.log('User synced to Firestore:', studentId);
// });
//
// // Trigger khi user bị xóa trong Authentication
// exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
//   console.log('User deleted:', user.uid);
//
//   const email = user.email || '';
//   const studentId = extractStudentId(email);
//
//   if (!studentId) return;
//
//   await admin.firestore()
//     .collection('users')
//     .doc(studentId)
//     .update({
//       isActive: false,
//       deletedAt: admin.firestore.FieldValue.serverTimestamp(),
//     });
//
//   console.log('User marked as deleted in Firestore:', studentId);
// });
//
// function extractStudentId(email) {
//   const username = email.split('@')[0];
//   const digits = username.replace(/[^0-9]/g, '');
//   return digits.length >= 9 ? digits.substring(0, 9) : '';
// }
//
// function determineRole(email) {
//   const emailLower = email.toLowerCase();
//   const teacherKeywords = ['teacher', 'admin', 'gv', 'giangvien'];
//   return teacherKeywords.some(k => emailLower.includes(k)) ? 'teacher' : 'student';
// }
//
// ============================================