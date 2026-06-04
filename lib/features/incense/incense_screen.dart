import 'dart:math';

import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import 'incense_provider.dart';
import '../monk_bell/monk_bell_provider.dart';
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
        ..color = Colors.white.withOpacity(opacity * 0.3)
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
    const baseY = 0.38;
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
      body: Column(
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
                      src: incenseProvider.modelSrc,
                      controller: _o3dController,
                      autoPlay: true,
                      autoRotate: true,
                      cameraControls: true,
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

                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 8),
                        Text(
                          '${monkBellProvider.onlineUsersCount} online',
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
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.darkWood.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
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
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            const Text(
                              'Đang thắp hương nguyện cầu...',
                              style: TextStyle(
                                fontSize: 12,
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
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!incenseProvider.isBurning) ...[
                  const Text(
                    'Số que hương',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStickBtn(context, 1, '1'),
                      const SizedBox(width: 16),
                      _buildStickBtn(context, 3, '3'),
                      const SizedBox(width: 16),
                      _buildStickBtn(context, 5, '5'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Thời gian thắp hương',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationBtn(context, 1, '1 Phút'),
                      _buildDurationBtn(context, 5, '5 Phút'),
                      _buildDurationBtn(context, 15, '15 Phút'),
                    ],
                  ),
                ] else
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickBtn(BuildContext context, int count, String label) {
    final provider = Provider.of<IncenseProvider>(context, listen: false);
    final isSelected = provider.stickCount == count;
    return GestureDetector(
      onTap: () {
        provider.setStickCount(count);
        _o3dController.cameraTarget(0, 0, 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.woodBrown : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.darkWood : AppTheme.woodBrown.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.darkWood.withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Text(
          '$label Que',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isSelected ? Colors.white : AppTheme.darkWood,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationBtn(BuildContext context, int min, String label) {
    return InkWell(
      onTap: () => Provider.of<IncenseProvider>(context, listen: false).startBurning(min),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.woodBrown.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.woodBrown.withOpacity(0.2)),
            ),
            child: const Icon(Icons.timer_outlined, color: AppTheme.woodBrown),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
