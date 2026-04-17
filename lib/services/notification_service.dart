import 'package:flutter/foundation.dart';

// Temporary mock service to fix compilation errors for web/mobile
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    debugPrint("NotificationService initialized (Mock)");
  }

  Future<void> showNotification({int id = 0, String? title, String? body}) async {
    debugPrint("Notification: $title - $body (Mock)");
  }

  Future<void> scheduleLunarReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    debugPrint("Scheduled: $title at $scheduledDate (Mock)");
  }
}
