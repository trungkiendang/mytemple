import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sử dụng HapticFeedback có sẵn của Flutter
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class MonkBellProvider with ChangeNotifier {
  int _tapCount = 0;
  int get tapCount => _tapCount;
  
  int _globalTapCount = 0;
  int get globalTapCount => _globalTapCount;
  
  int _onlineUsersCount = 0;
  int get onlineUsersCount => _onlineUsersCount;
  
  final player = AudioPlayer();
  FirebaseFirestore? _firestore;

  MonkBellProvider() {
    _initFirebase();
  }

  void _initFirebase() {
    if (Firebase.apps.isNotEmpty) {
      _firestore = FirebaseFirestore.instance;
      _listenToGlobalStats();
    }
  }

  void _listenToGlobalStats() {
    if (_firestore == null) return;

    _firestore!.collection('stats').doc('global_stats').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        _globalTapCount = data?['total_taps'] ?? 0;
        _onlineUsersCount = data?['online_users'] ?? 1;
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Error stats: $e'));
  }

  void tap() async {
    _tapCount++;
    notifyListeners();
    
    // Play sound
    try {
      await player.play(AssetSource('audio/bell_sound.mp3'));
    } catch (_) {}

    // Haptic Feedback (Chạy tốt cả trên iOS/Android/Web nếu trình duyệt hỗ trợ)
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    _syncTap();
  }

  void _syncTap() {
    if (_firestore == null) return;

    _firestore!.collection('stats').doc('global_stats').update({
      'total_taps': FieldValue.increment(1)
    }).catchError((_) {});
    
    _firestore!.collection('users').doc('prototype_user').set({
      'displayName': 'Người dùng hữu duyên',
      'tapCount': FieldValue.increment(1),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {});
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
