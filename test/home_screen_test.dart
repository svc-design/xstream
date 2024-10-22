import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xstream/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows service status and launch button', (WidgetTester tester) async {
    // Build the HomeScreen widget.
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    // Verify that the service status is displayed.
    expect(find.text('服务状态'), findsOneWidget);
    expect(find.text('服务未运行'), findsOneWidget);
    
    // Verify that the launch button is displayed.
    expect(find.text('启动服务'), findsOneWidget);

    // Verify that the custom list tiles are displayed.
    expect(find.text('VLESS'), findsOneWidget);
    expect(find.text('VMess'), findsOneWidget);
    expect(find.text('Shadowsocks'), findsOneWidget);
    expect(find.text('Trojan'), findsOneWidget);
    expect(find.text('Socks'), findsOneWidget);
  });
}
