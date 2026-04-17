import 'package:flutter/foundation.dart';
import 'package:flutter_haptic/flutter_haptic.dart';
import 'package:audioplayers/audioplayers.dart';

class MonkBellProvider with ChangeNotifier {
  int _tapCount = 0;
  int get tapCount => _tapCount;
  final player = AudioPlayer();

  void tap() async {
    _tapCount++;
    notifyListeners();
    // Play sound and haptic
    try {
      await player.play(AssetSource('audio/bell_sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
    
    try {
      await FlutterHaptic.hapticTick();
    } catch (e) {
      debugPrint('Error triggering haptic: $e');
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
