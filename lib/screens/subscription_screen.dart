import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/global_state.dart';
import '../../models/vpn_node.dart';
import '../../utils/vpn_config.dart';

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

  Future<String> _loadTemplate() async {
    return await rootBundle.loadString('assets/xray-template.json');
  }

  Future<String> _generatePlistContent(String name, String configPath) async {
  final template = await rootBundle.loadString('assets/xray-template.plist');
  final bundleId = _bundleId;
  return template
      .replaceAll('<BUNDLE_ID>', bundleId)
      .replaceAll('<NAME>', name)
      .replaceAll('<CONFIG_PATH>', configPath);
  }

  Future<void> _generateConfig(String password) async {
    final nodeName = _nodeNameController.text.trim();
    final domain = _domainController.text.trim();
    final port = _portController.text.trim();
    final uuid = _uuidController.text.trim();

    if (nodeName.isEmpty || domain.isEmpty || port.isEmpty || uuid.isEmpty) {
      setState(() => _message = '所有字段均不能为空');
      return;
    }

    String template;
    try {
      template = await _loadTemplate();
    } catch (e) {
      setState(() => _message = '加载模板失败: $e');
      return;
    }

    String rawJson = template
        .replaceAll('<SERVER_DOMAIN>', domain)
        .replaceAll('<PORT>', port)
        .replaceAll('<UUID>', uuid);

    late String fixedJsonContent;
    try {
      final jsonObj = jsonDecode(rawJson);
      fixedJsonContent = JsonEncoder.withIndent('  ').convert(jsonObj);
    } catch (e) {
      setState(() => _message = '生成的配置文件无效: $e');
      return;
    }

    final configPath = '/opt/homebrew/etc/xray-vpn-${nodeName.toLowerCase()}.json';
    final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
    final plistPath = '$homeDir/Library/LaunchAgents/${_bundleId}.xray-node-${nodeName.toLowerCase()}.plist';
    final plistContent = _generatePlistContent(nodeName.toLowerCase(), configPath);

    try {
      final script = '''
        echo "$password" | sudo -S bash -c '
          echo "${fixedJsonContent.replaceAll(r'"', r'\"')}" > "$configPath"
          echo "$plistContent" > "$plistPath"
        '
      ''';

      final process = await Process.start('sh', ['-c', script], runInShell: true);
      final result = await process.exitCode;
      if (result == 0) {
        final node = VpnNode(
          name: nodeName,
          countryCode: '',
          configPath: configPath,
          plistName: nodeName.toLowerCase(),
          server: domain,
          port: int.tryParse(port) ?? 443,
          uuid: uuid,
        );
        VpnConfigManager.addNode(node);
        await VpnConfigManager.saveToFile();

        setState(() {
          _message = '✅ 配置已保存: $configPath\n✅ 服务项已生成: $plistPath';
        });
      } else {
        setState(() => _message = '生成配置失败，错误码: $result');
      }
    } catch (e) {
      setState(() => _message = '生成配置失败: $e');
    }
  }

  void _onCreateConfig() {
    final unlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!unlocked) {
      setState(() => _message = '🔒 请先点击右上角的解锁按钮。');
    } else if (password.isNotEmpty) {
      _generateConfig(password);
    } else {
      setState(() => _message = '⚠️ 无法获取 sudo 密码。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加 VPN 节点配置')),
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
