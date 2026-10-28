import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../services/tts_service.dart';

class PrayerLine {
  final String text;

  /// A line the user fills in themselves (name / address): shown as a prompt and not spoken.
  final bool fill;
  const PrayerLine(this.text, {this.fill = false});
}

class Prayer {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final bool loop;
  final List<PrayerLine> lines;
  const Prayer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.loop,
    required this.lines,
  });

  factory Prayer.fromJson(Map<String, dynamic> j) => Prayer(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        loop: (j['loop'] ?? false) as bool,
        lines: [
          for (final l in j['lines'] as List) PrayerLine(l['t'] as String, fill: (l['fill'] ?? false) as bool),
        ],
      );

  /// Plain text (used by the scripture library).
  String get fullText => lines.map((l) => l.text).join('\n\n');
}

enum ReadMode { subtitle, voice }

/// Karaoke-style reading of prayers while burning incense: either scrolling subtitles
/// (timed from the line length) or spoken aloud with text-to-speech, highlighting the
/// current line and, within it, the words as they are read.
class PrayerProvider extends ChangeNotifier {
  static const speeds = [0.75, 1.0, 1.25, 1.5];

  final TtsService _tts;
  final Box _settings = Hive.box('settings');

  List<Prayer> prayers = [];
  Prayer? selected;
  ReadMode mode = ReadMode.subtitle;
  bool autoRead = true;
  double speed = 1.0;

  int index = 0;
  double progress = 0; // 0..1 within the current line
  bool playing = false;

  int _session = 0; // bumped to cancel the running read loop
  bool _wasBurning = false;

  PrayerProvider(this._tts) {
    mode = _settings.get('prayer_mode', defaultValue: 'subtitle') == 'voice' ? ReadMode.voice : ReadMode.subtitle;
    autoRead = _settings.get('prayer_auto', defaultValue: true) as bool;
    _load();
  }

  static Future<List<Prayer>> loadAsset() async {
    final raw = await rootBundle.loadString('assets/data/prayers.json');
    return [for (final e in jsonDecode(raw) as List) Prayer.fromJson(e as Map<String, dynamic>)];
  }

  Future<void> _load() async {
    try {
      prayers = await loadAsset();
      final id = _settings.get('prayer_id') as String?;
      selected = prayers.where((p) => p.id == id).firstOrNull;
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load prayers: $e');
    }
  }

  PrayerLine? get currentLine =>
      selected != null && index < selected!.lines.length ? selected!.lines[index] : null;

  void select(Prayer? prayer) {
    stop();
    selected = prayer;
    _settings.put('prayer_id', prayer?.id);
    notifyListeners();
  }

  void setMode(ReadMode m) {
    if (mode == m) return;
    final wasPlaying = playing;
    pause();
    mode = m;
    _settings.put('prayer_mode', m == ReadMode.voice ? 'voice' : 'subtitle');
    notifyListeners();
    if (wasPlaying) start();
  }

  void setAutoRead(bool v) {
    autoRead = v;
    _settings.put('prayer_auto', v);
    notifyListeners();
  }

  void setSpeed(double v) {
    speed = v;
    _tts.setRate(0.45 * v);
    if (playing) {
      pause();
      start();
    } else {
      notifyListeners();
    }
  }

  /// Called by the incense screen whenever the burning state may have changed.
  void syncBurning(bool burning) {
    if (burning == _wasBurning) return;
    _wasBurning = burning;
    if (burning) {
      if (autoRead && selected != null) {
        index = 0;
        start();
      }
    } else {
      stop();
    }
  }

  void seek(int i) {
    final p = selected;
    if (p == null) return;
    final wasPlaying = playing;
    pause();
    index = i.clamp(0, p.lines.length - 1);
    progress = 0;
    notifyListeners();
    if (wasPlaying) start();
  }

  void toggle() => playing ? pause() : start();

  void pause() {
    playing = false;
    _session++;
    _tts.stop();
    notifyListeners();
  }

  void stop() {
    pause();
    index = 0;
    progress = 0;
    notifyListeners();
  }

  Duration _estimate(PrayerLine line) {
    if (line.fill) return const Duration(seconds: 5);
    final perChar = mode == ReadMode.voice ? 0.075 : 0.09;
    final seconds = (line.text.length * perChar / speed).clamp(1.8, 40.0);
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Future<void> start() async {
    final p = selected;
    if (p == null || p.lines.isEmpty || playing) return;
    if (!p.loop && index >= p.lines.length - 1 && progress >= 1) index = 0; // replay from the start
    playing = true;
    final session = ++_session;
    notifyListeners();

    bool alive() => session == _session;
    while (alive()) {
      while (index < p.lines.length && alive()) {
        await _readLine(p.lines[index], alive);
        if (!alive()) return;
        if (index < p.lines.length - 1 || p.loop) {
          index = (index + 1) % p.lines.length;
          progress = 0;
          notifyListeners();
          if (index == 0 && !p.loop) break;
        } else {
          break;
        }
      }
      if (!alive()) return;
      if (!p.loop) {
        playing = false;
        progress = 1;
        notifyListeners();
        return;
      }
    }
  }

  Future<void> _readLine(PrayerLine line, bool Function() alive) async {
    final total = _estimate(line);
    final started = DateTime.now();
    progress = 0;
    notifyListeners();

    final ticker = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!alive()) return;
      final t = DateTime.now().difference(started).inMilliseconds / total.inMilliseconds;
      progress = t.clamp(0.0, 0.98);
      notifyListeners();
    });

    try {
      if (mode == ReadMode.voice && !line.fill) {
        await _tts.speakAndWait(line.text, timeout: total * 3);
      } else {
        // subtitle mode (or a line the user reads on their own): wait the estimated time
        final end = started.add(total);
        while (alive() && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
      }
      if (alive()) {
        progress = 1;
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 450)); // breath between lines
      }
    } finally {
      ticker.cancel();
    }
  }

  @override
  void dispose() {
    _session++;
    _tts.stop();
    super.dispose();
  }
}
