import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
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
                  // 左侧的状态信息和启动按钮
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '服务状态',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('服务地址: http:// 或 Socks5://127.0.0.1:1080'),
                          SizedBox(height: 8),
                          Text('网络延迟: '),
                          SizedBox(height: 8),
                          Text('网络丢包: '),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '服务未运行',
                                style: TextStyle(color: Colors.red),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // 启动服务的逻辑
                                },
                                child: Text('启动服务'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 右侧的配置列表
                  Expanded(
                    flex: 2,
                    child: ListView(
                      children: [
                        CustomListTile(title: 'VLESS', subtitle: 'tcp | none'),
                        CustomListTile(title: 'VMess', subtitle: 'tcp | none'),
                        CustomListTile(title: 'Shadowsocks', subtitle: 'tcp | none'),
                        CustomListTile(title: 'Trojan', subtitle: 'tcp | tls'),
                        CustomListTile(title: 'Socks', subtitle: 'tcp | none'),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  // 仅显示配置项目，在每行的按钮上显示状态信息
                  CustomListTile(
                    title: 'VLESS',
                    subtitle: 'tcp | none',
                    status: '服务未运行', // 可根据具体状态动态显示
                  ),
                  CustomListTile(
                    title: 'VMess',
                    subtitle: 'tcp | none',
                    status: '服务未运行',
                  ),
                  CustomListTile(
                    title: 'Shadowsocks',
                    subtitle: 'tcp | none',
                    status: '服务未运行',
                  ),
                  CustomListTile(
                    title: 'Trojan',
                    subtitle: 'tcp | tls',
                    status: '服务未运行',
                  ),
                  CustomListTile(
                    title: 'Socks',
                    subtitle: 'tcp | none',
                    status: '服务未运行',
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
              style: TextStyle(color: status == '服务运行' ? Colors.green : Colors.red),
            )
          : null,
      onTap: () {
        // 点击事件逻辑，例如显示详细信息或启动服务
      },
    );
  }
}
