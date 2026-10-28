import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../features/incense/prayer_provider.dart';
import '../models/scripture.dart';
import 'firebase_status.dart';

class FirebaseService {
  FirebaseFirestore? _firestore;

  FirebaseService() {
    if (Firebase.apps.isNotEmpty) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  /// Scriptures from Firestore; when it is unreachable or denied, falls back to the
  /// copy bundled with the app (assets/data/scriptures.json) so the library always works.
  Future<List<Scripture>> fetchScriptures() async {
    if (_firestore != null) {
      try {
        final snapshot = await _firestore!.collection('scriptures').get();
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return Scripture(
            id: doc.id,
            title: data['title'] ?? 'Không tiêu đề',
            content: data['content'] ?? '',
            sect: data['sect'],
          );
        }).toList();
        if (list.isNotEmpty) return [...list, ...await _prayerScriptures()];
      } catch (e) {
        debugPrint('Error fetching scriptures, using bundled copy: $e');
        FirebaseStatus.issue.value ??= 'Không đọc được kinh từ máy chủ (kiểm tra Firestore Rules): dùng bản kèm theo ứng dụng.';
      }
    }
    return _bundledScriptures();
  }

  Future<List<Scripture>> _bundledScriptures() async {
    final raw = await rootBundle.loadString('assets/data/scriptures.json');
    final scriptures = (jsonDecode(raw) as List)
        .map((e) => Scripture(
              id: e['id'] as String,
              title: e['title'] as String,
              content: e['content'] as String,
              sect: e['sect'] as String?,
            ))
        .toList();
    return [...scriptures, ...await _prayerScriptures()];
  }

  /// Văn khấn (Mùng Một, Rằm, cầu bình an...) also appear in the library for reading.
  Future<List<Scripture>> _prayerScriptures() async {
    final prayers = await PrayerProvider.loadAsset();
    return [
      for (final p in prayers)
        Scripture(id: 'khan-${p.id}', title: p.title, content: p.fullText, sect: 'Văn khấn'),
    ];
  }
}
