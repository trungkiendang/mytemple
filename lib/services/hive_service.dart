import 'package:hive_flutter/hive_flutter.dart';
import '../models/scripture.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScriptureAdapter());
    await Hive.openBox<Scripture>('scriptures');
    await Hive.openBox('settings');
  }

  static Future<void> saveScripture(Scripture scripture) async {
    var box = Hive.box<Scripture>('scriptures');
    await box.put(scripture.id, scripture);
  }

  static Scripture? getScripture(String id) {
    var box = Hive.box<Scripture>('scriptures');
    return box.get(id);
  }

  static List<Scripture> getAllScriptures() {
    var box = Hive.box<Scripture>('scriptures');
    return box.values.toList();
  }
}
