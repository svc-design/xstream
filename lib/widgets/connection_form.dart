import 'package:flutter/material.dart';

class ConnectionForm extends StatelessWidget {
  const ConnectionForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('连接到 XTLS 服务器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: '服务器 ID',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // 点击连接按钮的逻辑
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }
}
