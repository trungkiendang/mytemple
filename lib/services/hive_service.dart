import 'package:hive_flutter/hive_flutter.dart';
import '../models/scripture.dart';
import '../models/calendar_event.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScriptureAdapter());
    Hive.registerAdapter(CalendarEventAdapter());
    await Hive.openBox<Scripture>('scriptures');
    await Hive.openBox<CalendarEvent>('events');
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

  static Future<void> saveEvent(CalendarEvent event) async {
    var box = Hive.box<CalendarEvent>('events');
    await box.put(event.id, event);
  }

  static Future<void> deleteEvent(String id) async {
    var box = Hive.box<CalendarEvent>('events');
    await box.delete(id);
  }

  static List<CalendarEvent> getAllEvents() {
    var box = Hive.box<CalendarEvent>('events');
    return box.values.toList();
  }
}
