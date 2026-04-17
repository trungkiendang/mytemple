# My Chùa (Temple-Vibe)

**My Chùa** là một ứng dụng di động được xây dựng bằng Flutter, cung cấp một không gian tu tập tâm linh số hóa, hiện đại và thanh tịnh. Ứng dụng giúp người dùng tiếp cận với các pháp tu tập căn bản như gõ mõ, thắp hương, đọc kinh và theo dõi lịch âm một cách dễ dàng ngay trên điện thoại.

## 🌟 Tính năng chính

### 1. Gõ Mõ 3D & Tương tác
- Mô hình Mõ 3D chân thực, phản hồi rung (Haptic) và âm thanh khi chạm.
- Chế độ tự động gõ (Auto-tap) với tốc độ tùy chỉnh.
- Theo dõi số lượng người đang cùng tu tập trực tuyến thời gian thực.

### 2. Thắp Hương 3D
- Trải nghiệm thắp hương ảo với hiệu ứng khói 3D mượt mà.
- Hẹn giờ thắp hương (1, 5, 15 phút) và đếm ngược.
- Gửi gắm những lời cầu nguyện (Petition) cùng mỗi nén hương.

### 3. Thư viện Kinh Văn & Phật Pháp
- Chế độ **Hybrid**: Tải các bài kinh từ Firebase và lưu trữ cục bộ (Offline) qua Hive.
- Chức năng tự động cuộn (Auto-scroll) hỗ trợ việc tụng kinh thuận tiện.
- Phân loại kinh văn theo nhiều hệ phái (Bắc tông, Nam tông...).

### 4. Lịch Âm & Nhắc nhở
- Xem Lịch vạn niên Âm/Dương chuẩn Việt Nam.
- Đánh dấu các ngày lễ quan trọng trong năm.
- Thông báo nhắc nhở ngày Rằm, Mồng Một và các ngày vía Phật.

### 5. Cộng đồng & Cá nhân
- **Bảng xếp hạng (Leaderboard):** Tôn vinh những người tu tập tinh tấn nhất.
- **Thành tích cá nhân:** Lưu giữ lịch sử tu tập và danh hiệu (Badges).

## 🛠 Công nghệ sử dụng

- **Framework:** [Flutter](https://flutter.dev/) (Android & iOS).
- **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Cloud Storage, Cloud Messaging).
- **Cơ sở dữ liệu cục bộ:** [Hive](https://docs.hivedb.dev/).
- **Mô hình 3D:** `o3d` (định dạng .glb).
- **Quản lý trạng thái:** `Provider`.
- **Lịch âm:** `lunar`.

## 🚀 Hướng dẫn cài đặt

### 1. Yêu cầu hệ thống
- Flutter SDK (phiên bản mới nhất).
- Android Studio / VS Code đã cài đặt plugin Flutter/Dart.
- Xcode (nếu phát triển cho iOS).

### 2. Cấu hình Firebase
Ứng dụng yêu cầu kết nối với Firebase để sử dụng các tính năng trực tuyến.
1. Tạo dự án trên [Firebase Console](https://console.firebase.google.com/).
2. Thêm ứng dụng Android/iOS với Package Name: `com.kun.temple`.
3. Tải file cấu hình và đặt vào:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
4. Kích hoạt **Firestore Database** và **Authentication** (Anonymous/Google).

### 3. Cài đặt và chạy
```bash
# Cài đặt các thư viện
flutter pub get

# Chạy ứng dụng
flutter run
```

### 4. Nạp dữ liệu mẫu
Bạn có thể sử dụng script trong thư mục `scripts/` để nạp dữ liệu kinh văn lên Firestore:
```bash
cd scripts
npm install
node upload_to_firebase.js
```
*(Yêu cầu file `serviceAccountKey.json` từ Firebase)*

## 📦 Cấu trúc thư mục

```text
lib/
├── core/             # Cấu hình chung, theme, hằng số
├── features/         # Các tính năng chính (3D, Lịch, Kinh văn...)
│   ├── monk_bell/    # Gõ mõ
│   ├── incense/      # Thắp hương
│   ├── scriptures/   # Thư viện kinh văn
│   ├── calendar/     # Lịch âm
│   └── profile/      # Cá nhân & Cộng đồng
├── models/           # Các đối tượng dữ liệu
├── services/         # Firebase, Hive, Notifications
└── main.dart         # Điểm khởi đầu ứng dụng
```

## 📜 Giấy phép
Dự án được phát triển cho mục đích tu tập và chia sẻ kiến thức phật pháp.

---
**Phiên bản:** 1.0.0
**Tác giả:** Gemini CLI Agent & Kun
