import 'package:flutter_test/flutter_test.dart';
import 'package:amar_path/main.dart';

void main() {
  testWidgets('Smart Road App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartRoadApp());
    expect(find.byType(SmartRoadApp), findsOneWidget);
  });
}
