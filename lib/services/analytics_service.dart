import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Thin, failure-proof wrapper over Google Analytics (Firebase Analytics, project temple-a6cf8).
/// Every call is a no-op when Firebase is unavailable or Analytics is not configured, so
/// tracking can never break the app.
///
/// Web needs the GA4 measurement id at build time: `--dart-define=GA_MEASUREMENT_ID=G-XXXXXXX`
/// (set as the GitHub variable `GA_MEASUREMENT_ID`, see docs/ANALYTICS.md).
class AnalyticsService {
  static const webMeasurementId = String.fromEnvironment('GA_MEASUREMENT_ID');

  static FirebaseAnalytics? _analytics;
  static bool get enabled => _analytics != null;

  static Future<void> init() async {
    if (Firebase.apps.isEmpty) return;
    if (kIsWeb && webMeasurementId.isEmpty) {
      debugPrint('Analytics: GA_MEASUREMENT_ID not set, web tracking disabled');
      return;
    }
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      _analytics = analytics;
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  static void logEvent(String name, [Map<String, Object>? parameters]) {
    final a = _analytics;
    if (a == null) return;
    a.logEvent(name: name, parameters: parameters).catchError((Object e) => debugPrint('Analytics $name: $e'));
  }

  static void screen(String name) {
    final a = _analytics;
    if (a == null) return;
    a.logScreenView(screenName: name).catchError((Object e) => debugPrint('Analytics screen $name: $e'));
  }

  static void setUser(String? uid) {
    _analytics?.setUserId(id: uid).catchError((Object e) => debugPrint('Analytics setUser: $e'));
  }
}
