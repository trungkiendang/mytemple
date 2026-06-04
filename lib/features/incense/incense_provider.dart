import 'dart:async';
import 'package:flutter/material.dart';

class IncenseProvider with ChangeNotifier {
  bool _isBurning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  int _stickCount = 1;
  int _totalIncenseSeconds = 0;

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

  String get modelSrc => 'assets/models/incense_$_stickCount.glb';

  void setStickCount(int count) {
    if (count == 1 || count == 3 || count == 5) {
      _stickCount = count;
      notifyListeners();
    }
  }

  void startBurning(int durationMinutes) {
    if (_isBurning) return;

    _isBurning = true;
    _remainingSeconds = durationMinutes * 60;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _totalIncenseSeconds++;
        notifyListeners();
      } else {
        stopBurning();
      }
    });
  }

  void stopBurning() {
    _isBurning = false;
    _remainingSeconds = 0;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
