import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _domainController = TextEditingController();
  final _uuidController = TextEditingController();
  String _message = '';

  Future<void> _generateConfig() async {
    final domain = _domainController.text;
    final uuid = _uuidController.text;

    // JSON 数据结构
    final Map<String, dynamic> configData = {
      "outbounds": [
        {
          "protocol": "vless",
          "settings": {
            "vnext": [
              {
                "address": domain,
                "port": 443,
                "users": [
                  {
                    "id": uuid,
                    "alterId": 0,
                    "security": "none",
                  }
                ]
              }
            ]
          }
        }
      ],
      // 其他配置项可以在此添加
    };

    // 将 JSON 数据写入文件
    try {
      final file = File('/opt/homebrew/etc/xray-vpn.json');
      await file.writeAsString(json.encode(configData));
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
              onPressed: _generateConfig,
              child: Text('生成配置文件'),
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
