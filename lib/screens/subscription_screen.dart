import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/vpn_node.dart';
import '../../utils/global_state.dart';
import '../../utils/global_keys.dart';
import '../../utils/vpn_config.dart';
import '../../widgets/log_console.dart';  // Ensure LogConsole import

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

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

  Future<String> _loadConfigTemplate() async {
    return await rootBundle.loadString('assets/xray-template.json');
  }

  Future<String> _loadPlistTemplate() async {
    return await rootBundle.loadString('assets/xray-template.plist');
  }

  Future<void> _generateContent(String password) async {
    final nodeName = _nodeNameController.text.trim();
    final domain = _domainController.text.trim();
    final port = _portController.text.trim();
    final uuid = _uuidController.text.trim();

    if (nodeName.isEmpty || domain.isEmpty || port.isEmpty || uuid.isEmpty) {
      setState(() => _message = '所有字段均不能为空');
      logConsoleKey.currentState?.addLog('所有字段均不能为空', level: LogLevel.error); // Log error
      return;
    }

    String configTemplate;
    try {
      configTemplate = await _loadConfigTemplate();
      logConsoleKey.currentState?.addLog('模板加载成功'); // Log success
    } catch (e) {
      setState(() => _message = '加载模板失败: $e');
      logConsoleKey.currentState?.addLog('加载模板失败: $e', level: LogLevel.error); // Log error
      return;
    }

    String rawJson = configTemplate
        .replaceAll('<SERVER_DOMAIN>', domain)
        .replaceAll('<PORT>', port)
        .replaceAll('<UUID>', uuid);

    late String fixedJsonContent;
    try {
      final jsonObj = jsonDecode(rawJson);
      fixedJsonContent = JsonEncoder.withIndent('  ').convert(jsonObj);
      logConsoleKey.currentState?.addLog('配置文件 JSON 生成成功'); // Log success
    } catch (e) {
      setState(() => _message = '生成的配置文件无效: $e');
      logConsoleKey.currentState?.addLog('生成的配置文件无效: $e', level: LogLevel.error); // Log error
      return;
    }

    // Generate paths
    final configPath = '/opt/homebrew/etc/xray-vpn-${nodeName.toLowerCase()}.json';
    final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
    final plistPath = '$homeDir/Library/LaunchAgents/${_bundleId}.xray-node-${nodeName.toLowerCase()}.plist';

    String plistTemplate;
    try {
      plistTemplate = await _loadPlistTemplate();
      logConsoleKey.currentState?.addLog('Plist 模板加载成功');
    } catch (e) {
      setState(() => _message = '加载 Plist 模板失败: $e');
      logConsoleKey.currentState?.addLog('加载 Plist 模板失败: $e', level: LogLevel.error);
      return;
    }

    final plistContent = plistTemplate
        .replaceAll('<BUNDLE_ID>', _bundleId)
        .replaceAll('<NAME>', nodeName.toLowerCase())
        .replaceAll('<CONFIG_PATH>', configPath);

    // Now communicate with AppDelegate to write files to system paths
    try {
      await platform.invokeMethod('writeConfigFiles', {
        'configPath': configPath,
        'configContent': fixedJsonContent,
        'plistPath': plistPath,
        'plistContent': plistContent,
        'password': password, // Pass password for sudo if needed
      });

      setState(() {
        _message = '✅ 配置已保存: $configPath\n✅ 服务项已生成: $plistPath';
        logConsoleKey.currentState?.addLog('配置已成功保存并生成', level: LogLevel.info); // Log success
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('配置文件生成成功：\n$configPath\n$plistPath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } on PlatformException catch (e) {
      setState(() => _message = '生成配置失败: $e');
      logConsoleKey.currentState?.addLog('生成配置失败: $e', level: LogLevel.error); // Log error
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
      _generateContent(password);
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
