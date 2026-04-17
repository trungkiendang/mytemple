import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scripture.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Scripture>> fetchScripturesFromFirebase() async {
    QuerySnapshot snapshot = await _firestore.collection('scriptures').get();
    return snapshot.docs.map((doc) => Scripture(
      id: doc.id,
      title: doc['title'],
      content: doc['content'],
    )).toList();
  }
}
