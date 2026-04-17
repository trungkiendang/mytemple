import 'package:flutter_test/flutter_test.dart';
import 'package:temple_vibe/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TempleVibeApp());

    // Verify that our splash screen text is present.
    expect(find.text('Temple Vibe'), findsOneWidget);
  });
}
