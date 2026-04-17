import 'package:hive/hive.dart';

part 'scripture.g.dart';

@HiveType(typeId: 0)
class Scripture extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String content;
  @HiveField(3)
  final String? sect;

  Scripture({
    required this.id,
    required this.title,
    required this.content,
    this.sect,
  });
}
