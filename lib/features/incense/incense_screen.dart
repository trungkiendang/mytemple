import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';
import 'incense_provider.dart';

class IncenseScreen extends StatefulWidget {
  const IncenseScreen({super.key});

  @override
  State<IncenseScreen> createState() => _IncenseScreenState();
}

class _IncenseScreenState extends State<IncenseScreen> {
  final O3DController _o3dController = O3DController();

  @override
  Widget build(BuildContext context) {
    final incenseProvider = Provider.of<IncenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thắp hương'),
      ),
      body: Column(
        children: [
          Expanded(
            child: O3D(
              src: 'assets/models/incense_bowl.glb',
              controller: _o3dController,
              autoPlay: true,
              autoRotate: true,
              cameraControls: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (incenseProvider.isBurning)
                  Text(
                    incenseProvider.remainingTimeFormatted,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  )
                else
                  const Text(
                    'Chọn thời gian thắp hương',
                    style: TextStyle(fontSize: 18),
                  ),
                const SizedBox(height: 24),
                if (!incenseProvider.isBurning)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDurationButton(context, 1, '1 phút'),
                      _buildDurationButton(context, 5, '5 phút'),
                      _buildDurationButton(context, 15, '15 phút'),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () => incenseProvider.stopBurning(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Dừng thắp hương'),
                  ),
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
      child: Text(label),
    );
  }
}
