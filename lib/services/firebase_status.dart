import 'package:flutter/foundation.dart';

/// Connection state of the online features, set during startup so the UI can show
/// why it is running on local data (e.g. anonymous sign-in disabled in the console).
class FirebaseStatus {
  /// null = everything is fine; otherwise a Vietnamese explanation.
  static final ValueNotifier<String?> issue = ValueNotifier<String?>(null);

  static void report(Object error) {
    final text = error.toString();
    if (text.contains('operation-not-allowed') || text.contains('ADMIN_ONLY_OPERATION')) {
      issue.value = 'Đăng nhập ẩn danh chưa được bật trong Firebase Console (Authentication → Sign-in method).';
    } else if (text.contains('TimeoutException')) {
      issue.value = 'Không kết nối được máy chủ Firebase (hết thời gian chờ).';
    } else {
      issue.value = 'Lỗi Firebase: $text';
    }
  }
}
