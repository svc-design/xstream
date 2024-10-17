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
        const Text('服务地址: http:// Or Socks5://127.0.0.1:1080', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        const Text('网络延迟:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        const Text('网络丢包:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
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
