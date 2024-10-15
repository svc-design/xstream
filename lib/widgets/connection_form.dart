import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConnectionForm extends StatefulWidget {
  const ConnectionForm({super.key});

  @override
  _ConnectionFormState createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final TextEditingController _domainController = TextEditingController();
  String _message = '';

  Future<void> _fetchNodeConfig() async {
    final String domain = _domainController.text;
    if (domain.isEmpty) {
      setState(() {
        _message = '请输入有效的 XTLS 域名';
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://api.example.com/nodes?domain=$domain')); // 假设您的 API 是这样的
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 在这里处理获取到的节点配置数据
        setState(() {
          _message = '成功同步节点配置: ${data['nodes']}'; // 根据实际返回结构进行调整
        });
      } else {
        setState(() {
          _message = '无法获取节点配置: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _message = '请求失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('输入 XTLS 域名', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _domainController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'XTLS 域名',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _fetchNodeConfig,
            child: const Text('同步节点配置'),
          ),
          const SizedBox(height: 10),
          Text(_message, style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
