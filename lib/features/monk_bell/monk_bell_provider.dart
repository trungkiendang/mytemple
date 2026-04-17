import 'package:flutter/foundation.dart';
import 'package:flutter_haptic/flutter_haptic.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonkBellProvider with ChangeNotifier {
  int _tapCount = 0;
  int get tapCount => _tapCount;
  
  int _globalTapCount = 0;
  int get globalTapCount => _globalTapCount;
  
  int _onlineUsersCount = 0;
  int get onlineUsersCount => _onlineUsersCount;
  
  final player = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MonkBellProvider() {
    _listenToGlobalStats();
  }

  void _listenToGlobalStats() {
    // Listen to global taps
    _firestore.collection('stats').doc('global_taps').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _globalTapCount = snapshot.data()?['count'] ?? 0;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error listening to global taps: $e');
      // Mock data for prototype if Firebase is not fully setup
      _globalTapCount = 12345;
      notifyListeners();
    });

    // Listen to online users
    _firestore.collection('stats').doc('online_users').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _onlineUsersCount = snapshot.data()?['count'] ?? 0;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error listening to online users: $e');
      // Mock data for prototype
      _onlineUsersCount = 42;
      notifyListeners();
    });
  }

  void tap() async {
    _tapCount++;
    _globalTapCount++;
    notifyListeners();
    
    // Sync with Firestore
    _syncTapWithFirestore();

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

  void _syncTapWithFirestore() {
    _firestore.collection('stats').doc('global_taps').set({
      'count': FieldValue.increment(1),
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint('Error syncing tap with Firestore: $e');
    });
    
    // Also update user's personal tap count for leaderboard
    // For prototype, we'll use a hardcoded user ID or skip if not authenticated
    _firestore.collection('users').doc('prototype_user').set({
      'displayName': 'Prototype User',
      'tapCount': FieldValue.increment(1),
      'lastTap': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint('Error updating user tap count: $e');
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
