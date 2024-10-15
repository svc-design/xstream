import 'package:flutter/material.dart';

class ServiceStatus extends StatelessWidget {
  const ServiceStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('服务状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('ID: 512 765 950', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        const Text('一次性密码:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          height: 40,
          color: Colors.grey.shade300,
          child: Center(child: Text('-', style: TextStyle(fontSize: 16))),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('服务未运行', style: TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () {
                // 点击启动服务的逻辑
              },
              child: const Text('启动服务'),
            ),
          ],
        ),
      ],
    );
  }
}
