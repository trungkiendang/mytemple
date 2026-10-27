import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../community/leaderboard_screen.dart';
import 'monk_bell_provider.dart';

class MonkBellScreen extends StatefulWidget {
  const MonkBellScreen({super.key});

  @override
  State<MonkBellScreen> createState() => _MonkBellScreenState();
}

class _TapEffect {
  final Offset position;
  final AnimationController controller;
  _TapEffect(this.position, this.controller);
}

class _MonkBellScreenState extends State<MonkBellScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final O3DController _controller = O3DController();
  late final AnimationController _strike;
  final List<_TapEffect> _effects = [];
  StreamSubscription<void>? _tapSub;
  Offset? _pointer; // last pointer / touch position (strike point)
  Size _area = Size.zero;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _strike = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _tapSub = context.read<MonkBellProvider>().tapEvents.listen((_) => _animateStrike());
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _strike.dispose();
    for (final e in _effects) {
      e.controller.dispose();
    }
    super.dispose();
  }

  /// Where the mallet hits when there is no pointer (auto-tap / first launch).
  Offset get _defaultStrikePoint => Offset(_area.width * 0.5, _area.height * 0.46);

  void _animateStrike() {
    if (!mounted) return;
    _strike.forward(from: 0).then((_) {
      if (mounted) _strike.reverse();
    });
    final pos = _pointer ?? _defaultStrikePoint;
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final effect = _TapEffect(pos, c);
    setState(() => _effects.add(effect));
    if (_effects.length > 8) {
      _effects.removeAt(0).controller.dispose();
    }
    c.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _effects.remove(effect));
      c.dispose();
    });
    // little bounce of the 3D model
    _controller.cameraTarget(0, 0.06, 0);
    Future.delayed(const Duration(milliseconds: 70), () => _controller.cameraTarget(0, 0, 0));
  }

  void _onPointerMove(Offset p) => setState(() => _pointer = p);

  void _strikeAt(Offset p) {
    setState(() => _pointer = p);
    context.read<MonkBellProvider>().tap();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gõ Mõ'),
        actions: [
          IconButton(
            tooltip: 'Bảng xếp hạng',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, box) {
        _area = Size(box.maxWidth, box.maxHeight);
        return Stack(
          children: [
            // soft temple-light background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 0.9,
                    colors: [Colors.white.withValues(alpha: 0.9), AppTheme.parchment],
                  ),
                ),
              ),
            ),

            // 3D wooden fish (input is handled by the Flutter layer below)
            Positioned(
              top: 150,
              bottom: 190,
              left: 0,
              right: 0,
              child: O3D(
                id: 'monk-bell',
                controller: _controller,
                src: 'assets/models/mo.glb',
                autoPlay: true,
                autoRotate: true,
                rotationPerSecond: '20deg',
                cameraControls: false,
                disableTap: true,
                backgroundColor: Colors.transparent,
                loading: Loading.eager,
                environmentImage: 'neutral',
              ),
            ),

            // touch / mouse layer: mallet follows the pointer and strikes on tap
            Positioned.fill(
              child: MouseRegion(
                cursor: SystemMouseCursors.none,
                onHover: (e) => _onPointerMove(e.localPosition),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _strikeAt(e.localPosition),
                  onPointerMove: (e) => _onPointerMove(e.localPosition),
                  child: AnimatedBuilder(
                    animation: _strike,
                    builder: (context, _) => CustomPaint(
                      painter: _MalletPainter(
                        head: _pointer ?? _defaultStrikePoint,
                        strike: Curves.easeOut.transform(_strike.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ripples + floating "+1"
            for (final e in _effects)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: e.controller,
                    builder: (context, _) => CustomPaint(
                      painter: _EffectPainter(e.position, e.controller.value),
                    ),
                  ),
                ),
              ),

            const Positioned(top: 16, left: 0, right: 0, child: IgnorePointer(child: _StatsHeader())),
            const Positioned(bottom: 16, left: 16, right: 16, child: _ControlPanel()),
          ],
        );
      }),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MonkBellProvider>();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.darkWood, AppTheme.woodBrown]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text(
                  '${p.tapCount}',
                  key: ValueKey(p.tapCount),
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppTheme.gold),
                ),
              ),
              const Text('Lượt gõ · Công đức của bạn',
                  style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _badge('Toàn cầu: ${p.globalTapCount}', Icons.public, AppTheme.antiqueGold),
            const SizedBox(width: 8),
            _badge('${p.onlineUsersCount} đang tu tập', Icons.circle, Colors.green, iconSize: 9),
          ],
        ),
      ],
    );
  }

  Widget _badge(String label, IconData icon, Color color, {double iconSize = 13}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkWood)),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MonkBellProvider>();
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chạm hoặc nhấp chuột để gõ mõ',
              style: TextStyle(color: AppTheme.darkWood, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.autorenew, size: 18, color: AppTheme.woodBrown),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Tự động gõ', style: TextStyle(color: AppTheme.darkWood, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: p.isAutoTapping,
                  activeThumbColor: AppTheme.antiqueGold,
                  onChanged: (v) => v ? p.startAutoTap() : p.stopAutoTap(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Nhịp/phút:', style: TextStyle(fontSize: 12, color: AppTheme.lightWood)),
                const SizedBox(width: 8),
                for (final s in MonkBellProvider.autoSpeeds)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text('$s'),
                      selected: p.autoSpeed == s,
                      onSelected: (_) => p.setAutoSpeed(s),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The mallet (dùi): the ball sits on the strike point, the handle leans up-right and
/// swings down on a strike.
class _MalletPainter extends CustomPainter {
  final Offset head;
  final double strike; // 0..1
  _MalletPainter({required this.head, required this.strike});

  @override
  void paint(Canvas canvas, Size size) {
    const handleLen = 170.0;
    final angle = -1.05 + strike * 0.35; // radians from +x; leaning up-right, swings down
    final dir = Offset(math.cos(angle), math.sin(angle));
    final ballCenter = head + Offset(0, strike * 6) - dir * 0; // ball touches the strike point
    final end = ballCenter + dir * handleLen;

    // soft shadow under the ball
    canvas.drawOval(
      Rect.fromCenter(center: head + const Offset(0, 20), width: 54, height: 12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12 + strike * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // handle
    final handle = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF7B3F1E), Color(0xFF4A2410)])
          .createShader(Rect.fromPoints(ballCenter, end))
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(ballCenter + dir * 10, end, handle);
    canvas.drawLine(
      end - dir * 40,
      end - dir * 34,
      Paint()
        ..color = AppTheme.antiqueGold
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.butt,
    );

    // ball head (cream ivory with a highlight)
    final r = 25.0 - strike * 1.5;
    canvas.drawCircle(
      ballCenter,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: const [Colors.white, Color(0xFFEBDDB8), Color(0xFFC9B07A)],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: ballCenter, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_MalletPainter old) => old.head != head || old.strike != strike;
}

class _EffectPainter extends CustomPainter {
  final Offset position;
  final double t; // 0..1
  _EffectPainter(this.position, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = 1 - t;
    canvas.drawCircle(
      position,
      12 + t * 46,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade + 0.5
        ..color = AppTheme.antiqueGold.withValues(alpha: 0.7 * fade),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '+1',
        style: TextStyle(
          color: AppTheme.antiqueGold.withValues(alpha: fade),
          fontSize: 22 + 6 * t,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25 * fade), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position + Offset(-tp.width / 2, -50 - 60 * t));
  }

  @override
  bool shouldRepaint(_EffectPainter old) => old.t != t || old.position != position;
}
