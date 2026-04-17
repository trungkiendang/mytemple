# Temple-Vibe Implementation Plan - Phase 2

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện các tính năng Thắp hương 3D, Lịch âm Việt Nam và kết nối Cộng đồng thời gian thực cho Temple-Vibe.

**Architecture:** Mở rộng kiến trúc Feature-based. Sử dụng Firebase Realtime Database hoặc Firestore Listeners cho tính năng cộng đồng. Sử dụng `flutter_lunar_calendar` cho lịch âm.

**Tech Stack:** Flutter, Firebase Firestore, Firebase Cloud Messaging, `o3d`, `flutter_local_notifications`, `lunar_calendar_v2`.

---

### Task 5: 3D Feature - Incense Burning (Thắp hương)

**Files:**
- Create: `lib/features/incense/incense_screen.dart`, `lib/features/incense/incense_provider.dart`
- Assets: `assets/models/incense_bowl.glb`, `assets/audio/incense_ambient.mp3`

- [ ] **Step 1: Viết IncenseProvider xử lý logic thắp hương**

```dart
class IncenseProvider with ChangeNotifier {
  bool _isBurning = false;
  double _remainingTime = 0; // In seconds
  bool get isBurning => _isBurning;
  double get remainingTime => _remainingTime;

  void startBurning(int minutes) {
    _isBurning = true;
    _remainingTime = minutes * 60.0;
    notifyListeners();
    // Start timer logic
  }
}
```

- [ ] **Step 2: Tạo giao diện 3D IncenseScreen**
- [ ] **Step 3: Tích hợp hiệu ứng khói (Particle System giả lập qua O3D hoặc overlay)**
- [ ] **Step 4: Commit**

---

### Task 6: Vietnamese Lunar Calendar & Notifications

**Files:**
- Create: `lib/features/calendar/lunar_calendar_screen.dart`, `lib/services/notification_service.dart`

- [ ] **Step 1: Tích hợp thư viện Lịch âm Việt Nam**
- [ ] **Step 2: Giao diện hiển thị lịch tháng kết hợp Âm/Dương**
- [ ] **Step 3: Thiết lập NotificationService để nhắc nhở ngày Rằm/Mồng Một**
- [ ] **Step 4: Commit**

---

### Task 7: Real-time Community Features

**Files:**
- Modify: `lib/features/monk_bell/monk_bell_provider.dart`, `lib/features/monk_bell/monk_bell_screen.dart`
- Create: `lib/features/community/leaderboard_screen.dart`

- [ ] **Step 1: Logic cập nhật "Online Status" lên Firestore**
- [ ] **Step 2: Lắng nghe số lượng người online thời gian thực**
- [ ] **Step 3: Giao diện Bảng xếp hạng tu tập (Leaderboard)**
- [ ] **Step 4: Commit**

---

### Task 8: Final Polish & Multi-platform Check

- [ ] **Step 1: Kiểm tra độ mượt trên Android/iOS**
- [ ] **Step 2: Tối ưu dung lượng tệp 3D**
- [ ] **Step 3: Hoàn thiện màn hình "Cá nhân" (Profile)**
- [ ] **Step 4: Commit**
