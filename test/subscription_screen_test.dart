import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xstream/screens/subscription_screen.dart';

void main() {
  testWidgets('SubscriptionScreen generates config file', (WidgetTester tester) async {
    // Build the SubscriptionScreen widget.
    await tester.pumpWidget(MaterialApp(home: SubscriptionScreen()));

    // Verify that the text fields and button are displayed.
    expect(find.byType(TextField), findsNWidgets(2)); // 2 text fields
    expect(find.text('生成配置文件'), findsOneWidget);

    // Enter text in the text fields.
    await tester.enterText(find.byType(TextField).at(0), 'example.com');
    await tester.enterText(find.byType(TextField).at(1), '123e4567-e89b-12d3-a456-426614174000');

    // Tap the generate button.
    await tester.tap(find.text('生成配置文件'));
    await tester.pumpAndSettle(); // Wait for any animations to finish.

    // Verify that a success message is displayed (you may want to adjust this to match your logic).
    expect(find.textContaining('配置文件生成成功'), findsOneWidget);
  });
}
