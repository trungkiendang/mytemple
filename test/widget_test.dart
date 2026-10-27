import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:temple_vibe/main.dart';
import 'package:temple_vibe/models/calendar_event.dart';
import 'package:temple_vibe/models/scripture.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN', null);
    Hive.init(Directory.systemTemp.createTempSync('hive_test').path);
    Hive.registerAdapter(ScriptureAdapter());
    Hive.registerAdapter(CalendarEventAdapter());
    await Hive.openBox<Scripture>('scriptures');
    await Hive.openBox<CalendarEvent>('events');
    await Hive.openBox('settings');
  });

  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MyApp), findsOneWidget);
  });
}
