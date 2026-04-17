import 'package:hive/hive.dart';
part 'calendar_event.g.dart';

@HiveType(typeId: 1)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final bool isLunar;
  @HiveField(4)
  final bool reminderEnabled;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.isLunar = false,
    this.reminderEnabled = true,
  });
}
