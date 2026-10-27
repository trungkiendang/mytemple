# Rà soát Firebase (project `temple-a6cf8`)

Kiểm tra trực tiếp bằng API key đã có trong app (27/10/2026):

| Hạng mục | Kết quả | Hệ quả |
|---|---|---|
| Firestore – đọc khi **chưa** đăng nhập | `403 PERMISSION_DENIED` | Rules đang yêu cầu đăng nhập |
| Đăng nhập **ẩn danh** (Anonymous) | `ADMIN_ONLY_OPERATION` → **đang tắt** | `signInAnonymously()` luôn lỗi → không có quyền đọc/ghi Firestore |
| Đăng nhập **Email/Mật khẩu** | `PASSWORD_LOGIN_DISABLED` → **đang tắt** | Đăng nhập/Đăng ký trong màn Cá nhân không dùng được |
| Authorized domains (Auth) | `localhost`, `temple-a6cf8.firebaseapp.com`, `temple-a6cf8.web.app` | Thiếu `chant.iamkien.tech` (cần khi dùng đăng nhập Google/popup trên web) |
| Web app ID trong `lib/main.dart` | `1:609068144093:web:dummy` | Là giá trị giả; cần App ID thật của web app |

Kết luận: **chưa có kết nối thực** — ứng dụng đang chạy bằng dữ liệu cục bộ (kinh sách kèm theo app, số liệu 0, bảng xếp hạng mẫu). Màn **Cá nhân** hiển thị trạng thái kết nối để dễ chẩn đoán.

## Việc cần làm trong Firebase Console
1. **Authentication → Sign-in method**: bật **Anonymous** (và **Email/Password** nếu muốn đăng nhập).
2. **Authentication → Settings → Authorized domains**: thêm `chant.iamkien.tech`.
3. **Project settings → Your apps**: thêm **Web app**, lấy `appId` thật rồi sửa trong `lib/main.dart` (khối `FirebaseOptions`).
4. **Firestore → Rules**: dán nội dung `firebase/firestore.rules` (hoặc `firebase deploy --only firestore:rules`).
5. Nạp dữ liệu: `cd scripts && npm install && node upload_to_firebase.js` (cần `serviceAccountKey.json`).

## Cấu trúc dữ liệu app đang dùng
- `scriptures/{id}`: `title`, `content`, `sect`, `category` — đọc công khai, chỉ ghi bằng Admin SDK.
- `stats/global_stats`: `total_taps` (cộng dồn theo lô mỗi ~4 giây), `online_users` (dự phòng).
- `users/{uid}`: `displayName`, `tapCount`, `lastActive` — dùng cho bảng xếp hạng và đếm người đang tu tập (số user có `lastActive` trong 3 phút gần nhất).
- `users/{uid}/user_events/{id}`: sự kiện lịch của người dùng (chỉ chủ sở hữu).

## Đã sửa trong code
- Bộ lọc hệ phái bị lệch hoa/thường (`Bắc tông` vs `Bắc Tông` trong dữ liệu) nên lọc ra rỗng → nay lọc ở client, không phân biệt hoa/thường, danh sách hệ phái lấy từ dữ liệu.
- Khi Firestore không dùng được, thư viện kinh dùng bản kèm app (`assets/data/scriptures.json`).
- Đồng bộ lượt gõ theo `uid` thật (trước đây ghi cứng `prototype_user`), gộp lô để giảm số lần ghi.
- Khởi động có timeout, màn bảng xếp hạng không còn lỗi khi Firebase chưa khởi tạo.
