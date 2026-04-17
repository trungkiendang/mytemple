import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  double _rate = 0.5;

  TtsState get ttsState => _ttsState;
  double get rate => _rate;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isStopped => _ttsState == TtsState.stopped;
  bool get isPaused => _ttsState == TtsState.paused;
  bool get isContinued => _ttsState == TtsState.continued;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
      notifyListeners();
    });

    _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.continued;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    await _flutterTts.setSpeechRate(rate);
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
