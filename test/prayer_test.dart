import 'package:flutter_test/flutter_test.dart';
import 'package:temple_vibe/features/incense/prayer_provider.dart';

void main() {
  test('recording timing spreads the audio over lines by length', () {
    final lines = [PrayerLine('a' * 10), PrayerLine('b' * 30), PrayerLine('c' * 10)];
    final ends = lineEndsMs(lines, 5000);
    expect(ends, [1000, 4000, 5000]);
    expect(lineEndsMs([PrayerLine('x' * 20, fill: true), PrayerLine('y' * 40)], 800), [400, 800]);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled prayers are well-formed', () async {
    final prayers = await PrayerProvider.loadAsset();
    final books = (await PrayerProvider.loadBooks()).map((b) => b.id).toSet();
    expect(prayers.length, greaterThanOrEqualTo(20));
    final ids = prayers.map((p) => p.id).toSet();
    expect(ids.length, prayers.length, reason: 'ids must be unique');
    expect(ids, containsAll(['khan-mung-mot', 'khan-ram', 'khan-cau-may', 'tet-giao-thua', 'le-vu-lan', 'gia-nhap-trach']));
    for (final p in prayers) {
      expect(p.lines, isNotEmpty, reason: p.id);
      expect(p.lines.every((l) => l.text.trim().isNotEmpty), isTrue, reason: p.id);
      expect(books, contains(p.book), reason: '${p.id} must belong to a known book');
    }
  });

  test('personal fill-in lines are flagged so they are not spoken', () async {
    final ram = (await PrayerProvider.loadAsset()).firstWhere((p) => p.id == 'khan-ram');
    expect(ram.lines.where((l) => l.fill), isNotEmpty);
  });
}
