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

class _MonkBellScreenState extends State<MonkBellScreen> {
  final O3DController _controller = O3DController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monk Bell (Mõ)'),
        backgroundColor: AppTheme.darkWood,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
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
                  // Trigger a small animation if possible
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
                ),
              ),
              
              // Stats Overlay
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.woodBrown.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Taps: ${provider.tapCount}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Global: ${provider.globalTapCount}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            '${provider.onlineUsersCount} online',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Instructions
              const Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap the bell to pray',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkWood,
                      fontStyle: FontStyle.italic,
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
}
