import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../services/analytics_service.dart';
import '../../services/firebase_status.dart';

/// Tap counter for the wooden fish. Counts are persisted locally (Hive `settings`)
/// and synced to Firestore in small batches when Firebase is reachable.
class MonkBellProvider with ChangeNotifier {
  static const _tapKey = 'tap_count';
  static const List<int> autoSpeeds = [40, 60, 90, 120]; // taps per minute

  int _tapCount = Hive.box('settings').get(_tapKey, defaultValue: 0) as int;
  int get tapCount => _tapCount;

  int _globalTapCount = 0;
  int get globalTapCount => _globalTapCount;

  int _onlineUsersCount = 0;
  int get onlineUsersCount => _onlineUsersCount;

  bool _isAutoTapping = false;
  bool get isAutoTapping => _isAutoTapping;
  int _autoSpeed = 60;
  int get autoSpeed => _autoSpeed;

  /// Emits an event for every tap (manual or automatic) so the UI can animate.
  final StreamController<void> _tapEvents = StreamController<void>.broadcast();
  Stream<void> get tapEvents => _tapEvents.stream;

  final AudioPlayer player = AudioPlayer();
  FirebaseFirestore? _firestore;
  Timer? _autoTimer;
  Timer? _flushTimer;
  Timer? _presenceTimer;
  StreamSubscription? _statsSub;
  int _pendingTaps = 0;

  MonkBellProvider() {
    player.setPlayerMode(PlayerMode.lowLatency);
    _initFirebase();
  }

  /// True when Firestore is usable (Firebase initialised and a user is signed in).
  bool get cloudReady =>
      _firestore != null && FirebaseStatus.issue.value == null && FirebaseAuth.instance.currentUser != null;

  void _initFirebase() {
    if (Firebase.apps.isEmpty) return;
    _firestore = FirebaseFirestore.instance;
    _listenToGlobalStats();
    _flushTimer = Timer.periodic(const Duration(seconds: 4), (_) => _flush());
    _presenceTimer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshPresence());
    _refreshPresence();
  }

  void _listenToGlobalStats() {
    _statsSub = _firestore!.collection('stats').doc('global_stats').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        _globalTapCount = (data?['total_taps'] ?? 0) as int;
        if (_onlineUsersCount == 0) {
          _onlineUsersCount = (data?['online_users'] ?? 1) as int;
        }
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Stats listener error: $e'));
  }

  Future<void> _refreshPresence() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_firestore == null || user == null) return;
    try {
      await _firestore!.collection('users').doc(user.uid).set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 3)));
      final result = await _firestore!
          .collection('users')
          .where('lastActive', isGreaterThan: since)
          .count()
          .get();
      final online = result.count ?? 0;
      if (online > 0 && online != _onlineUsersCount) {
        _onlineUsersCount = online;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Presence error: $e');
    }
  }

  void tap() {
    _tapCount++;
    _pendingTaps++;
    Hive.box('settings').put(_tapKey, _tapCount);
    if (const {10, 50, 108, 500, 1000, 5000}.contains(_tapCount)) {
      AnalyticsService.logEvent('tap_milestone', {'count': _tapCount});
    }
    _tapEvents.add(null);
    notifyListeners();

    player.stop().then((_) => player.play(AssetSource('audio/bell_sound.wav'))).catchError((_) {});
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void startAutoTap([int? perMinute]) {
    if (perMinute != null) _autoSpeed = perMinute;
    _autoTimer?.cancel();
    if (!_isAutoTapping) AnalyticsService.logEvent('auto_tap_start', {'bpm': _autoSpeed});
    _isAutoTapping = true;
    _autoTimer = Timer.periodic(Duration(milliseconds: (60000 / _autoSpeed).round()), (_) => tap());
    notifyListeners();
  }

  void stopAutoTap() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _isAutoTapping = false;
    notifyListeners();
  }

  void setAutoSpeed(int perMinute) {
    _autoSpeed = perMinute;
    if (_isAutoTapping) {
      startAutoTap();
    } else {
      notifyListeners();
    }
  }

  Future<void> _flush() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_pendingTaps == 0 || _firestore == null || user == null) return;
    final count = _pendingTaps;
    _pendingTaps = 0;
    try {
      final batch = _firestore!.batch();
      batch.set(
        _firestore!.collection('stats').doc('global_stats'),
        {'total_taps': FieldValue.increment(count)},
        SetOptions(merge: true),
      );
      batch.set(
        _firestore!.collection('users').doc(user.uid),
        {
          'displayName': user.displayName ?? user.email?.split('@').first ?? 'Người tu tập ${user.uid.substring(0, 4)}',
          'tapCount': FieldValue.increment(count),
          'lastActive': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (e) {
      _pendingTaps += count; // retry on the next flush
      debugPrint('Tap sync error: $e');
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _flushTimer?.cancel();
    _presenceTimer?.cancel();
    _statsSub?.cancel();
    _tapEvents.close();
    player.dispose();
    super.dispose();
  }
}
