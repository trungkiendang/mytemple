# Build & phát hành

## Web (public)
- Push/merge vào `main` → workflow `Deploy to GitHub Pages` tự build `flutter build web` và publish tại https://chant.iamkien.tech.
- Build thủ công: `flutter build web --release --base-href / --pwa-strategy=none`.
- Workflow dùng `--pwa-strategy=none` (không cache offline bằng service worker) để người dùng luôn nhận bản mới ngay sau khi deploy; bản build này cũng tự gỡ service worker cũ còn sót trên trình duyệt. Nếu thấy bản cũ: tải lại cứng (Ctrl/Cmd+Shift+R) hoặc xóa dữ liệu trang một lần.

## Android (APK)
- Workflow `Build Release APK` chạy khi push vào `main` hoặc bằng nút *Run workflow* (artifact `release-apk`).
- Build local cần Android SDK + JDK 17: `flutter build apk --release`.
- Release chính thức nên đổi sang ký bằng keystore riêng (hiện dùng cấu hình mặc định của template).

## iOS
- Bundle ID: `com.kun.temple`, iOS tối thiểu 13.0.
- Workflow `Build iOS (unsigned)` (chạy tay, runner macOS) tạo `my-chua-unsigned.ipa` (artifact `ios-unsigned-ipa`) để ký lại bằng Apple Developer account.
- Build local trên macOS: `flutter build ios --release` rồi Archive trong Xcode (`ios/Runner.xcworkspace`), cần Team ID và provisioning profile.

## Tạo lại mô hình 3D
`cd scripts && npm install && node generate_models.js` (ghi vào `assets/models/`).
