// Basic smoke test for Click2Fix app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:click2fix_mobile_app/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Click2FixApp()));
    // Just verify it renders without crashing
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
