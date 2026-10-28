import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'prayer_provider.dart';

/// Bottom sheet to choose the prayer and how it is read.
Future<void> showPrayerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.ivory,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => _PrayerSheet(controller: controller),
    ),
  );
}

class _PrayerSheet extends StatelessWidget {
  final ScrollController controller;
  const _PrayerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PrayerProvider>();
    final categories = <String>[];
    for (final x in p.prayers) {
      if (!categories.contains(x.category)) categories.add(x.category);
    }
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text('Chọn bài khấn / kinh để đọc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkWood)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<ReadMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ReadMode.subtitle, icon: Icon(Icons.subtitles_outlined), label: Text('Chữ chạy')),
              ButtonSegment(value: ReadMode.voice, icon: Icon(Icons.record_voice_over_outlined), label: Text('Giọng đọc')),
            ],
            selected: {p.mode},
            onSelectionChanged: (s) => p.setMode(s.first),
          ),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: const Text('Tự động đọc khi thắp hương'),
          value: p.autoRead,
          activeThumbColor: AppTheme.antiqueGold,
          onChanged: p.setAutoRead,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ListTile(
                leading: const Icon(Icons.volume_off_outlined, color: AppTheme.woodBrown),
                title: const Text('Không đọc kinh'),
                trailing: p.selected == null ? const Icon(Icons.check_circle, color: AppTheme.antiqueGold) : null,
                onTap: () {
                  p.select(null);
                  Navigator.pop(context);
                },
              ),
              for (final c in categories) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Text(c.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.lightWood)),
                ),
                for (final x in p.prayers.where((x) => x.category == c))
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: AppTheme.woodBrown),
                    title: Text(x.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkWood)),
                    subtitle: Text(x.subtitle),
                    trailing: p.selected?.id == x.id ? const Icon(Icons.check_circle, color: AppTheme.antiqueGold) : null,
                    onTap: () {
                      p.select(x);
                      Navigator.pop(context);
                    },
                  ),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Nội dung văn khấn mang tính tham khảo, có thể khác nhau theo vùng miền và truyền thống từng gia đình.',
                  style: TextStyle(fontSize: 12, color: AppTheme.lightWood, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dark "karaoke" card: lines scroll to the current one, words light up as they are read.
class PrayerReaderCard extends StatefulWidget {
  final double height;
  const PrayerReaderCard({super.key, this.height = 230});

  @override
  State<PrayerReaderCard> createState() => _PrayerReaderCardState();
}

class _PrayerReaderCardState extends State<PrayerReaderCard> {
  final _keys = <int, GlobalKey>{};
  int _lastIndex = -1;

  void _scrollTo(int index) {
    final ctx = _keys[index]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, alignment: 0.4, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PrayerProvider>();
    final prayer = p.selected;
    if (prayer == null) return const SizedBox.shrink();
    if (p.index != _lastIndex) {
      _lastIndex = p.index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollTo(p.index);
      });
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.darkWood, Color(0xFF2A1A16)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.menu_book, size: 16, color: AppTheme.antiqueGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(prayer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.antiqueGold, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: p.mode == ReadMode.voice ? 'Đang đọc thành tiếng' : 'Chữ chạy',
                  icon: Icon(p.mode == ReadMode.voice ? Icons.record_voice_over : Icons.subtitles_outlined, color: Colors.white70, size: 20),
                  onPressed: () => p.setMode(p.mode == ReadMode.voice ? ReadMode.subtitle : ReadMode.voice),
                ),
              ],
            ),
          ),
          Expanded(
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.15, 0.85, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
                child: Column(
                  children: [
                    for (var i = 0; i < prayer.lines.length; i++)
                      GestureDetector(
                        key: _keys.putIfAbsent(i, GlobalKey.new),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => p.seek(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: _KaraokeLine(
                            line: prayer.lines[i],
                            state: i < p.index ? _LineState.done : (i == p.index ? _LineState.current : _LineState.next),
                            progress: i == p.index ? p.progress : (i < p.index ? 1 : 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Câu trước',
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70),
                  onPressed: () => p.seek(p.index - 1),
                ),
                IconButton(
                  tooltip: p.playing ? 'Tạm dừng' : 'Đọc',
                  iconSize: 36,
                  icon: Icon(p.playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppTheme.antiqueGold),
                  onPressed: p.toggle,
                ),
                IconButton(
                  tooltip: 'Câu sau',
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
                  onPressed: () => p.seek(p.index + 1),
                ),
                PopupMenuButton<double>(
                  tooltip: 'Tốc độ',
                  initialValue: p.speed,
                  onSelected: p.setSpeed,
                  itemBuilder: (_) => [for (final s in PrayerProvider.speeds) PopupMenuItem(value: s, child: Text('${s}x'))],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text('${p.speed}x', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LineState { done, current, next }

class _KaraokeLine extends StatelessWidget {
  final PrayerLine line;
  final _LineState state;
  final double progress;
  const _KaraokeLine({required this.line, required this.state, required this.progress});

  @override
  Widget build(BuildContext context) {
    final current = state == _LineState.current;
    final size = current ? 19.0 : 15.0;
    final style = TextStyle(fontSize: size, height: 1.4, fontWeight: current ? FontWeight.w700 : FontWeight.w500, fontStyle: line.fill ? FontStyle.italic : FontStyle.normal);

    if (!current) {
      final color = state == _LineState.done ? AppTheme.antiqueGold.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.5);
      return Text(line.text, textAlign: TextAlign.center, style: style.copyWith(color: color));
    }
    // words already read turn gold, the rest stay cream
    final words = line.text.split(' ');
    final reached = (progress * words.length).floor();
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < words.length; i++)
            TextSpan(
              text: i == words.length - 1 ? words[i] : '${words[i]} ',
              style: style.copyWith(color: i < reached ? AppTheme.gold : Colors.white),
            ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
