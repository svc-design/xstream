import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const XStreamApp());
}

class XStreamApp extends StatelessWidget {
  const XStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XStream',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
