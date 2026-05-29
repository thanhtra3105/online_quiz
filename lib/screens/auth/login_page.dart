// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../student/class_list_page.dart';
import '../teacher/teacher_panel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    super.dispose();
  }

  /// Xử lý đăng nhập Microsoft
  Future<void> _handleMicrosoftLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔐 Attempting Microsoft login...');

      // Tạo Microsoft Provider
      final microsoftProvider = OAuthProvider('microsoft.com');

      // Thêm các scope cần thiết
      microsoftProvider.addScope('email');
      microsoftProvider.addScope('profile');

      // Force account selection
      microsoftProvider.setCustomParameters({
        'prompt': 'select_account',
        'login_hint': '',
      });

      UserCredential? userCredential;

      // Kiểm tra platform và sử dụng method phù hợp
      if (kIsWeb) {
        print('🌐 Using signInWithPopup for Web');
        userCredential = await _auth.signInWithPopup(microsoftProvider);
      } else {
        print('📱 Using signInWithProvider for Mobile/Desktop');
        userCredential = await _auth.signInWithProvider(microsoftProvider);
      }

      if (userCredential?.user == null) {
        throw Exception('Đăng nhập Microsoft thất bại');
      }

      final user = userCredential!.user!;
      print('✅ Microsoft authentication successful: ${user.uid}');
      print('📧 Email: ${user.email}');
      print('👤 Display Name: ${user.displayName}');

      // Xử lý đăng nhập thành công
      await _handleSuccessfulLogin(user);
    } on FirebaseAuthException catch (e) {
      print('❌ Microsoft Auth Error: ${e.code}');
      setState(() {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            _errorMessage =
                'Tài khoản đã tồn tại với phương thức đăng nhập khác. Vui lòng đăng nhập bằng email/password.';
            break;
          case 'invalid-credential':
            _errorMessage = 'Thông tin đăng nhập Microsoft không hợp lệ';
            break;
          case 'operation-not-allowed':
            _errorMessage =
                'Đăng nhập Microsoft chưa được kích hoạt. Vui lòng liên hệ quản trị viên.';
            break;
          case 'user-disabled':
            _errorMessage = 'Tài khoản đã bị vô hiệu hóa';
            break;
          case 'popup-closed-by-user':
            _errorMessage = 'Đăng nhập bị hủy bỏ';
            break;
          case 'popup-blocked':
            _errorMessage =
                'Trình duyệt đã chặn popup. Vui lòng cho phép popup và thử lại.';
            break;
          default:
            _errorMessage = 'Đăng nhập Microsoft thất bại: ${e.message}';
        }
      });
    } catch (e) {
      print('❌ General Error: $e');
      setState(() {
        _errorMessage =
            'Có lỗi xảy ra với đăng nhập Microsoft. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Xử lý sau khi đăng nhập thành công - UPDATED
  Future<void> _handleSuccessfulLogin(User user) async {
    print('🔄 Syncing with Firestore...');

    // 🆕 Không cần check studentId nữa - cho phép tất cả email hợp lệ
    final email = user.email;

    if (email == null || email.isEmpty) {
      setState(() {
        _errorMessage = 'Email không hợp lệ. Vui lòng thử lại.';
      });
      await _auth.signOut();
      return;
    }

    print('📧 Email: $email');

    // Sync và lấy role
    final role = await UserService.syncUserAndGetRole(user);

    if (role == null || role.isEmpty) {
      setState(() {
        _errorMessage = 'Không thể xác định vai trò. Vui lòng thử lại.';
      });
      await _auth.signOut();
      return;
    }

    print('✅ Role confirmed: $role');

    // 🆕 Lấy userId (có thể là studentId hoặc email encoded)
    final userId = await UserService.getUserId(user);

    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = 'Không thể tạo ID người dùng. Vui lòng thử lại.';
      });
      await _auth.signOut();
      return;
    }

    print('🆔 User ID: $userId');

    // Chuyển trang dựa trên role
    if (mounted) {
      print('🚀 Navigating to $role panel');

      if (role == 'student') {
        // 🆕 Với sinh viên, cần có studentId
        final studentId = await UserService.getStudentId(user);

        if (studentId == null || studentId.isEmpty) {
          setState(() {
            _errorMessage = 'Email sinh viên phải chứa 9 chữ số mã sinh viên.';
          });
          await _auth.signOut();
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ClassListPage(studentId: studentId),
          ),
          (route) => false,
        );
      } else {
        // Giáo viên vào teacher panel
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TeacherPanel()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Decorative Background Element 1
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Decorative Background Element 2
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QuizMaster',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration / Logo Section
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chào mừng trở lại!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sử dụng tài khoản Microsoft do trường cấp để đăng nhập vào hệ thống thi trực tuyến.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Login Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Nút đăng nhập Microsoft
                          OutlinedButton(
                            onPressed: _isLoading ? null : _handleMicrosoftLogin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                                width: 1,
                              ),
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CustomPaint(
                                          painter: MicrosoftLogoPainter(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Đăng nhập với Microsoft',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Info text
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dành cho Sinh viên & Giảng viên',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'SV: Email chứa 9 chữ số MSSV\nGV: Email @dut.udn.vn',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '© 2024 QuizMaster Educational Suite.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter để vẽ logo Microsoft
class MicrosoftLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 2.2;
    final gap = size.width * 0.08;

    // Ô đỏ (trên trái)
    final redPaint = Paint()..color = const Color(0xFFF25022);
    canvas.drawRect(Rect.fromLTWH(0, 0, squareSize, squareSize), redPaint);

    // Ô xanh lá (trên phải)
    final greenPaint = Paint()..color = const Color(0xFF7FBA00);
    canvas.drawRect(
      Rect.fromLTWH(squareSize + gap, 0, squareSize, squareSize),
      greenPaint,
    );

    // Ô xanh dương (dưới trái)
    final bluePaint = Paint()..color = const Color(0xFF00A4EF);
    canvas.drawRect(
      Rect.fromLTWH(0, squareSize + gap, squareSize, squareSize),
      bluePaint,
    );

    // Ô vàng (dưới phải)
    final yellowPaint = Paint()..color = const Color(0xFFFEB902);
    canvas.drawRect(
      Rect.fromLTWH(squareSize + gap, squareSize + gap, squareSize, squareSize),
      yellowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
