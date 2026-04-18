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

class _IncenseScreenState extends State<IncenseScreen>
    with AutomaticKeepAliveClientMixin {
  final O3DController _o3dController = O3DController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final incenseProvider = Provider.of<IncenseProvider>(context);
    final monkBellProvider = Provider.of<MonkBellProvider>(context);

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
                // 3D Model Area - INTERACTIVE
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (!incenseProvider.isBurning) {
                        // Gợi ý người dùng chọn thời gian nếu chưa thắp
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn thời gian để thắp hương')),
                        );
                      }
                    },
                    child: O3D(
                      src: 'assets/models/incense_bowl.glb', // Sử dụng file local
                      controller: _o3dController,
                      autoPlay: true,
                      autoRotate: true,
                      cameraControls: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                
                // Online Badge overlay
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
