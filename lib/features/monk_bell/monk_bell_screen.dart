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
      backgroundColor: AppTheme.parchment,
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
              // 3D Model Area - INTERACTIVE
              Positioned.fill(
                child: GestureDetector(
                  onTap: () async {
                    provider.tap();
                    _controller.cameraTarget(0, 0.06, 0);
                    await Future.delayed(const Duration(milliseconds: 60));
                    _controller.cameraTarget(0, 0, 0);
                  },
                    child: O3D(
                    controller: _controller,
                    src: 'assets/models/mo.glb',
                    autoPlay: true,
                    autoRotate: true,
                    rotationPerSecond: '30deg',
                    cameraControls: false,
                    disableTap: true,
                    backgroundColor: Colors.transparent,
                    loading: Loading.eager,
                    environmentImage: 'neutral',
                  ),
                ),
              ),

              // Stats Overlay
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkWood.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${provider.tapCount}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gold,
                              ),
                            ),
                            const Text(
                              'Lượt gõ của bạn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge(
                            label: 'Toàn cầu: ${provider.globalTapCount}',
                            icon: Icons.public,
                          ),
                          const SizedBox(width: 10),
                          _buildBadge(
                            label: '${provider.onlineUsersCount} online',
                            icon: Icons.circle,
                            iconColor: Colors.greenAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Instruction
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.darkWood.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Chạm trực tiếp vào vật thể để gõ',
                      style: TextStyle(
                        color: AppTheme.darkWood,
                        fontWeight: FontWeight.bold,
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

  Widget _buildBadge({required String label, required IconData icon, Color iconColor = AppTheme.gold}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkWood,
            ),
          ),
        ],
      ),
    );
  }
}
