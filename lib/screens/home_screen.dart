import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final bool isUnlocked; // 新参数，用于接收解锁状态
  final String sudoPassword; // 新参数，用于接收 sudo 密码

  HomeScreen({Key? key, required this.isUnlocked, required this.sudoPassword}) : super(key: key); // 修改构造函数

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 检测屏幕宽度和平台
        bool isLargeScreen = constraints.maxWidth > 600;
        bool isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.fuchsia;

        return isLargeScreen && isDesktop
            ? Row(
                children: [
                  // 左侧：状态信息和启动按钮
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Status',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Service Address: http:// or Socks5://127.0.0.1:1080'),
                          SizedBox(height: 8),
                          Text('Network Latency: '),
                          SizedBox(height: 8),
                          Text('Packet Loss: '),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isUnlocked ? 'Service running' : 'Service not running',
                                style: TextStyle(color: isUnlocked ? Colors.green : Colors.red),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // 启动服务的逻辑
                                },
                                child: Text('Start Service'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 右侧：配置列表
                  Expanded(
                    flex: 2,
                    child: ListView(
                      children: [
                        CustomListTile(title: 'VLESS', subtitle: 'tcp | none', status: isUnlocked ? 'Service running' : 'Service not running'),
                        CustomListTile(title: 'VMess', subtitle: 'tcp | none', status: isUnlocked ? 'Service running' : 'Service not running'),
                        CustomListTile(title: 'Shadowsocks', subtitle: 'tcp | none', status: isUnlocked ? 'Service running' : 'Service not running'),
                        CustomListTile(title: 'Trojan', subtitle: 'tcp | tls', status: isUnlocked ? 'Service running' : 'Service not running'),
                        CustomListTile(title: 'Socks', subtitle: 'tcp | none', status: isUnlocked ? 'Service running' : 'Service not running'),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  // 仅在手机屏幕上显示配置项
                  CustomListTile(
                    title: 'VLESS',
                    subtitle: 'tcp | none',
                    status: isUnlocked ? 'Service running' : 'Service not running',
                  ),
                  CustomListTile(
                    title: 'VMess',
                    subtitle: 'tcp | none',
                    status: isUnlocked ? 'Service running' : 'Service not running',
                  ),
                  CustomListTile(
                    title: 'Shadowsocks',
                    subtitle: 'tcp | none',
                    status: isUnlocked ? 'Service running' : 'Service not running',
                  ),
                  CustomListTile(
                    title: 'Trojan',
                    subtitle: 'tcp | tls',
                    status: isUnlocked ? 'Service running' : 'Service not running',
                  ),
                  CustomListTile(
                    title: 'Socks',
                    subtitle: 'tcp | none',
                    status: isUnlocked ? 'Service running' : 'Service not running',
                  ),
                ],
              );
      },
    );
  }
}

class CustomListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? status;

  const CustomListTile({
    Key? key,
    required this.title,
    required this.subtitle,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: status != null
          ? Text(
              status!,
              style: TextStyle(color: status == 'Service running' ? Colors.green : Colors.red),
            )
          : null,
      onTap: () {
        // 处理点击事件的逻辑，例如启动服务
      },
    );
  }
}