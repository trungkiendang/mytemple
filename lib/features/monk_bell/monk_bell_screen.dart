import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import 'monk_bell_provider.dart';
import '../../core/app_theme.dart';
import '../community/leaderboard_screen.dart';

class MonkBellScreen extends StatefulWidget {
  const MonkBellScreen({super.key});

  @override
  State<MonkBellScreen> createState() => _MonkBellScreenState();
}

class _MonkBellScreenState extends State<MonkBellScreen>
    with AutomaticKeepAliveClientMixin {
  final O3DController _controller = O3DController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gõ Mõ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<MonkBellProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // 3D Model
              GestureDetector(
                onTap: () {
                  provider.tap();
                  // Trigger a small animation
                  _controller.cameraTarget(0, 0.1, 0);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _controller.cameraTarget(0, 0, 0);
                  });
                },
                child: O3D(
                  controller: _controller,
                  src: 'assets/models/mo.glb',
                  autoPlay: true,
                  autoRotate: false,
                  cameraControls: true,
                  backgroundColor: AppTheme.parchment,
                ),
              ),

              // Stats Overlay
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * -20),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.woodBrown.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${provider.tapCount}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Lượt gõ của bạn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSmallBadge(
                            icon: Icons.public,
                            label: 'Toàn cầu: ${provider.globalTapCount}',
                            color: AppTheme.forestGreen,
                          ),
                          const SizedBox(width: 8),
                          _buildSmallBadge(
                            icon: Icons.circle,
                            label: '${provider.onlineUsersCount} online',
                            color: Colors.green,
                            showDot: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Instructions
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Chạm vào mõ để tích công đức',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.darkWood,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmallBadge({
    required IconData icon,
    required String label,
    required Color color,
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            showDot ? Icons.circle : icon,
            color: color,
            size: showDot ? 8 : 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.darkWood.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
