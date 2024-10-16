import 'package:flutter/material.dart';
import '../widgets/connection_form.dart';
import '../widgets/device_list.dart';
import '../widgets/service_status.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XStream - 连接 XTLS 服务器'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey.shade200,
              child: const ServiceStatus(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const ConnectionForm(), // 这里可以使用 const
                Expanded(child: const DeviceList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
