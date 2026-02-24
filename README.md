# Student Quiz App - README

## 📚 Giới thiệu

**Student Quiz App** là ứng dụng thi trực tuyến được xây dựng bằng Flutter và Firebase, hỗ trợ giáo viên tạo và quản lý bài thi, đồng thời cho phép học sinh tham gia làm bài thi với hệ thống chống gian lận tích hợp.

## ✨ Tính năng chính

### 👨‍🏫 Dành cho Giáo viên

#### Quản lý Lớp học
- ✅ Tạo và quản lý nhiều lớp học
- ✅ Thêm học sinh thủ công hoặc import từ file Excel
- ✅ Xem danh sách học sinh và chỉnh sửa thông tin
- ✅ Theo dõi số lượng bài thi và học sinh

#### Quản lý Đề thi
- ✅ **Kho đề thi trung tâm**: Tạo và lưu trữ đề thi để tái sử dụng
- ✅ **Upload từ file**: Hỗ trợ PDF và TXT với format chuẩn
- ✅ **Tạo trực tiếp**: Tạo đề thi mới và gán vào lớp ngay lập tức
- ✅ **Chỉnh sửa**: Cập nhật câu hỏi, đáp án, thời gian làm bài
- ✅ **Cấu hình vi phạm**: Đặt số lần vi phạm tối đa (1-20 lần)

#### Lên lịch Bài thi
- ✅ **Đặt thời gian mở/đóng**: Lên lịch tự động mở và đóng bài thi
- ✅ **Mở/đóng thủ công**: Kiểm soát trạng thái bài thi theo thời gian thực
- ✅ **Hiển thị trạng thái**: Đã lên lịch, đang mở, đã đóng
- ✅ **Đếm ngược thời gian**: Hiển thị thời gian còn lại cho học sinh

#### Xem kết quả
- ✅ **Bảng kết quả chi tiết**: Xem điểm, thời gian, vi phạm của từng học sinh
- ✅ **Tìm kiếm và lọc**: Tìm theo mã học sinh, lọc theo bài thi
- ✅ **Sắp xếp linh hoạt**: Theo thời gian, điểm số, số lần vi phạm (tăng/giảm)
- ✅ **Xem bài làm**: Chi tiết từng câu trả lời, đúng/sai
- ✅ **Cảnh báo vi phạm**: Đánh dấu bài thi có hành vi khả nghi

### 👨‍🎓 Dành cho Học sinh

#### Tham gia Lớp học
- ✅ Đăng nhập bằng Microsoft Account (Email sinh viên)
- ✅ Tự động nhận diện mã sinh viên từ email
- ✅ Xem danh sách lớp học đã tham gia
- ✅ Giao diện thân thiện, dễ sử dụng

#### Làm bài thi
- ✅ **Xem bài thi khả dụng**: Danh sách bài thi chưa làm
- ✅ **Kiểm tra lịch trình**: Hiển thị trạng thái mở/đóng, thời gian còn lại
- ✅ **Làm bài fullscreen**: Bắt buộc chế độ toàn màn hình
- ✅ **Đếm ngược thời gian**: Timer hiển thị thời gian còn lại
- ✅ **Điều hướng câu hỏi**: Palette để nhảy đến câu bất kỳ
- ✅ **Theo dõi tiến độ**: Số câu đã làm/tổng số câu

#### Hệ thống Chống gian lận
- ⚠️ **Phát hiện chuyển tab/cửa sổ**: Cảnh báo khi rời khỏi trang thi
- ⚠️ **Phát hiện thoát fullscreen**: Cảnh báo và yêu cầu vào lại
- ⚠️ **Phát hiện thay đổi kích thước**: Cảnh báo khi resize window
- ⚠️ **Đếm số vi phạm**: Hiển thị số lần vi phạm/giới hạn
- ⚠️ **Cảnh báo cuối cùng**: Dialog đặc biệt trước vi phạm cuối
- ⚠️ **Tự động nộp bài**: Nộp bài ngay khi vượt quá số vi phạm cho phép
- ⚠️ **Ghi nhận vi phạm**: Lưu vào Firestore để giáo viên xem lại

#### Xem lịch sử
- ✅ Danh sách bài thi đã làm
- ✅ Xem lại điểm số và chi tiết bài làm
- ✅ So sánh đáp án đúng/sai

## 🛠️ Công nghệ sử dụng

### Frontend
- **Flutter 3.x**: Framework đa nền tảng (Web, Mobile, Desktop)
- **Material Design 3**: Giao diện hiện đại, responsive

### Backend & Database
- **Firebase Authentication**: Đăng nhập Microsoft OAuth
- **Cloud Firestore**: Database NoSQL thời gian thực
- **Firebase Storage**: Lưu trữ file (nếu cần)

### Thư viện bổ sung
- `firebase_auth`: Xác thực người dùng
- `cloud_firestore`: Tương tác Firestore
- `file_picker`: Chọn file PDF/TXT/Excel
- `syncfusion_flutter_pdf`: Đọc file PDF
- `unorm_dart`: Chuẩn hóa Unicode tiếng Việt
- `excel`: Đọc file Excel (.xlsx, .xls)

## 📁 Cấu trúc dự án

```
student_quiz_app/
│
├── lib/
│   ├── main.dart                          # Entry point của ứng dụng
│   │
│   ├── models/                            # Data models
│   │   ├── quiz_model.dart                # Quiz & Question models
│   │   ├── quiz_schedule_model.dart       # QuizSchedule model
│   │   └── submission_model.dart          # Submission model
│   │
│   ├── screens/                           # UI Screens
│   │   ├── auth/
│   │   │   └── login_page.dart            # Trang đăng nhập Microsoft
│   │   │
│   │   ├── student/                       # Student screens
│   │   │   ├── class_list_page.dart       # Danh sách lớp học
│   │   │   ├── student_panel.dart         # Bottom nav (Dashboard/Quiz/History)
│   │   │   ├── dashboard_page.dart        # Trang chủ học sinh
│   │   │   ├── quiz_list_page.dart        # Danh sách bài thi khả dụng
│   │   │   ├── quiz_taking_page.dart      # Trang làm bài thi (Anti-cheat)
│   │   │   ├── history_page.dart          # Lịch sử bài thi đã làm
│   │   │   └── result_detail_page.dart    # Chi tiết kết quả bài thi
│   │   │
│   │   └── teacher/                       # Teacher screens
│   │       ├── teacher_panel.dart         # Bottom nav (Classes/QuizBank)
│   │       ├── manage_classes_page.dart   # Quản lý lớp học
│   │       ├── class_detail_page.dart     # Chi tiết lớp (Students/Quizzes/Results)
│   │       ├── class_create_quiz_page.dart # Tạo đề thi gán trực tiếp vào lớp
│   │       ├── class_quiz_detail_page.dart # Chi tiết đề thi trong lớp
│   │       ├── class_results_page.dart    # Trang kết quả (search/filter/sort)
│   │       ├── quiz_bank_page.dart        # Kho đề thi
│   │       ├── quiz_bank_create_page.dart # Tạo đề thi vào kho
│   │       ├── edit_quiz_page.dart        # Chỉnh sửa đề thi
│   │       └── quiz_schedule_dialog.dart  # Dialog lên lịch bài thi
│   │
│   ├── services/                          # Business logic & Firebase services
│   │   ├── firebase_service.dart          # CRUD Firestore operations
│   │   ├── user_service.dart              # User authentication & profile
│   │   └── quiz_schedule_service.dart     # Quiz scheduling logic
│   │
│   ├── utils/                             # Utilities & helpers
│   │   ├── constants.dart                 # App constants (colors, strings)
│   │   └── helpers.dart                   # Helper functions (format date, etc.)
│   │
│   └── widgets/                           # Reusable widgets (nếu có)
│
├── web/                                   # Web-specific files
│   ├── index.html
│   └── favicon.png
│
├── android/                               # Android-specific files
├── ios/                                   # iOS-specific files
├── windows/                               # Windows-specific files
├── macos/                                 # macOS-specific files
├── linux/                                 # Linux-specific files
│
├── assets/                                # Static assets
│   ├── images/
│   └── fonts/
│
├── test/                                  # Unit & widget tests
│
├── .gitignore
├── pubspec.yaml                           # Dependencies
├── README.md                              # Tài liệu này
└── firebase.json                          # Firebase configuration
```

## 📁 Cấu trúc Database (Firestore)

```
📦 Firestore Collections

├── 📂 users
│   └── {userId}
│       ├── email: string
│       ├── role: "student" | "teacher"
│       ├── displayName: string
│       └── createdAt: timestamp

├── 📂 classes
│   └── {classId}
│       ├── name: string
│       ├── description: string
│       ├── teacherId: string
│       ├── studentCount: number
│       ├── quizCount: number
│       ├── createdAt: timestamp
│       │
│       ├── 📂 students (subcollection)
│       │   └── {studentId (9 digits)}
│       │       ├── studentId: string
│       │       ├── email: string
│       │       ├── name: string
│       │       ├── phone: string (optional)
│       │       └── addedAt: timestamp
│       │
│       ├── 📂 quizzes (subcollection)
│       │   └── {quizId}
│       │       ├── title: string
│       │       ├── questionCount: number
│       │       ├── duration: number (minutes)
│       │       └── assignedAt: timestamp
│       │
│       └── 📂 schedules (subcollection)
│           └── {scheduleId}
│               ├── quizId: string
│               ├── openTime: timestamp (nullable)
│               ├── closeTime: timestamp (nullable)
│               ├── autoOpen: boolean
│               ├── autoClose: boolean
│               ├── status: "scheduled" | "open" | "closed"
│               ├── createdAt: timestamp
│               └── updatedAt: timestamp

├── 📂 quiz (global collection)
│   └── {quizId}
│       ├── title: string
│       ├── questionCount: number
│       ├── duration: number (minutes)
│       ├── maxSuspiciousActions: number (1-20)
│       ├── status: "available" | "archived"
│       ├── createdAt: timestamp
│       │
│       └── 📂 questions (subcollection)
│           └── {questionId}
│               ├── question: string
│               ├── options: array[4] of string
│               ├── correctAnswer: "A" | "B" | "C" | "D"
│               └── order: number (optional)

└── 📂 submissions
    └── {submissionId}
        ├── studentId: string
        ├── quizId: string
        ├── classId: string
        ├── quizTitle: string
        ├── answers: map<questionId, answer>
        ├── score: number
        ├── totalQuestions: number
        ├── timestamp: timestamp
        ├── timeSpent: number (seconds)
        ├── suspiciousActionCount: number
        ├── cheatingDetected: boolean
        └── autoSubmitted: boolean
```

## 📝 Format file đề thi

### Định dạng TXT/PDF

```
Câu 1: Thủ đô của Việt Nam là?
A. Hà Nội
B. Đà Nẵng
C. TP.HCM
D. Hải Phòng
Đáp án: A

Câu 2: 2 + 2 = ?
A. 2
B. 3
C. 4
D. 5
Đáp án: C
```

### Định dạng Excel (Import học sinh)

| Cột | Tên cột | Mô tả | Bắt buộc |
|-----|---------|-------|----------|
| A | STT | Số thứ tự | Không |
| B | Số thẻ SV | Mã sinh viên (9 chữ số) | **Có** |
| C | Họ tên SV | Họ và tên đầy đủ | **Có** |
| D | Lớp sinh hoạt | Lớp (optional) | Không |
| E | Số điện thoại | SĐT (optional) | Không |

**Lưu ý**: Dòng đầu tiên (header) sẽ bị bỏ qua.

## 🚀 Cài đặt và Chạy

### 1. Yêu cầu hệ thống
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Firebase CLI (để setup Firebase)

### 2. Clone project
```bash
git clone https://github.com/yourusername/student-quiz-app.git
cd student-quiz-app
```

### 3. Cài đặt dependencies
```bash
flutter pub get
```

### 4. Cấu hình Firebase

#### a. Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Tạo project mới
3. Enable **Authentication** → Bật **Microsoft** provider
4. Enable **Firestore Database** → Chế độ production
5. Thiết lập **Security Rules**

#### b. Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Classes collection
    match /classes/{classId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.resource.data.teacherId == request.auth.uid;
      allow update, delete: if request.auth != null && 
        resource.data.teacherId == request.auth.uid;
      
      // Students subcollection
      match /students/{studentId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/classes/$(classId)).data.teacherId == request.auth.uid;
      }
      
      // Quizzes subcollection
      match /quizzes/{quizId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/classes/$(classId)).data.teacherId == request.auth.uid;
      }
      
      // Schedules subcollection
      match /schedules/{scheduleId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/classes/$(classId)).data.teacherId == request.auth.uid;
      }
    }
    
    // Global quiz collection
    match /quiz/{quizId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
      
      match /questions/{questionId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
    
    // Submissions collection
    match /submissions/{submissionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if false; // Không cho phép sửa sau khi nộp
      allow delete: if false; // Không cho phép xóa
    }
  }
}
```

#### c. Thêm Firebase vào Flutter

```bash
# Cài đặt Firebase CLI
npm install -g firebase-tools

# Đăng nhập
firebase login

# Cấu hình Firebase cho Flutter
flutterfire configure
```

Chọn Firebase project và platforms (Web, Android, iOS)

### 5. Cấu hình Microsoft Authentication

1. Truy cập [Azure Portal](https://portal.azure.com/)
2. Đăng ký ứng dụng (App Registration)
3. Lấy **Client ID** và **Client Secret**
4. Thêm Redirect URIs:
   - `https://YOUR_PROJECT_ID.firebaseapp.com/__/auth/handler`
5. Cấu hình trong Firebase Console → Authentication → Microsoft

### 6. Chạy ứng dụng

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios

# Desktop (Windows)
flutter run -d windows
```

## 📱 Hướng dẫn sử dụng

### Giáo viên

1. **Đăng nhập** bằng tài khoản Microsoft
2. **Tạo lớp học**:
   - Vào "Quản lý lớp" → "Tạo lớp mới"
   - Nhập tên và mô tả
3. **Thêm học sinh**:
   - Thủ công: Nhập email và tên
   - Import Excel: Chọn file .xlsx/.xls
4. **Tạo đề thi**:
   - **Cách 1**: Kho đề thi → Upload PDF/TXT
   - **Cách 2**: Trong lớp → "Tạo đề thi mới"
5. **Lên lịch** (optional):
   - Chọn bài thi → Icon lịch
   - Đặt thời gian mở/đóng
6. **Xem kết quả**:
   - Tab "Kết quả" → Xem, tìm kiếm, sắp xếp

### Học sinh

1. **Đăng nhập** bằng email sinh viên (9 chữ số)
2. **Chọn lớp học** từ danh sách
3. **Xem bài thi khả dụng**:
   - Tab "Bài thi"
   - Kiểm tra trạng thái (Đang mở/Chưa mở/Đã đóng)
4. **Làm bài**:
   - Nhấn "Làm bài" → Vào fullscreen
   - Không chuyển tab, không thoát fullscreen
   - Chú ý số vi phạm hiển thị trên header
5. **Xem lịch sử**:
   - Tab "Lịch sử" → Xem lại bài đã làm

## ⚙️ Cấu hình nâng cao

### Thay đổi số vi phạm mặc định

Trong `class_create_quiz_page.dart` hoặc `quiz_bank_create_page.dart`:

```dart
final _maxViolationsController = TextEditingController(text: '5'); // Đổi '5' thành số khác
```

### Tùy chỉnh thời gian làm bài mặc định

```dart
final _durationController = TextEditingController(text: '30'); // 30 phút
```

### Chỉnh sửa format email sinh viên

Trong `user_service.dart`:

```dart
static String extractStudentId(String? email) {
  // Tùy chỉnh regex để match format email của trường bạn
  final digits = username.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 9) {
    return digits.substring(0, 9); // Lấy 9 chữ số đầu
  }
  return digits;
}
```

## 🐛 Troubleshooting

### Lỗi: "Firebase not initialized"
```bash
flutter clean
flutter pub get
flutterfire configure
```

### Lỗi: "Microsoft login failed"
- Kiểm tra Client ID/Secret trong Firebase Console
- Kiểm tra Redirect URIs trong Azure Portal
- Xóa cache trình duyệt

### Lỗi: "Permission denied" khi đọc/ghi Firestore
- Kiểm tra Security Rules
- Đảm bảo user đã đăng nhập

### Lỗi: "Fullscreen not working"
- Chỉ hoạt động trên Web với HTTPS
- Desktop/Mobile không cần fullscreen API

## 👥 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:
1. Fork project
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request
