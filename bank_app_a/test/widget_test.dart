import 'package:flutter_test/flutter_test.dart';

import 'package:bank_app_a/main.dart';

void main() {
  testWidgets('Home screen shows the bank name and balance',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BankApp());
    await tester.pumpAndSettle();

    expect(find.text('Bank A'), findsWidgets);
    expect(find.textContaining('Available balance'), findsOneWidget);
  });
}
