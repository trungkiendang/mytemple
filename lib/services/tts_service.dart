import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  double _rate = 0.5;
  Completer<void>? _speaking;

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

    if (!kIsWeb && Platform.isIOS) {
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ]);
    }

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _finishSpeaking();
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      _finishSpeaking();
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
      _finishSpeaking();
      notifyListeners();
    });
  }

  void _finishSpeaking() {
    final c = _speaking;
    _speaking = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Speaks [text] and completes when the utterance ends (or is cancelled / errors /
  /// [timeout] passes — some platforms never report completion).
  Future<void> speakAndWait(String text, {Duration timeout = const Duration(seconds: 30)}) async {
    if (text.isEmpty) return;
    _finishSpeaking();
    final done = Completer<void>();
    _speaking = done;
    await _flutterTts.speak(text);
    await done.future.timeout(timeout, onTimeout: () {});
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
    _finishSpeaking();
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
