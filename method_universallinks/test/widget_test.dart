import 'package:flutter_test/flutter_test.dart';

import 'package:method_universallinks/main.dart';

void main() {
  testWidgets('Shows the waiting state before any link arrives', (WidgetTester tester) async {
    await tester.pumpWidget(const MethodApp());
    expect(find.text('Waiting for a link…'), findsOneWidget);
  });
}
