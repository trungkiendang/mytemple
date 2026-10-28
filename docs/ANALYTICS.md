# Google Analytics (Firebase Analytics) – project `temple-a6cf8`

Ứng dụng gửi sự kiện qua `firebase_analytics` (`lib/services/analytics_service.dart`). Mọi lệnh gọi đều "an toàn": nếu Firebase/Analytics chưa cấu hình thì không làm gì, không ảnh hưởng ứng dụng.

## Trạng thái hiện tại (kiểm tra 28/10/2026)
- `android/app/google-services.json` **không có** `analytics_service` và `ios/Runner/GoogleService-Info.plist` có `IS_ANALYTICS_ENABLED = false` → **Google Analytics chưa được bật cho project**, nên chưa có dữ liệu nào được ghi nhận.
- Web đang dùng App ID giả (`...web:dummy`) và chưa có Measurement ID.

## Việc cần làm (một lần, trong Firebase Console)
1. **Project settings → Integrations → Google Analytics → Enable** (tạo/chọn một tài khoản GA4 rồi liên kết với `temple-a6cf8`).
2. **Project settings → Your apps**:
   - Android `com.kun.temple`, iOS `com.kun.temple`: tải lại `google-services.json` / `GoogleService-Info.plist` (sau khi bật Analytics file mới sẽ có `analytics_service`) và thay vào `android/app/` và `ios/Runner/`.
   - **Thêm Web app** → lấy `appId` (`1:609068144093:web:...`) và `measurementId` (`G-...`).
3. Đặt hai biến cho web tại GitHub **Settings → Secrets and variables → Actions → Variables** (hoặc dùng `.github/store.env` + `scripts/setup_github_secrets.sh`):
   - `GA_MEASUREMENT_ID` = `G-XXXXXXXXXX`
   - `FIREBASE_WEB_APP_ID` = `1:609068144093:web:xxxxxxxx`
   Workflow *Deploy to GitHub Pages* truyền chúng vào bản build (`--dart-define`). Build local: `flutter build web --dart-define=GA_MEASUREMENT_ID=G-... --dart-define=FIREBASE_WEB_APP_ID=1:...`
4. Kiểm tra: Firebase Console → Analytics → **DebugView** (Android: `adb shell setprop debug.firebase.analytics.app com.kun.temple`).

## Sự kiện được ghi
| Sự kiện | Khi nào | Tham số |
|---|---|---|
| `screen_view` | mở tab: `go_mo`, `kinh`, `thap_huong`, `lich`, `ca_nhan` | `screen_name` |
| `tap_milestone` | số lượt gõ đạt 10 / 50 / 108 / 500 / 1000 / 5000 | `count` |
| `auto_tap_start` | bật tự động gõ | `bpm` |
| `incense_start` | bắt đầu thắp hương | `sticks`, `minutes`, `has_petition` |
| `prayer_select` | chọn bài khấn / kinh | `prayer_id`, `mode` |
| `scripture_open` | mở một bài kinh trong thư viện | `scripture_id` |
| `login`, `sign_up` | đăng nhập / đăng ký email | `method` |

Người dùng được gắn `user_id` = UID Firebase (ẩn danh), không thu thập thông tin cá nhân. Khi lên chợ ứng dụng cần khai báo việc thu thập dữ liệu Analytics trong chính sách quyền riêng tư (Play Data safety / App Privacy của Apple).
