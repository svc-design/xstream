import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xstream/screens/subscription_screen.dart';

void main() {
  testWidgets('SubscriptionScreen validates required fields', (WidgetTester tester) async {
    // Build the SubscriptionScreen widget.
    await tester.pumpWidget(const MaterialApp(home: SubscriptionScreen()));

    // Wait for async initialization to finish.
    await tester.pumpAndSettle();

    // Verify that the text fields and button are displayed.
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('生成配置并保存'), findsOneWidget);

    // Tap the generate button without entering any text.
    await tester.tap(find.text('生成配置并保存'));
    await tester.pumpAndSettle();

    // Verify that a warning message is shown.
    expect(find.textContaining('请填写所有必填项'), findsOneWidget);
  });
}
