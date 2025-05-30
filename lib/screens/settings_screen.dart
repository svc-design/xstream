import 'package:flutter/material.dart';
import '../../utils/global_state.dart';
import '../../utils/native_bridge.dart';
import '../../utils/global_keys.dart'; // ✅ 引入全局 logConsoleKey
import '../widgets/log_console.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'log';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧菜单栏
        Container(
          width: 220,
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '⚙️ 设置中心',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: GlobalState.isUnlocked,
                  builder: (context, isUnlocked, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: const Text('初始化 Xray'),
                          onPressed: isUnlocked
                              ? () async {
                                  logConsoleKey.currentState?.addLog('开始初始化 Xray...');
                                  try {
                                    final output = await NativeBridge.initXray();
                                    logConsoleKey.currentState?.addLog(output);
                                  } catch (e) {
                                    logConsoleKey.currentState?.addLog('[错误] $e', level: LogLevel.error);
                                  }
                                }
                              : null,
                        ),
                        if (!isUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '请先解锁以执行初始化操作',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('📜 查看日志'),
                selected: _selectedTab == 'log',
                onTap: () {
                  setState(() {
                    _selectedTab = 'log';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('关于'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'XStream',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text('由 XStream 驱动的多节点代理 UI'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧日志输出面板
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _selectedTab == 'log'
                ? LogConsole(key: logConsoleKey) // ✅ 使用全局 logConsoleKey
                : const Center(child: Text('请选择左侧菜单')),
          ),
        ),
      ],
    );
  }
}

