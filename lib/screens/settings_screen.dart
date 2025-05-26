// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../../utils/log_store.dart';
import '../../utils/global_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'home';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧菜单
        Container(
          width: 200,
          color: Colors.grey[100],
          child: ListView(
            children: [
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
              const Divider(),
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
        // 主内容区域
        Expanded(
          child: _selectedTab == 'log'
              ? const _LiveLogViewer()
              : _buildSettingsCenter(context),
        ),
      ],
    );
  }

  Widget _buildSettingsCenter(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalState.isUnlocked,
      builder: (context, isUnlocked, _) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '⚙️ 设置中心',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                isUnlocked ? '🔓 当前已解锁' : '🔒 当前未解锁',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveLogViewer extends StatefulWidget {
  const _LiveLogViewer({Key? key}) : super(key: key);

  @override
  State<_LiveLogViewer> createState() => _LiveLogViewerState();
}

class _LiveLogViewerState extends State<_LiveLogViewer> {
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs = LogStore.getAll().map((e) => e.formatted).toList();

    _startPolling();
  }

  void _startPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      final current = LogStore.getAll().map((e) => e.formatted).toList();
      if (current.length != _logs.length) {
        setState(() {
          _logs = current;
        });
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('📡 实时日志', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Text(
                  log,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
