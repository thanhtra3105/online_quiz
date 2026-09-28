// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/student/class_list_page.dart';
import 'screens/teacher/teacher_panel.dart';
import 'services/user_service.dart';
import 'services/auth_sync_service.dart';
import 'services/quiz_schedule_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'utils/theme_provider.dart';

// IMPORT CÁC TRANG NGÂN HÀNG CÂU HỎI
import 'screens/teacher/quiz_bank_list_page.dart';
import 'screens/teacher/question_bank_create_page.dart'; // ✨ ĐỔI TÊN FILE
import 'screens/teacher/quiz_create_from_bank_page.dart';
import 'screens/teacher/quiz_bank_question_selector_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔄 KHỞI ĐỘNG SERVICE ĐỒNG BỘ TỰ ĐỘNG
  // Từ giờ, mọi thay đổi trong Authentication sẽ tự động sync sang Firestore
  AuthSyncService.initialize();
  QuizScheduleService.startScheduler();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Student Quiz App',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9F9FF),
            colorScheme: const ColorScheme(
              brightness: Brightness.light,
              primary: Color(0xFF003D9B),
              onPrimary: Color(0xFFFFFFFF),
              primaryContainer: Color(0xFF0052CC),
              onPrimaryContainer: Color(0xFFC4D2FF),
              secondary: Color(0xFF006C47),
              onSecondary: Color(0xFFFFFFFF),
              secondaryContainer: Color(0xFF82F9BE),
              onSecondaryContainer: Color(0xFF00734C),
              tertiary: Color(0xFF851800),
              onTertiary: Color(0xFFFFFFFF),
              tertiaryContainer: Color(0xFFB02300),
              onTertiaryContainer: Color(0xFFFFC6B9),
              error: Color(0xFFBA1A1A),
              onError: Color(0xFFFFFFFF),
              errorContainer: Color(0xFFFFDAD6),
              onErrorContainer: Color(0xFF93000A),
              background: Color(0xFFF9F9FF),
              onBackground: Color(0xFF041B3C),
              surface: Color(0xFFFFFFFF),
              onSurface: Color(0xFF041B3C),
              surfaceVariant: Color(0xFFD7E2FF),
              onSurfaceVariant: Color(0xFF434654),
              outline: Color(0xFF737685),
              outlineVariant: Color(0xFFC3C6D6),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121418),
            colorScheme: const ColorScheme(
              brightness: Brightness.dark,
              primary: Color(0xFF6B9BFF),
              onPrimary: Color(0xFFFFFFFF),
              primaryContainer: Color(0xFF1E3A70),
              onPrimaryContainer: Color(0xFFD8E4FF),
              secondary: Color(0xFF34D399),
              onSecondary: Color(0xFFFFFFFF),
              secondaryContainer: Color(0xFF064E3B),
              onSecondaryContainer: Color(0xFFA7F3D0),
              tertiary: Color(0xFFFB923C),
              onTertiary: Color(0xFFFFFFFF),
              tertiaryContainer: Color(0xFF7C2D12),
              onTertiaryContainer: Color(0xFFFFEDD5),
              error: Color(0xFFF87171),
              onError: Color(0xFFFFFFFF),
              errorContainer: Color(0xFF7F1D1D),
              onErrorContainer: Color(0xFFFECACA),
              background: Color(0xFF121418),
              onBackground: Color(0xFFF1F3F7),
              surface: Color(0xFF1E2128),
              onSurface: Color(0xFFF1F3F7),
              surfaceVariant: Color(0xFF282C37),
              onSurfaceVariant: Color(0xFF9EA3B0),
              outline: Color(0xFF5A606E),
              outlineVariant: Color(0xFF2F333D),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.textScaleFactor),
                ),
                child: child!,
              );
            },
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,

      // ✨ THÊM ROUTES Ở ĐÂY
      routes: {
        '/quiz_bank_list': (context) => const QuizBankListPage(),
        '/question_bank_create': (context) =>
            const QuestionBankCreatePage(), // ✨ ĐỔI TÊN
      },

      // ✨ THÊM onGenerateRoute ĐỂ XỬ LÝ ROUTES CÓ ARGUMENTS
      onGenerateRoute: (settings) {
        // Route: /quiz_create_from_bank
        if (settings.name == '/quiz_create_from_bank') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => QuizCreateFromBankPage(
              bankId: args['bankId'] as String,
              bankTitle: args['bankTitle'] as String,
              questionCount: args['questionCount'] as int,
            ),
          );
        }

        // Route: /quiz_bank_question_selector
        if (settings.name == '/quiz_bank_question_selector') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => QuizBankQuestionSelectorPage(
              bankId: args['bankId'] as String,
              bankTitle: args['bankTitle'] as String,
              quizTitle: args['quizTitle'] as String,
              duration: args['duration'] as int,
              maxViolations: args['maxViolations'] as int,
            ),
          );
        }

        // Route không tìm thấy
        return null;
      },
          );
        },
      );
  }
}

/// Widget tự động đồng bộ Authentication với Firestore
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<String?>? _roleFuture;
  String? _lastUserId;

  @override
  void dispose() {
    // Cleanup khi app đóng
    AuthSyncService.dispose();
    super.dispose();
  }

  Future<String?> _getRoleCached(User user, String studentId) {
    if (_roleFuture == null || _lastUserId != user.uid) {
      _lastUserId = user.uid;
      _roleFuture = _syncAndGetRole(user, studentId);
    }
    return _roleFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang kiểm tra trạng thái đăng nhập
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang khởi động...'),
                ],
              ),
            ),
          );
        }

        // Chưa đăng nhập
        if (!snapshot.hasData || snapshot.data == null) {
          print('❌ No user logged in');
          return const LoginPage();
        }

        final user = snapshot.data!;
        print('👤 User logged in: ${user.uid}');
        print('📧 Email: ${user.email}');

        // Trích xuất studentId từ email
        final studentId = UserService.extractStudentId(user.email);

        if (studentId.isEmpty) {
          print('❌ Cannot extract student ID from email');
          return _buildErrorScreen(
            context,
            title: 'Email không hợp lệ',
            message:
                'Email không chứa mã sinh viên hợp lệ (cần 9 chữ số).\nVui lòng sử dụng email sinh viên.',
            showRetry: false,
          );
        }

        print('🎓 Student ID: $studentId');

        // Đã đăng nhập - đồng bộ với Firestore và lấy role
        return FutureBuilder<String?>(
          future: _getRoleCached(user, studentId),
          builder: (context, roleSnapshot) {
            // Đang đồng bộ và lấy role
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Đang đồng bộ dữ liệu...'),
                      SizedBox(height: 8),
                      Text(
                        '🔄 Authentication → Firestore',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Có lỗi khi đồng bộ
            if (roleSnapshot.hasError) {
              print('❌ Error syncing: ${roleSnapshot.error}');
              return _buildErrorScreen(
                context,
                title: 'Lỗi đồng bộ',
                message:
                    'Không thể đồng bộ với máy chủ.\nVui lòng kiểm tra kết nối và thử lại.',
                onRetry: () => setState(() {}),
              );
            }

            final role = roleSnapshot.data;
            print('🎭 Role detected: $role');

            // Không có role hoặc role rỗng
            if (role == null || role.isEmpty) {
              print('⚠️ No role found after sync');
              return _buildErrorScreen(
                context,
                title: 'Không tìm thấy vai trò',
                message:
                    'Tài khoản chưa được gán vai trò.\nVui lòng liên hệ quản trị viên.',
                showRetry: false,
              );
            }

            // Chuyển hướng dựa trên role
            print('✅ Redirecting to $role panel');
            print('   Using Student ID: $studentId');
            print(
              '   ✨ Auto-sync enabled - changes will be reflected automatically',
            );

            if (role == 'student') {
              return ClassListPage(studentId: studentId);
            } else if (role == 'teacher') {
              return const TeacherPanel();
            } else {
              // Role không hợp lệ
              print('⚠️ Invalid role: $role');
              return _buildErrorScreen(
                context,
                title: 'Vai trò không hợp lệ',
                message:
                    'Vai trò "$role" không được hỗ trợ.\nVui lòng liên hệ quản trị viên.',
                showRetry: false,
              );
            }
          },
        );
      },
    );
  }

  /// Đồng bộ và lấy role
  Future<String?> _syncAndGetRole(User user, String studentId) async {
    try {
      // Bước 1: Kiểm tra và đồng bộ nếu data cũ
      print('🔍 Checking if sync needed...');
      final wasSynced = await AuthSyncService.checkAndSyncIfOutdated(studentId);

      if (wasSynced) {
        print('✅ Data was synced from Authentication');
      } else {
        print('✅ Data already up to date');
      }

      // Bước 2: Đồng bộ đầy đủ (đảm bảo)
      final role = await UserService.syncUserAndGetRole(user);

      return role;
    } catch (e) {
      print('❌ Error in sync and get role: $e');
      rethrow;
    }
  }

  /// Widget hiển thị màn hình lỗi
  Widget _buildErrorScreen(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    bool showRetry = true,
  }) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.orange[300]),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Nút thử lại
              if (showRetry && onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

              if (showRetry && onRetry != null) const SizedBox(height: 16),

              // Nút đồng bộ thủ công
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await AuthSyncService.forceSyncCurrentUser();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã đồng bộ thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    if (onRetry != null) onRetry();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Lỗi đồng bộ: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.sync),
                label: const Text('Đồng bộ thủ công'),
              ),

              const SizedBox(height: 16),

              // Nút đăng xuất
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await UserService.clearUserCache();
                },
                child: const Text('Đăng xuất'),
              ),

              // Debug info
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đồng bộ tự động đã bật',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Authentication ↔️ Firestore',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// HƯỚNG DẪN SỬ DỤNG AUTO-SYNC
// ============================================
//
// Service đồng bộ tự động đã được kích hoạt:
//
// 1. ✅ Khi user đăng nhập → Tự động tạo/cập nhật Firestore
// 2. ✅ Khi email thay đổi → Tự động sync sang Firestore
// 3. ✅ Khi displayName thay đổi → Tự động sync sang Firestore
// 4. ✅ Khi emailVerified thay đổi → Tự động sync sang Firestore
// 5. ✅ Khi user đăng xuất → Đánh dấu inactive trong Firestore
//
// CÁCH ĐỒNG BỘ THỦ CÔNG (nếu cần):
//
// // Đồng bộ current user
// await AuthSyncService.forceSyncCurrentUser();
//
// // Đồng bộ một user cụ thể
// final user = FirebaseAuth.instance.currentUser;
// if (user != null) {
//   await AuthSyncService.forceSyncUser(user);
// }
//
// // Kiểm tra và đồng bộ nếu cần
// await AuthSyncService.checkAndSyncIfOutdated(studentId);
//
// ============================================
