import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';

class IncenseProvider with ChangeNotifier {
  bool _isBurning = false;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  DateTime? _startedAt;
  bool _burntOut = false;
  int _stickCount = 1;
  int _totalIncenseSeconds = 0;
  String _petition = '';
  int _selectedMinutes = 5;
  static const durations = [1, 5, 15, 30];

  int get selectedMinutes => _selectedMinutes;

  void setSelectedMinutes(int m) {
    _selectedMinutes = m;
    notifyListeners();
  }

  /// Prayer attached to the incense (shown while burning).
  String get petition => _petition;

  void setPetition(String value) {
    _petition = value.trim();
    notifyListeners();
  }

  bool get isBurning => _isBurning;
  int get remainingSeconds => _remainingSeconds;
  int get stickCount => _stickCount;
  int get totalIncenseSeconds => _totalIncenseSeconds;

  String get totalIncenseFormatted {
    final hours = _totalIncenseSeconds ~/ 3600;
    final minutes = (_totalIncenseSeconds % 3600) ~/ 60;
    if (hours > 0) return '$hours giờ $minutes phút';
    return '$minutes phút';
  }

  String get remainingTimeFormatted {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static const modelSrc = 'assets/models/incense_censer.glb';

  /// The incense has burnt all the way down (timer finished) – shown until the next lighting.
  bool get burntOut => _burntOut;

  /// 0 when just lit → 1 when the chosen time has elapsed. Based on the wall clock so the
  /// sticks burn down smoothly and finish exactly when the countdown reaches 00:00.
  double get burnProgress {
    if (_burntOut) return 1;
    if (!_isBurning || _startedAt == null || _totalSeconds <= 0) return 0;
    final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds / 1000;
    return (elapsed / _totalSeconds).clamp(0.0, 1.0);
  }

  void setStickCount(int count) {
    if (count == 1 || count == 3 || count == 5) {
      if (_isBurning) return;
      _stickCount = count;
      _burntOut = false;
      notifyListeners();
    }
  }

  void startBurning(int durationMinutes) {
    if (_isBurning) return;

    AnalyticsService.logEvent('incense_start', {
      'sticks': _stickCount,
      'minutes': durationMinutes,
      'has_petition': _petition.isNotEmpty ? 1 : 0,
    });
    _isBurning = true;
    _burntOut = false;
    _remainingSeconds = durationMinutes * 60;
    _totalSeconds = _remainingSeconds;
    _startedAt = DateTime.now();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // derive the countdown from the wall clock so it cannot drift if timers are throttled
      final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
      final left = (_totalSeconds - elapsed).clamp(0, _totalSeconds);
      if (left < _remainingSeconds) {
        _totalIncenseSeconds += _remainingSeconds - left;
        _remainingSeconds = left;
      }
      if (_remainingSeconds > 0) {
        notifyListeners();
      } else {
        _finishBurning();
      }
    });
  }

  /// The chosen time is over: the sticks are burnt out (ash stubs are shown).
  void _finishBurning() {
    AnalyticsService.logEvent('incense_complete', {'sticks': _stickCount, 'minutes': _totalSeconds ~/ 60});
    _burntOut = true;
    _endBurning();
  }

  /// The user stopped early: back to fresh sticks.
  void stopBurning() {
    _burntOut = false;
    _endBurning();
  }

  void _endBurning() {
    _isBurning = false;
    _remainingSeconds = 0;
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
