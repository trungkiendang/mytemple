import 'package:flutter_test/flutter_test.dart';
import 'package:temple_vibe/features/incense/prayer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled prayers are well-formed', () async {
    final prayers = await PrayerProvider.loadAsset();
    expect(prayers.length, greaterThanOrEqualTo(6));
    final ids = prayers.map((p) => p.id).toSet();
    expect(ids.length, prayers.length, reason: 'ids must be unique');
    expect(ids, containsAll(['khan-mung-mot', 'khan-ram', 'khan-cau-may']));
    for (final p in prayers) {
      expect(p.lines, isNotEmpty, reason: p.id);
      expect(p.lines.every((l) => l.text.trim().isNotEmpty), isTrue, reason: p.id);
      expect(p.category, isNotEmpty, reason: p.id);
    }
  });

  test('personal fill-in lines are flagged so they are not spoken', () async {
    final ram = (await PrayerProvider.loadAsset()).firstWhere((p) => p.id == 'khan-ram');
    expect(ram.lines.where((l) => l.fill), isNotEmpty);
  });
}
