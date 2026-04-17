import 'dart:async';
import 'package:flutter/material.dart';

class IncenseProvider with ChangeNotifier {
  bool _isBurning = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  bool get isBurning => _isBurning;
  int get remainingSeconds => _remainingSeconds;

  String get remainingTimeFormatted {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startBurning(int durationMinutes) {
    if (_isBurning) return;

    _isBurning = true;
    _remainingSeconds = durationMinutes * 60;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
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
