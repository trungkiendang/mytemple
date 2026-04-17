import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import 'incense_provider.dart';
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
      appBar: AppBar(
        title: const Text('Thắp Hương'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      '${monkBellProvider.onlineUsersCount} online',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                O3D(
                  src: 'assets/models/incense_bowl.glb',
                  controller: _o3dController,
                  autoPlay: true,
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: AppTheme.parchment,
                ),
                if (incenseProvider.isBurning)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              incenseProvider.remainingTimeFormatted,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text(
                              'Thời gian còn lại',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.darkWood,
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
            padding: const EdgeInsets.all(30.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!incenseProvider.isBurning) ...[
                  const Text(
                    'Chọn thời gian thắp hương',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationButton(context, 1, '1 phút'),
                      _buildDurationButton(context, 5, '5 phút'),
                      _buildDurationButton(context, 15, '15 phút'),
                    ],
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => incenseProvider.stopBurning(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Dừng thắp hương',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton(BuildContext context, int minutes, String label) {
    return ElevatedButton(
      onPressed: () {
        Provider.of<IncenseProvider>(context, listen: false)
            .startBurning(minutes);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}
