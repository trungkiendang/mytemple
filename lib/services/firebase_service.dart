import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/scripture.dart';

class FirebaseService {
  FirebaseFirestore? _firestore;

  FirebaseService() {
    if (Firebase.apps.isNotEmpty) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  Future<List<Scripture>> fetchScripturesFromFirebase() async {
    if (_firestore == null) {
      debugPrint('Firestore not available, returning mock data');
      return _getMockScriptures();
    }

    try {
      QuerySnapshot snapshot = await _firestore!.collection('scriptures').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Scripture(
          id: doc.id,
          title: data['title'] ?? 'Không tiêu đề',
          content: data['content'] ?? 'Không nội dung',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching scriptures: $e');
      return _getMockScriptures();
    }
  }

  List<Scripture> _getMockScriptures() {
    return [
      Scripture(
        id: 'mock-1',
        title: 'Chú Đại Bi (Đang kết nối...)',
        content: 'Nội dung sẽ được tải khi Firebase sẵn sàng...',
      ),
    ];
  }
}
