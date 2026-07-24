import 'package:flutter_test/flutter_test.dart';

import 'package:method_deferred/main.dart';

void main() {
  testWidgets('Shows the checking-clipboard state on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MethodApp());
    expect(find.text('Checking clipboard for a pending link…'), findsOneWidget);
  });
}
