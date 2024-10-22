import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于加载资产

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _domainController = TextEditingController();
  final _uuidController = TextEditingController();
  String _message = '';

  Future<String> _loadTemplate() async {
    // 从 assets 目录加载模板文件
    return await rootBundle.loadString('assets/xray-template.json');
  }

  Future<void> _generateConfig(String password) async {
    final domain = _domainController.text;
    final uuid = _uuidController.text;

    // 加载模板
    String template;
    try {
      template = await _loadTemplate();
    } catch (e) {
      setState(() {
        _message = '加载模板失败: $e';
      });
      return;
    }

    // 替换模板中的占位符
    String configContent = template
        .replaceAll('<SERVER_DOMAIN>', domain)
        .replaceAll('<UUID>', uuid);

    // 将 JSON 数据写入文件
    try {
      final file = File('/opt/homebrew/etc/xray-vpn.json');
      await file.writeAsString(configContent);
      setState(() {
        _message = '配置文件生成成功: ${file.path}';
      });
    } catch (e) {
      setState(() {
        _message = '生成配置文件失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Config'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                labelText: 'XTLS Server 域名',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _uuidController,
              decoration: InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 显示提示信息或执行其他操作
                setState(() {
                  _message = '请先输入域名和 UUID，然后使用右上角的解锁按钮生成配置文件。';
                });
              },
              child: Text('提示信息'),
            ),
            SizedBox(height: 16),
            Text(
              _message,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}