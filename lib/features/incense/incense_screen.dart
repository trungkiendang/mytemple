import 'dart:math';

import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import 'incense_provider.dart';
import 'prayer_provider.dart';
import 'prayer_widgets.dart';
import '../monk_bell/monk_bell_provider.dart';
import '../../core/app_icons.dart';
import '../../core/app_theme.dart';

class IncenseScreen extends StatefulWidget {
  const IncenseScreen({super.key});

  @override
  State<IncenseScreen> createState() => _IncenseScreenState();
}

class _SmokeParticle {
  double x;
  double y;
  double size;
  double opacity;
  double speedY;
  double driftX;
  double life;

  _SmokeParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedY,
    required this.driftX,
    required this.life,
  });
}

class _SmokePainter extends CustomPainter {
  final List<_SmokeParticle> particles;

  _SmokePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in particles) {
      final wobble = (now / 2000 + p.x * 20) % 1.0;
      final sway = (wobble - 0.5) * 2 * 0.03;
      final opacity = p.opacity * (1 - p.life);
      final paint = Paint()
        ..color = const Color(0xFFA89F94).withValues(alpha: opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
        Offset(
          (p.x + sway + p.driftX * p.life * 2) * size.width,
          (p.y - p.life * 0.3) * size.height,
        ),
        p.size + p.life * size.width * 0.06,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SmokePainter oldDelegate) => true;
}

class _IncenseScreenState extends State<IncenseScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final O3DController _o3dController = O3DController();
  late AnimationController _smokeController;
  final List<_SmokeParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(_updateParticles);
  }

  @override
  void dispose() {
    _smokeController.dispose();
    super.dispose();
  }

  void _startSmoke(int stickCount) {
    _particles.clear();
    final count = switch (stickCount) { 3 => 20, 5 => 30, _ => 12 };
    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle(_random.nextDouble(), stickCount));
    }
    _smokeController.repeat();
  }

  void _stopSmoke() {
    _smokeController.stop();
    _particles.clear();
  }

  _SmokeParticle _createParticle(double life, int stickCount) {
    // Ember tips sit at about 28% of the view height with the camera above.
    const baseY = 0.28;
    final spread = switch (stickCount) { 3 => 0.1, 5 => 0.15, _ => 0.04 };
    return _SmokeParticle(
      x: 0.5 + (_random.nextDouble() - 0.5) * spread,
      y: baseY + (_random.nextDouble() - 0.5) * 0.02,
      size: 4 + _random.nextDouble() * 8,
      opacity: 0.2 + _random.nextDouble() * 0.3,
      speedY: 0.002 + _random.nextDouble() * 0.004,
      driftX: (_random.nextDouble() - 0.5) * 0.003,
      life: life,
    );
  }

  void _updateParticles() {
    final provider = context.read<IncenseProvider>();
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.life += 0.008;
      p.driftX += (_random.nextDouble() - 0.5) * 0.0005;
      p.size += 0.12;
      if (p.life >= 1.0) {
        _particles[i] = _createParticle(0, provider.stickCount);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final incenseProvider = Provider.of<IncenseProvider>(context);
    final monkBellProvider = Provider.of<MonkBellProvider>(context);

    final prayers = context.read<PrayerProvider>();
    final burning = incenseProvider.isBurning;
    WidgetsBinding.instance.addPostFrameCallback((_) => prayers.syncBurning(burning));

    if (incenseProvider.isBurning && !_smokeController.isAnimating) {
      _startSmoke(incenseProvider.stickCount);
    } else if (!incenseProvider.isBurning && _smokeController.isAnimating) {
      _stopSmoke();
    }

    return Scaffold(
      backgroundColor: AppTheme.parchment,
      appBar: AppBar(
        title: const Text('Thắp Hương'),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, box) {
        // Fixed bottom-panel height (same in both states) → the 3D view keeps its size.
        final panelHeight = (box.maxHeight * 0.40).clamp(318.0, 380.0);
        return Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (!incenseProvider.isBurning) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn thời gian để thắp hương')),
                        );
                      }
                    },
                    child: O3D(
                      key: ValueKey('incense-${incenseProvider.stickCount}'),
                      id: 'incense-${incenseProvider.stickCount}',
                      src: incenseProvider.modelSrc,
                      controller: _o3dController,
                      autoPlay: true,
                      autoRotate: true,
                      cameraControls: true,
                      disableZoom: true,
                      cameraOrbit: CameraOrbit(30, 80, 4),
                      cameraTarget: CameraTarget(0, 0.75, 0),
                      fieldOfView: '30deg',
                      disableTap: true,
                      backgroundColor: Colors.transparent,
                      loading: Loading.eager,
                      environmentImage: 'neutral',
                    ),
                  ),
                ),

                if (incenseProvider.isBurning)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SmokePainter(_particles),
                      ),
                    ),
                  ),

                if (monkBellProvider.cloudReady)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 8),
                        Text(
                          '${monkBellProvider.onlineUsersCount} đang tu tập',
                          style: const TextStyle(
                            color: AppTheme.darkWood,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (incenseProvider.isBurning)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkWood.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              incenseProvider.remainingTimeFormatted,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            const Text(
                              'Đang nguyện cầu',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            height: panelHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!incenseProvider.isBurning) ...[
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppTheme.woodBrown,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: AppTheme.darkWood,
                      side: BorderSide(color: AppTheme.woodBrown.withValues(alpha: 0.35)),
                      minimumSize: const Size(0, 46),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 nén')),
                      ButtonSegment(value: 3, label: Text('3 nén')),
                      ButtonSegment(value: 5, label: Text('5 nén')),
                    ],
                    selected: {incenseProvider.stickCount},
                    onSelectionChanged: (s) {
                      incenseProvider.setStickCount(s.first);
                      _o3dController.cameraTarget(0, 0.75, 0);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editPetition(context, incenseProvider),
                          icon: const Icon(Icons.edit_note, color: AppTheme.woodBrown, size: 20),
                          label: Text(
                            incenseProvider.petition.isEmpty ? 'Lời nguyện' : incenseProvider.petition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.darkWood, fontSize: 13),
                          ),
                          style: _pillStyle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Consumer<PrayerProvider>(
                          builder: (context, prayer, _) => OutlinedButton.icon(
                            onPressed: () => showPrayerSheet(context),
                            icon: Icon(
                              prayer.selected == null ? Icons.menu_book_outlined : Icons.menu_book,
                              color: prayer.selected == null ? AppTheme.woodBrown : AppTheme.antiqueGold,
                              size: 20,
                            ),
                            label: Text(
                              prayer.selected?.title ?? 'Đọc kinh / khấn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.darkWood, fontSize: 13),
                            ),
                            style: _pillStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Thời gian thắp hương',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkWood.withValues(alpha: 0.6))),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final m in IncenseProvider.durations)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              showCheckmark: false,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(vertical: 6),
                              label: SizedBox(width: double.infinity, child: Text('$m phút', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                              selected: incenseProvider.selectedMinutes == m,
                              selectedColor: AppTheme.antiqueGold.withValues(alpha: 0.35),
                              onSelected: (_) => incenseProvider.setSelectedMinutes(m),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => incenseProvider.startBurning(incenseProvider.selectedMinutes),
                      icon: const AppIcon.incense(size: 22, color: AppTheme.gold),
                      label: Text('Thắp hương · ${incenseProvider.selectedMinutes} phút',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                  ),
                ] else ...[
                  if (incenseProvider.petition.isNotEmpty && context.read<PrayerProvider>().selected != null) ...[
                    Text(
                      '“${incenseProvider.petition}”',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.woodBrown),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Expanded(
                    child: Selector<PrayerProvider, bool>(
                      selector: (_, p) => p.selected != null,
                      builder: (_, hasPrayer, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: hasPrayer ? const PrayerReaderCard() : _PrayingCard(petition: incenseProvider.petition),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => incenseProvider.stopBurning(),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Dừng thắp hương'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
      }),
    );
  }

  static final ButtonStyle _pillStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    side: BorderSide(color: AppTheme.woodBrown.withValues(alpha: 0.3)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  );

  Future<void> _editPetition(BuildContext context, IncenseProvider provider) async {
    final controller = TextEditingController(text: provider.petition);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lời nguyện'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Con xin nguyện cầu cho...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Lưu')),
        ],
      ),
    );
    if (result != null) provider.setPetition(result);
    controller.dispose();
  }
}

class _PrayingCard extends StatelessWidget {
  final String petition;
  const _PrayingCard({required this.petition});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.darkWood, Color(0xFF2A1A16)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIcon.lotus(size: 38, color: AppTheme.antiqueGold),
          const SizedBox(height: 8),
          const Text('Đang nguyện cầu', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            petition.isEmpty ? 'Tĩnh tâm, hít thở sâu và hướng lòng về điều thiện lành.' : '“$petition”',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.45, fontStyle: petition.isEmpty ? FontStyle.normal : FontStyle.italic),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showPrayerSheet(context),
            icon: const Icon(Icons.menu_book_outlined, color: AppTheme.gold, size: 20),
            label: const Text('Chọn kinh để đọc', style: TextStyle(color: AppTheme.gold)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.antiqueGold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
          ),
        ],
      ),
    );
  }
}
