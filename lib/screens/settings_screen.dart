import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool isUnlocked; // 新参数，用于接收解锁状态
  final String sudoPassword; // 新参数，用于接收 sudo 密码

  SettingsScreen({Key? key, required this.isUnlocked, required this.sudoPassword}) : super(key: key); // 修改构造函数

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Settings Page'),
    );
  }
}