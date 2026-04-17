# Design Spec: Temple-Vibe - Ứng dụng Tâm linh Online

**Ngày:** 2026-04-17
**Trạng thái:** Chờ duyệt
**Mục tiêu:** Xây dựng ứng dụng Flutter đa nền tảng (Android/iOS) phục vụ nhu cầu tu tập tâm linh, hỗ trợ đa hệ phái, tích hợp mô hình 3D tương tác và cộng đồng thời gian thực.

## 1. Tổng quan (Overview)
Ứng dụng cung cấp các công cụ tu tập số hóa như Gõ mõ, Thắp hương, xem Lịch âm và tra cứu Kinh văn. Tập trung vào trải nghiệm mượt mà, giao diện thiền định và kết nối những người cùng tu tập qua Firebase.

## 2. Đối tượng khách hàng (Target Audience)
*   Người tu tập mọi lứa tuổi, từ người mới bắt đầu đến người hành trì lâu năm.
*   Hỗ trợ đa hệ phái (Bắc tông, Nam tông, Khất sĩ...).

## 3. Kiến trúc hệ thống (Architecture)
*   **Frontend:** Flutter (Dart).
*   **3D Engine:** `o3d` hoặc `model_viewer_plus` để hiển thị tệp `.glb`.
*   **Local DB:** `Hive` (Lưu trữ cấu hình, bài kinh offline).
*   **Backend (Firebase):**
    *   **Auth:** Google, Apple, Anonymous.
    *   **Firestore:** Real-time sync lượt gõ mõ, bài kinh mới, bảng xếp hạng.
    *   **Storage:** Chứa file 3D (.glb), file âm thanh (.mp3), kinh văn (.json/.md).
    *   **Functions:** Xử lý logic bảng xếp hạng.

## 4. Tính năng chi tiết (Detailed Features)

### 4.1. Gõ mõ 3D & Phản hồi Tương tác
*   Mô hình Mõ 3D xoay chuyển, phản hồi rung (Haptic) và âm thanh khi chạm.
*   Chế độ tự động gõ (Auto-tap) với tốc độ tùy chỉnh.
*   Hiển thị số người đang cùng online gõ mõ (Real-time).

### 4.2. Thắp hương 3D
*   Châm hương, hiệu ứng khói 3D (Particle system).
*   Hương ngắn dần theo thời gian thực (15-30 phút).
*   Gửi lời nguyện cầu (Petition) kèm theo mỗi lần thắp hương.

### 4.3. Lịch âm & Nhắc nhở
*   Lịch Vạn niên (Âm/Dương) chuẩn Việt Nam.
*   Đánh dấu ngày lễ Phật giáo (Rằm, Mồng Một, ngày vía...).
*   Push notification nhắc nhở ăn chay, tụng kinh.

### 4.4. Thư viện Kinh văn & Phật pháp (Hybrid Mode)
*   **Offline:** Các bài kinh căn bản (Chú Đại Bi, Bát Nhã...).
*   **Online:** Tải kinh theo hệ phái từ Firebase, lưu vào Hive để đọc offline.
*   **Trải nghiệm đọc:** Auto-scroll theo nhịp mõ, chỉnh font/size/theme.

## 5. Giao diện (UI/UX)
*   **Theme:** Trầm, dịu mắt (Nâu, Vàng đồng, Xám tùng).
*   **Navigation:** Bottom Navigation Bar (Trang chủ, Kinh văn, Lịch âm, Cá nhân).
*   **3D Assets:** Sử dụng các file GLB nhẹ (< 5MB) để đảm bảo hiệu năng.

## 6. Chiến lược thử nghiệm (Testing Strategy)
*   **Unit test:** Logic tính toán ngày âm lịch, logic xử lý dữ liệu Hive.
*   **Integration test:** Kết nối Firebase, tải file từ Storage.
*   **UI/UX test:** Độ mượt của mô hình 3D trên các dòng máy Android/iOS khác nhau.

---
**Tự đánh giá (Self-Review):**
1. Không có "TBD" hay phần nào bị bỏ trống.
2. Cấu trúc Hybrid cho Kinh văn đã được làm rõ.
3. Tech stack (Flutter + Firebase + Hive) đồng nhất với yêu cầu.
4. Phạm vi (Scope) phù hợp cho một dự án triển khai giai đoạn 1.
