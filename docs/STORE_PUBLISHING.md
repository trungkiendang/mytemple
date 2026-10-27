# Đẩy ứng dụng lên chợ ứng dụng (GitHub Actions)

Hai workflow, chạy tay (**Actions → Run workflow**) hoặc tự chạy khi đẩy tag `v*` (vd. `git tag v1.1.0 && git push --tags`):

| Workflow | Kết quả | Chợ |
|---|---|---|
| `Release Android (Google Play)` – `.github/workflows/release-android.yml` | App Bundle (`.aab`) ký bằng upload key | Google Play (track `internal` mặc định) |
| `Release iOS (TestFlight)` – `.github/workflows/release-ios.yml` | `.ipa` ký chính thức | App Store Connect / TestFlight |

Số build (`versionCode` / build number) lấy từ `github.run_number`; tên phiên bản lấy từ `version:` trong `pubspec.yaml`.

## Điền giá trị cho Secrets / Variables

Cách nhanh: `cp .github/store.env.example .github/store.env`, điền giá trị rồi chạy `scripts/setup_github_secrets.sh` (cần GitHub CLI `gh auth login`). Hoặc nhập tay tại **Settings → Secrets and variables → Actions**. Workflow sẽ báo lỗi rõ tên biến còn thiếu.

### Android
| Tên | Loại | Cách lấy |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Secret | `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` rồi `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Secret | mật khẩu keystore |
| `ANDROID_KEY_ALIAS` | Secret | alias (vd. `upload`) |
| `ANDROID_KEY_PASSWORD` | Secret | mật khẩu key |
| `PLAY_SERVICE_ACCOUNT_JSON` | Secret | Play Console → Setup → API access → tạo service account, cấp quyền *Release manager*, tải file JSON |
| `PLAY_DEFAULT_TRACK` | Variable | `internal` / `alpha` / `beta` / `production` (mặc định `internal`) |
| `PLAY_RELEASE_STATUS` | Variable | `draft` (mặc định) hoặc `completed` |

Lưu ý: lần đầu phải tạo ứng dụng `com.kun.temple` trong Play Console và tải bản đầu tiên thủ công (hoặc để status `draft`). Nên bật **Play App Signing**; key trong repo chỉ là *upload key*.

### iOS
| Tên | Loại | Cách lấy |
|---|---|---|
| `IOS_DIST_CERT_BASE64` | Secret | Chứng chỉ *Apple Distribution* xuất `.p12` → `base64 -i Distribution.p12` |
| `IOS_DIST_CERT_PASSWORD` | Secret | mật khẩu khi xuất `.p12` |
| `IOS_PROVISION_PROFILE_BASE64` | Secret | Provisioning profile loại *App Store* cho `com.kun.temple` → `base64 -i profile.mobileprovision` |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY_P8` | Secret | App Store Connect → Users and Access → Integrations → tạo API key (quyền App Manager), tải `AuthKey_XXXX.p8` |
| `APPLE_TEAM_ID` | Variable | Team ID trong Apple Developer |
| `IOS_PROVISION_PROFILE_NAME` | Variable | tên profile đúng như trên Developer Portal |
| `IOS_BUNDLE_ID` | Variable | mặc định `com.kun.temple` |

Cần tài khoản Apple Developer (99 USD/năm) và app đã tạo trong App Store Connect.

## Quy trình phát hành
1. Tăng `version:` trong `pubspec.yaml` (vd. `1.1.0+2`).
2. Merge vào `main`, tạo tag `v1.1.0` → hai workflow tự chạy (hoặc chạy tay).
3. Android: kiểm tra bản ở track *internal* rồi promote lên production trong Play Console.
4. iOS: build xuất hiện trong TestFlight sau vài phút xử lý, rồi gửi review.

## Việc cần làm trước khi lên chợ (không tự động hóa được)
- Mô tả, ảnh chụp màn hình, chính sách quyền riêng tư (ứng dụng dùng Firebase Auth/Firestore), phân loại nội dung.
- Bật Anonymous Auth + đặt Firestore Rules (xem `docs/FIREBASE.md`).
- Thay chữ ký bản APK CI (`build-apk.yml`) nếu muốn phát hành APK ngoài chợ: hiện ký bằng debug key khi không có `android/key.properties`.
