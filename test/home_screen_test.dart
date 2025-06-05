import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xstream/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows placeholder when no VPN nodes',
      (WidgetTester tester) async {
    // Build the HomeScreen widget.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Wait for async initialization to finish.
    await tester.pumpAndSettle();

    // Verify that a placeholder message is displayed when there are no nodes.
    expect(find.text('暂无 VPN 节点，请先添加。'), findsOneWidget);
  });
}
