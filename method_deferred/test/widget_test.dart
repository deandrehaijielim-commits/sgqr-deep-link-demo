import 'package:flutter_test/flutter_test.dart';

import 'package:method_deferred/main.dart';

void main() {
  testWidgets('Shows the app name on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MethodApp());
    await tester.pump();
    expect(find.text('Bank 5'), findsOneWidget);
  });
}
