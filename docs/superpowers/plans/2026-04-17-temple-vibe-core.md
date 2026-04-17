# Temple-Vibe Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng khung ứng dụng Flutter (Android/iOS) cho Temple-Vibe với các tính năng Gõ mõ 3D, Thắp hương 3D, Lịch âm và Kinh văn tích hợp Firebase + Hive.

**Architecture:** Sử dụng kiến trúc Feature-based, tách biệt logic và giao diện. Firebase quản lý real-time và dữ liệu lớn, Hive quản lý dữ liệu cục bộ (Offline).

**Tech Stack:** Flutter, Firebase (Auth, Firestore, Storage), Hive, `o3d`, `flutter_lunar_calendar`, `provider`.

---

### Task 1: Project Scaffolding & Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/main.dart`, `lib/core/constants.dart`, `lib/core/app_theme.dart`

- [ ] **Step 1: Cấu hình pubspec.yaml**

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_storage: ^12.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  o3d: ^0.1.0
  provider: ^6.1.2
  intl: ^0.19.0
  path_provider: ^2.1.3
  flutter_haptic: ^0.1.0
  audioplayers: ^6.0.0
```

- [ ] **Step 2: Chạy lệnh cài đặt**

Run: `flutter pub get`
Expected: PASS

- [ ] **Step 3: Khởi tạo App Theme**

```dart
// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    primaryColor: Color(0xFF8B4513), // Nâu gỗ
    scaffoldBackgroundColor: Color(0xFFF5F5DC), // Beige
    appBarTheme: AppBarTheme(backgroundColor: Color(0xFF8B4513)),
  );
}
```

- [ ] **Step 4: Khởi tạo main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'lib/core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TempleVibeApp());
}

class TempleVibeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temple Vibe',
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: Text('Temple Vibe Initialized'))),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "chore: initial project scaffolding and dependencies"
```

---

### Task 2: Local Database Setup (Hive)

**Files:**
- Create: `lib/services/hive_service.dart`, `lib/models/scripture.dart`

- [ ] **Step 1: Tạo model Scripture**

```dart
import 'package:hive/hive.dart';
part 'scripture.g.dart';

@HiveType(typeId: 0)
class Scripture extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String content;

  Scripture({required this.id, required this.title, required this.content});
}
```

- [ ] **Step 2: Khởi tạo Hive Service**

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/scripture.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScriptureAdapter());
    await Hive.openBox<Scripture>('scriptures');
    await Hive.openBox('settings');
  }
}
```

- [ ] **Step 3: Cập nhật main.dart để gọi Hive.init**

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: setup Hive for local storage"
```

---

### Task 3: 3D Feature - Monk Bell (Gõ mõ)

**Files:**
- Create: `lib/features/monk_bell/monk_bell_screen.dart`, `lib/features/monk_bell/monk_bell_provider.dart`
- Assets: `assets/models/mo.glb`, `assets/audio/bell_sound.mp3`

- [ ] **Step 1: Viết provider xử lý logic gõ**

```dart
class MonkBellProvider with ChangeNotifier {
  int _tapCount = 0;
  int get tapCount => _tapCount;

  void tap() {
    _tapCount++;
    notifyListeners();
    // TODO: Play sound and haptic
  }
}
```

- [ ] **Step 2: Tạo giao diện 3D với O3D**

```dart
// lib/features/monk_bell/monk_bell_screen.dart
import 'package:o3d/o3d.dart';
// ... UI implementation using O3D widget
```

- [ ] **Step 3: Tích hợp âm thanh và rung**

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: implement 3D monk bell feature"
```

---

### Task 4: Hybrid Scripture Library

**Files:**
- Create: `lib/features/scriptures/scripture_list_screen.dart`, `lib/services/firebase_service.dart`

- [ ] **Step 1: Logic đồng bộ Firebase -> Hive**
- [ ] **Step 2: Giao diện danh sách kinh văn**
- [ ] **Step 3: Chế độ đọc (Auto-scroll)**
- [ ] **Step 4: Commit**

---

*(Bản kế hoạch sẽ tiếp tục với Task 5: Lunar Calendar và Task 6: Firebase Integration chi tiết sau khi các bước cơ bản hoàn tất)*
