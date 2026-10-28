import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../services/analytics_service.dart';
import '../../services/tts_service.dart';

class PrayerLine {
  final String text;

  /// A line the user fills in themselves (name / address): shown as a prompt and not spoken.
  final bool fill;
  const PrayerLine(this.text, {this.fill = false});
}

/// A "book" of prayers in the prayer library (e.g. "Văn khấn Tết Nguyên Đán").
class PrayerBook {
  final String id;
  final String title;
  final String intro;
  const PrayerBook({required this.id, required this.title, required this.intro});
}

class Prayer {
  final String id;
  final String title;
  final String subtitle;
  final String book; // PrayerBook.id
  final bool loop;
  final List<PrayerLine> lines;

  /// Optional licensed recording (asset path relative to `assets/`, e.g. `audio/prayers/x.mp3`).
  final String? audio;
  final String? audioCredit;
  const Prayer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.book,
    required this.loop,
    required this.lines,
    this.audio,
    this.audioCredit,
  });

  factory Prayer.fromJson(Map<String, dynamic> j) => Prayer(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] ?? '') as String,
        book: (j['book'] ?? '') as String,
        audio: j['audio'] as String?,
        audioCredit: j['audioCredit'] as String?,
        loop: (j['loop'] ?? false) as bool,
        lines: [
          for (final l in j['lines'] as List) PrayerLine(l['t'] as String, fill: (l['fill'] ?? false) as bool),
        ],
      );

  /// Plain text (used by the scripture library).
  String get fullText => lines.map((l) => l.text).join('\n\n');
}

/// subtitle = scrolling karaoke text, voice = text-to-speech, recording = a licensed recording
/// (only for prayers that ship an `audio` file).
enum ReadMode { subtitle, voice, recording }

/// End time (ms) of every line when a recording of [totalMs] is spread over the lines in
/// proportion to their length (lines the user fills in count as a fixed-size pause).
List<int> lineEndsMs(List<PrayerLine> lines, int totalMs) {
  final weights = [for (final l in lines) l.fill ? 40 : l.text.length.clamp(8, 400)];
  final sum = weights.fold<int>(0, (a, b) => a + b);
  var acc = 0;
  return [
    for (final w in weights) (acc += w) * totalMs ~/ sum,
  ];
}

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

  static Future<Map<String, dynamic>> _readAsset() async =>
      jsonDecode(await rootBundle.loadString('assets/data/prayers.json')) as Map<String, dynamic>;

  static Future<List<Prayer>> loadAsset() async =>
      [for (final e in (await _readAsset())['prayers'] as List) Prayer.fromJson(e as Map<String, dynamic>)];

  static Future<List<PrayerBook>> loadBooks() async => [
        for (final e in (await _readAsset())['books'] as List)
          PrayerBook(id: e['id'] as String, title: e['title'] as String, intro: (e['intro'] ?? '') as String),
      ];

  List<PrayerBook> books = [];

  Future<void> _load() async {
    try {
      prayers = await loadAsset();
      books = await loadBooks();
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
    if (mode == ReadMode.recording && prayer?.audio == null) mode = ReadMode.subtitle;
    _settings.put('prayer_id', prayer?.id);
    if (prayer != null) AnalyticsService.logEvent('prayer_select', {'prayer_id': prayer.id, 'mode': mode.name});
    notifyListeners();
    // picked while the incense is burning → start reading right away
    if (prayer != null && _wasBurning) start();
  }

  void setMode(ReadMode m) {
    if (mode == m) return;
    final wasPlaying = playing;
    pause();
    mode = m;
    if (m != ReadMode.recording) _settings.put('prayer_mode', m == ReadMode.voice ? 'voice' : 'subtitle');
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
    _recorder?.pause();
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

  AudioPlayer? _recorder;

  /// Plays the prayer's recording and walks the karaoke highlight through the lines in step
  /// with the playback position. Returns when the recording ends (or is cancelled).
  Future<void> _playRecording(Prayer p, bool Function() alive) async {
    final player = _recorder ??= AudioPlayer();
    await player.stop();
    await player.setSource(AssetSource(p.audio!));
    final total = await player.getDuration();
    final totalMs = (total?.inMilliseconds ?? 0) > 0
        ? total!.inMilliseconds
        : p.lines.fold<int>(0, (a, l) => a + _estimate(l).inMilliseconds);
    final ends = lineEndsMs(p.lines, totalMs);
    await player.resume();
    final started = DateTime.now();
    while (alive()) {
      final pos = (await player.getCurrentPosition())?.inMilliseconds ?? DateTime.now().difference(started).inMilliseconds;
      var i = ends.indexWhere((e) => pos < e);
      if (i < 0) i = ends.length - 1;
      final lineStart = i == 0 ? 0 : ends[i - 1];
      index = i;
      progress = ((pos - lineStart) / (ends[i] - lineStart).clamp(1, 1 << 30)).clamp(0.0, 1.0);
      notifyListeners();
      if (pos >= totalMs || player.state == PlayerState.completed) break;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    await player.stop();
  }

  Future<void> start() async {
    final p = selected;
    if (p == null || p.lines.isEmpty || playing) return;
    if (!p.loop && index >= p.lines.length - 1 && progress >= 1) index = 0; // replay from the start
    playing = true;
    final session = ++_session;
    notifyListeners();

    bool alive() => session == _session;
    if (mode == ReadMode.recording && p.audio != null) {
      try {
        do {
          await _playRecording(p, alive);
        } while (alive() && p.loop);
      } catch (e) {
        debugPrint('Recording playback failed: $e');
      }
      if (alive()) {
        playing = false;
        progress = 1;
        notifyListeners();
      }
      return;
    }
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
    _recorder?.dispose();
    super.dispose();
  }
}
