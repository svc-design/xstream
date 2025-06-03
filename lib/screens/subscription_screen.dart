import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/global_config.dart';
import '../../widgets/log_console.dart';
import '../../services/vpn_config_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _nodeNameController = TextEditingController();
  final _domainController = TextEditingController();
  final _portController = TextEditingController(text: '443');
  final _uuidController = TextEditingController();
  String _message = '';
  String _bundleId = 'com.xstream'; // default fallback
  static const platform = MethodChannel('com.xstream/native');

  @override
  void initState() {
    super.initState();
    _loadBundleId();
  }

  Future<void> _loadBundleId() async {
    try {
      final config = await rootBundle.loadString('macos/Runner/Configs/AppInfo.xcconfig');
      for (final line in config.split('\n')) {
        if (line.trim().startsWith('PRODUCT_BUNDLE_IDENTIFIER')) {
          setState(() {
            _bundleId = line.split('=').last.trim();
          });
          break;
        }
      }
    } catch (_) {
      // silently fallback
    }
  }

  void _onCreateConfig() {
    final unlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!unlocked) {
      setState(() {
        _message = '🔒 请先点击右上角的解锁按钮。';
      });
      logConsoleKey.currentState?.addLog('请先解锁后再创建配置', level: LogLevel.warning); // Log warning
    } else if (password.isNotEmpty) {
      // Call VpnConfigService to generate content
      VpnConfig.generateContent(
        nodeName: _nodeNameController.text.trim(),
        domain: _domainController.text.trim(),
        port: _portController.text.trim(),
        uuid: _uuidController.text.trim(),
        password: password,
        bundleId: _bundleId,
        platform: platform,
        setMessage: (msg) {
          setState(() {
            _message = msg;
          });
        },
        logMessage: (msg) {
          logConsoleKey.currentState?.addLog(msg);
        },
      );
    } else {
      setState(() {
        _message = '⚠️ 无法获取 sudo 密码。';
      });
      logConsoleKey.currentState?.addLog('无法获取 sudo 密码', level: LogLevel.error); // Log error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加 VPN 节点配置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nodeNameController,
              decoration: const InputDecoration(labelText: '节点名（如 US-VPN）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(labelText: '服务器域名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: '端口号'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uuidController,
              decoration: const InputDecoration(labelText: 'UUID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onCreateConfig,
              child: const Text('生成配置并保存'),
            ),
            const SizedBox(height: 16),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
