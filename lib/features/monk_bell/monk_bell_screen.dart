import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import 'monk_bell_provider.dart';
import '../../core/app_theme.dart';

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
              
              // Tap Counter
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.woodBrown.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Taps: ${provider.tapCount}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
