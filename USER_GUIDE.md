# TÀI LIỆU HƯỚNG DẪN SỬ DỤNG HỆ THỐNG THI TRỰC TUYẾN (DUT QUIZMASTER)
> **Dành cho: Giảng viên (Teacher), Trợ giảng (Teaching Assistant) và Sinh viên (Student)**

---

## MỤC LỤC
1. [Giới thiệu tổng quan](#1-giới-thiệu-tổng-quan)
2. [Hướng dẫn dành cho GIẢNG VIÊN (Teacher)](#2-hướng-dẫn-dành-cho-giảng-viên-teacher)
   - [2.1 Đăng nhập & Không gian làm việc](#21-đăng-nhập--không-gian-làm-việc)
   - [2.2 Quản lý Lớp học](#22-quản-lý-lớp-học)
   - [2.3 Quản lý Sinh viên trong lớp](#23-quản-lý-sinh-viên-trong-lớp)
   - [2.4 Phân quyền Trợ giảng (TA)](#24-phân-quyền-trợ-giảng-ta)
   - [2.5 Quản lý Ngân hàng câu hỏi & Kho đề thi](#25-quản-lý-ngân-hàng-câu-hỏi--kho-đề-thi)
   - [2.6 Tạo & Gán đề thi vào lớp](#26-tạo--gán-đề-thi-vào-lớp)
   - [2.7 Lên lịch & Tổ chức kỳ thi](#27-lên-lịch--tổ-chức-kỳ-thi)
   - [2.8 Giám sát & Xem kết quả thi](#28-giám-sát--xem-kết-quả-thi)
3. [Hướng dẫn dành cho TRỢ GIẢNG (Teaching Assistant - TA)](#3-hướng-dẫn-dành-cho-trợ-giảng-teaching-assistant---ta)
   - [3.1 Bản chất vai trò & Cách truy cập](#31-bản-chất-vai-trò--cách-truy-cập)
   - [3.2 Quản lý danh sách sinh viên](#32-quản-lý-danh-sách-sinh-viên)
   - [3.3 Tạo & Quản lý bài thi của lớp](#33-tạo--quản-lý-bài-thi-của-lớp)
   - [3.4 Tạo đề thi từ Ngân hàng câu hỏi (Phương án 1)](#34-tạo-đề-thi-từ-ngân-hàng-câu-hỏi-phương-án-1)
   - [3.5 Tổ chức thi & Thống kê điểm số](#35-tổ-chức-thi--thống-kê-điểm-số)
   - [3.6 Các giới hạn an toàn đối với Trợ giảng](#36-các-giới-hạn-an-toàn-đối-với-trợ-giảng)
4. [Hướng dẫn dành cho SINH VIÊN (Student)](#4-hướng-dẫn-dành-cho-sinh-viên-student)
   - [4.1 Đăng nhập & Không gian học tập](#41-đăng-nhập--không-gian-học-tập)
   - [4.2 Truy cập lớp học & Xem bài thi](#42-truy-cập-lớp-học--xem-bài-thi)
   - [4.3 Quy trình làm bài thi & Hệ thống chống gian lận (Anti-cheat)](#43-quy-trình-làm-bài-thi--hệ-thống-chống-gian-lận-anti-cheat)
   - [4.4 Xem kết quả & Lịch sử học tập](#44-xem-kết-quả--lịch-sử-học-tập)
5. [Bảng so sánh quyền hạn (Matrix Permissions)](#5-bảng-so-sánh-quyền-hạn-matrix-permissions)

---

## 1. GIỚI THIỆU TỔNG QUAN
**DUT QuizMaster** là nền tảng quản trị và tổ chức thi trắc nghiệm trực tuyến hiện đại. Hệ thống được thiết kế chuyên biệt cho môi trường giáo dục đại học, tối ưu hóa quy trình tổ chức kiểm tra, giám sát gian lận thời gian thực và quản trị phân quyền đa cấp giữa **Giảng viên**, **Trợ giảng** và **Sinh viên**.

---

## 2. HƯỚNG DẪN DÀNH CHO GIẢNG VIÊN (Teacher)

Giảng viên là người có quyền cao nhất trong hệ sinh thái giảng dạy: quản lý các lớp học, sở hữu kho ngân hàng câu hỏi, tổ chức kỳ thi và phân quyền trợ giảng.

### 2.1 Đăng nhập & Không gian làm việc
1. Đăng nhập bằng tài khoản Giảng viên (Email & Mật khẩu được cấp).
2. Thanh điều hướng bên trái (Sidebar) gồm các phân hệ chính:
   - **Quản lý Lớp học**: Quản lý tất cả các lớp học phần đang giảng dạy.
   - **Kho đề thi**: Quản lý các đề thi mẫu/đề thi đã xuất bản để tái sử dụng.
   - **Ngân hàng câu hỏi**: Kho lưu trữ các bộ câu hỏi nguồn theo từng học phần/chủ đề.
   - **Cài đặt & Giao diện**: Bật/tắt chế độ Sáng/Tối (Light/Dark mode) hoặc Đăng xuất.

### 2.2 Quản lý Lớp học
* **Tạo lớp học mới**: 
  - Tại trang Quản lý lớp học, bấm nút **"+ Tạo lớp học mới"**.
  - Nhập: Tên lớp (Ví dụ: `Lập trình mạng - 22T1`), Mã học phần, Mô tả lớp học và chọn Màu sắc nhận diện.
  - Bấm **"Tạo lớp"**.
* **Chỉnh sửa / Xóa lớp**: 
  - Trong danh sách lớp hoặc trong trang chi tiết lớp học, bấm biểu tượng menu 3 chấm để chỉnh sửa tên/mô tả hoặc xóa lớp học khi kết thúc học kỳ.

### 2.3 Quản lý Sinh viên trong lớp
Truy cập vào một lớp học > Chọn tab **"Danh sách sinh viên"**:
* **Thêm sinh viên thủ công**:
  - Bấm **"+ Thêm học sinh"** > Chọn **"Thêm thủ công"**.
  - Nhập Họ và tên, Email sinh viên (Hệ thống tự động trích xuất MSSV từ email định dạng trường, ví dụ `106230210@sv1.dut.udn.vn` -> MSSV: `106230210`).
* **Import sinh viên từ Excel**:
  - Bấm **"+ Thêm học sinh"** > Chọn **"Import từ Excel"**.
  - Tải lên file `.xlsx` hoặc `.xls`. Hệ thống tự động đọc các cột Email, Họ tên và nạp toàn bộ danh sách vào lớp trong vài giây.
* **Xóa sinh viên khỏi lớp**: Bấm menu bên cạnh sinh viên > Chọn **"Xóa khỏi lớp"**.

### 2.4 Phân quyền Trợ giảng (TA)
Nhằm giảm tải công việc cho Giảng viên ở các lớp đông sinh viên:
1. Trong tab **"Danh sách sinh viên"**, nhìn vào khối **"Trợ giảng lớp học"**.
2. Bấm **"+ Thêm trợ giảng"**.
3. Nhập Email hoặc MSSV của sinh viên bạn muốn giao quyền Trợ giảng > Bấm **"Xác nhận gán Trợ giảng"**.
4. Sinh viên này ngay lập tức có quyền Trợ giảng trong lớp này.
5. **Gỡ quyền Trợ giảng**: Bấm biểu tượng thùng rác màu đỏ bên cạnh thẻ Trợ giảng bất kỳ lúc nào để thu hồi quyền.

### 2.5 Quản lý Ngân hàng câu hỏi & Kho đề thi
* **Ngân hàng câu hỏi (`QuizBankListPage`)**:
  - Truy cập menu **"Ngân hàng câu hỏi"** trên thanh bên.
  - Bấm **"+ Tạo ngân hàng mới"**: Soạn thủ công từng câu hỏi hoặc tải file `.txt`/`.pdf` để hệ thống tự động bóc tách câu hỏi và đáp án A, B, C, D.
  - Giảng viên có thể vào **"Chỉnh sửa"** ngân hàng để thêm/sửa/xóa từng câu hỏi bất kỳ lúc nào.
* **Kho đề thi (`QuizBankPage`)**:
  - Lưu trữ các đề thi hoàn chỉnh. Đề thi trong kho có thể được gán vào nhiều lớp học khác nhau mà không cần tạo lại từ đầu.

### 2.6 Tạo & Gán đề thi vào lớp
Trong trang Chi tiết lớp học > Chọn tab **"Bài thi"** > Bấm **"+ Thêm bài thi"**:
1. **Tạo bài thi mới**: Soạn đề thủ công hoặc import trực tiếp từ file PDF/TXT.
2. **Gán bài thi có sẵn**: Chọn bài thi từ Kho đề thi để gán ngay cho lớp này.
3. **Tạo từ ngân hàng câu hỏi**: Chọn 1 ngân hàng câu hỏi > Chọn sinh đề ngẫu nhiên ($N$ câu) hoặc tự tay tích chọn các câu hỏi ưng ý. Đề thi sẽ được tạo và gán thẳng vào lớp.

### 2.7 Lên lịch & Tổ chức kỳ thi
Bấm vào bài thi trong tab **"Bài thi"** để mở trang **Chi tiết bài thi của lớp**:
* **Lên lịch tự động**: Bấm **"Lên lịch thi"** > Cài đặt Ngày/Giờ mở đề, Ngày/Giờ đóng đề, Thời lượng làm bài (phút).
* **Điều khiển thủ công**: Giảng viên có thể bấm **"Mở thi ngay"** hoặc **"Đóng phòng thi ngay"** theo tình hình thực tế trên lớp.
* **Cấu hình chống gian lận**: Thiết lập số lần vi phạm tối đa cho phép (Ví dụ: 3 lần hoặc 5 lần). Nếu sinh viên vượt quá, hệ thống sẽ tự động thu bài.

### 2.8 Giám sát & Xem kết quả thi
* **Giám sát thời gian thực**: Xem số lượng sinh viên đang làm bài thi, thời gian còn lại.
* **Xem kết quả & Thống kê**:
  - Xem danh sách điểm của tất cả sinh viên trong lớp.
  - Xem chi tiết từng bài nộp: Số câu đúng/sai, thời gian hoàn thành, các lần vi phạm chuyển tab/thoát toàn màn hình.
  - Bấm **"Xuất CSV"** để tải file bảng điểm về máy tính để báo cáo hoặc nhập điểm vào hệ thống đào tạo.

---

## 3. HƯỚNG DẪN DÀNH CHO TRỢ GIẢNG (Teaching Assistant - TA)

### 3.1 Bản chất vai trò & Cách truy cập
* **Tài khoản**: Trợ giảng vẫn đăng nhập bằng **tài khoản sinh viên bình thường**, không cần tạo tài khoản riêng.
* **Cách truy cập**:
  1. Đăng nhập vào trang Sinh viên.
  2. Tại mục **"Lớp của tôi"**, bạn sẽ thấy một khối riêng biệt: **"Lớp học phụ trách Trợ giảng"** (kèm huy hiệu tím).
  3. Bấm nút **"Quản lý lớp học (Trợ giảng)"** trên thẻ lớp.
  4. Bạn sẽ được đưa vào giao diện Quản lý chi tiết lớp học của Giảng viên với đầy đủ quyền năng quản trị, trong khi **thanh điều hướng (sidebar) sinh viên vẫn được giữ nguyên** bên trái.

### 3.2 Quản lý danh sách sinh viên
* Xem danh bạ toàn bộ sinh viên trong lớp học phần.
* Thêm sinh viên mới vào lớp (Nhập thủ công hoặc tải file Excel).
* Hỗ trợ giải quyết các vấn đề sinh viên chưa có tên trong danh sách lớp trước giờ thi.

### 3.3 Tạo & Quản lý bài thi của lớp
* Hỗ trợ Giảng viên tạo các bài kiểm tra 15 phút, bài tập tuần, hoặc bài kiểm tra giữa kỳ.
* Hỗ trợ tạo đề thi từ file PDF/TXT hoặc chọn bài thi có sẵn.
* Quản lý trạng thái bài thi, xóa bài thi nháp hoặc bài thi thử nghiệm khỏi lớp.

### 3.4 Tạo đề thi từ Ngân hàng câu hỏi (Phương án 1)
Trợ giảng được quyền tận dụng nguồn đề phong phú từ Ngân hàng câu hỏi để ra đề cho lớp:
1. Trong tab **"Bài thi"** của lớp > Bấm **"+ Thêm bài thi"**.
2. Chọn **"Tạo từ ngân hàng câu hỏi"**.
3. Một danh sách các ngân hàng câu hỏi hiện lên > Bấm **"Tạo đề"** ở ngân hàng mong muốn.
4. Lựa chọn cách tạo:
   - **Sinh ngẫu nhiên (Random)**: Nhập số lượng câu hỏi (ví dụ: 20 câu), thời gian thi > Bấm "Tạo đề ngay". Hệ thống tự bốc ngẫu nhiên 20 câu hỏi từ ngân hàng.
   - **Chọn thủ công (Manual)**: Mở danh sách câu hỏi > Tích chọn từng câu hỏi mong muốn > Bấm "Tạo đề thi".
5. Đề thi sẽ tự động xuất hiện ngay trong tab Bài thi của lớp.

### 3.5 Tổ chức thi & Thống kê điểm số
* Cài đặt thời gian làm bài, số lần vi phạm cho bài thi.
* Mở bài thi cho sinh viên làm hoặc đóng bài thi khi hết giờ.
* Xem bảng điểm lớp, phát hiện các trường hợp vi phạm nhiều lần (thoát màn hình, đổi tab).
* Xuất bảng kết quả ra file Excel/CSV để gửi cho Giảng viên chính.

### 3.6 Các giới hạn an toàn đối với Trợ giảng
Để đảm bảo an toàn và quyền sở hữu học thuật của Giảng viên chính:
- 🚫 **Không thể xóa hoặc đổi tên lớp học**.
- 🚫 **Không thể sửa hay xóa Ngân hàng câu hỏi gốc**: Câu hỏi khi lấy từ ngân hàng được sao chép độc lập vào đề thi lớp đó, ngân hàng gốc của Giảng viên luôn được bảo toàn vẹn nguyên.
- 🚫 **Không thể tự gán hoặc gỡ Trợ giảng khác**.
- 🚫 **Không có quyền đối với các lớp học khác** mà mình không được phân công phụ trách.

---

## 4. HƯỚNG DẪN DÀNH CHO SINH VIÊN (Student)

### 4.1 Đăng nhập & Không gian học tập
1. Đăng nhập bằng Email sinh viên (Hỗ trợ tài khoản Microsoft SSO hoặc Google của nhà trường).
2. Hệ thống tự động nhận diện Mã số sinh viên (MSSV) và thông tin cá nhân.
3. Thanh bên trái gồm:
   - **Lớp của tôi**: Danh sách các lớp học phần sinh viên đã được ghi danh.
   - **Thành tích**: Xem tổng hợp điểm số các bài kiểm tra đã làm, biểu đồ tiến độ học tập và xếp loại.
   - **Lịch trình**: Lịch thi chi tiết theo ngày, trạng thái bài thi (Sắp diễn ra, Đang mở, Đã đóng).
   - **Cài đặt & Giao diện**: Tùy chỉnh chế độ ban đêm (Dark Mode) bảo vệ mắt.

### 4.2 Truy cập lớp học & Xem bài thi
1. Vào mục **"Lớp của tôi"** > Bấm vào thẻ lớp học phần bạn muốn xem.
2. Danh sách bài thi hiển thị rõ ràng:
   - **Bản nháp / Sắp diễn ra**: Bài thi chưa đến giờ mở, có hiển thị thời gian dự kiến mở.
   - **Đang diễn ra (Màu xanh)**: Bài thi đang mở, sinh viên có thể bấm **"Bắt đầu làm bài"**.
   - **Đã kết thúc**: Bài thi đã đóng, sinh viên có thể bấm để xem điểm số và đáp án (nếu giảng viên cho phép).

### 4.3 Quy trình làm bài thi & Hệ thống chống gian lận (Anti-cheat)
1. **Chuẩn bị vào thi**:
   - Màn hình hướng dẫn hiển thị: Thời lượng làm bài, số lượng câu hỏi, số lần vi phạm tối đa cho phép.
   - Bấm **"Bắt đầu làm bài"**.
2. **Chế độ toàn màn hình (Fullscreen)**:
   - Trình duyệt sẽ tự động chuyển sang chế độ Toàn màn hình. Sinh viên **không được thoát toàn màn hình** trong suốt quá trình làm bài.
3. **Giám sát vi phạm chống gian lận**:
   - Nếu sinh viên thực hiện một trong các hành vi sau:
     + Thoát chế độ toàn màn hình (Bấm phím `Esc` hoặc `F11`).
     + Chuyển sang tab khác của trình duyệt.
     + Mở ứng dụng khác (Alt + Tab, phím Windows,...).
   - ⚠️ **Hệ thống sẽ lập tức đếm 1 lần vi phạm** và hiện thông báo cảnh báo màu đỏ trên màn hình.
   - 🚨 **Nếu số lần vi phạm vượt quá mức quy định (ví dụ quá 3 lần hoặc 5 lần), hệ thống sẽ NGAY LẬP TỨC THU BÀI TỰ ĐỘNG và khóa quyền làm bài của sinh viên**.
4. **Thao tác trong khi làm bài**:
   - **Đồng hồ đếm ngược**: Hiển thị rõ số phút và giây còn lại ở góc màn hình.
   - **Bảng danh sách câu hỏi (Palette)**:
     + Màu xám: Câu chưa trả lời.
     + Màu xanh/nổi bật: Câu đã chọn đáp án.
     + Nhấp vào số thứ tự để nhảy nhanh đến câu hỏi tương ứng.
   - Chọn đáp án A, B, C, D: Hệ thống tự động ghi nhận câu trả lời tức thì lên máy chủ.
5. **Nộp bài**:
   - Bấm nút **"Nộp bài"** khi đã kiểm tra xong.
   - Hệ thống hiển thị hộp thoại xác nhận (thông báo rõ số câu đã làm và số câu còn bỏ trống).
   - Nếu hết giờ làm bài, hệ thống sẽ **tự động nộp bài** ngay lập tức với các câu đã chọn.

### 4.4 Xem kết quả & Lịch sử học tập
* Ngay sau khi nộp bài: Xem điểm số đạt được, số câu trả lời đúng/sai.
* Xem lại bài làm: Xem lại câu trả lời của mình so với đáp án chuẩn (tuỳ thuộc vào cài đặt công bố của giáo viên).
* Theo dõi lịch sử điểm số tại mục **"Thành tích"** để đánh giá sự tiến bộ qua từng bài kiểm tra.

---

## 5. BẢNG SO SÁNH QUYỀN HẠN (MATRIX PERMISSIONS)

| Chức năng | Giảng viên (Teacher) | Trợ giảng (TA) | Sinh viên (Student) |
| :--- | :---: | :---: | :---: |
| **Tạo lớp học mới** | ✅ Có quyền | ❌ Không | ❌ Không |
| **Xóa / Đổi tên lớp học** | ✅ Có quyền | ❌ Không | ❌ Không |
| **Thêm / Gỡ sinh viên trong lớp** | ✅ Có quyền | ✅ Có quyền (trong lớp) | ❌ Không |
| **Gán / Gỡ Trợ giảng cho lớp** | ✅ Có quyền | ❌ Không | ❌ Không |
| **Sở hữu & Sửa Ngân hàng câu hỏi gốc** | ✅ Có quyền | ❌ Không | ❌ Không |
| **Tạo đề từ Ngân hàng câu hỏi vào lớp** | ✅ Có quyền | ✅ Có quyền | ❌ Không |
| **Tạo đề từ file PDF/TXT vào lớp** | ✅ Có quyền | ✅ Có quyền | ❌ Không |
| **Gán bài thi có sẵn vào lớp** | ✅ Có quyền | ✅ Có quyền | ❌ Không |
| **Lên lịch thi & Mở/Đóng phòng thi** | ✅ Có quyền | ✅ Có quyền | ❌ Không |
| **Xem bảng điểm & Xuất CSV/Excel** | ✅ Có quyền | ✅ Có quyền | ❌ Không |
| **Xem chi tiết nhật ký vi phạm gian lận** | ✅ Có quyền | ✅ Có quyền | ❌ Không |
| **Tham gia làm bài thi kiểm tra** | ❌ (Không cần) | ❌ (Không làm lớp phụ trách) | ✅ Có quyền |
| **Xem bảng thành tích cá nhân** | ❌ | ✅ (Lớp đang học) | ✅ Có quyền |
| **Xem lịch trình bài thi cá nhân** | ❌ | ✅ (Lớp đang học) | ✅ Có quyền |

---
*Tài liệu được cập nhật tự động đồng bộ với phiên bản DUT QuizMaster ver 2.0.*

