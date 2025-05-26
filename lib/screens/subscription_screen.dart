import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/global_state.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _domainController = TextEditingController();
  final _uuidController = TextEditingController();
  String _message = '';

  Future<String> _loadTemplate() async {
    return await rootBundle.loadString('assets/xray-template.json');
  }

  Future<void> _generateConfig(String password) async {
    final domain = _domainController.text;
    final uuid = _uuidController.text;

    if (domain.isEmpty || uuid.isEmpty) {
      setState(() {
        _message = '域名和 UUID 不能为空';
      });
      return;
    }

    String template;
    try {
      template = await _loadTemplate();
    } catch (e) {
      setState(() {
        _message = '加载模板失败: $e';
      });
      return;
    }

    String configContent = template
        .replaceAll('<SERVER_DOMAIN>', domain)
        .replaceAll('<UUID>', uuid);

    try {
      jsonDecode(configContent);
    } catch (e) {
      setState(() {
        _message = '生成的配置文件无效: $e';
      });
      return;
    }

    try {
      final process = await Process.start('sh', ['-c', '''
        echo "$password" | sudo -S bash -c 'echo "$configContent" > /opt/homebrew/etc/xray-vpn.json'
      '''], runInShell: true);

      final result = await process.exitCode;
      if (result == 0) {
        setState(() {
          _message = '✅ 配置文件生成成功: /opt/homebrew/etc/xray-vpn.json';
        });
      } else {
        setState(() {
          _message = '生成配置文件失败，错误码: $result';
        });
      }
    } catch (e) {
      setState(() {
        _message = '生成配置文件失败: $e';
      });
    }
  }

  void _onCreateConfig() {
    final unlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!unlocked) {
      setState(() {
        _message = '🔒 请先点击右上角的解锁按钮。';
      });
    } else if (password.isNotEmpty) {
      _generateConfig(password);
    } else {
      setState(() {
        _message = '⚠️ 无法获取 sudo 密码。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Config'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'XTLS Server 域名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uuidController,
              decoration: const InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onCreateConfig,
              child: const Text('创建配置项'),
            ),
            const SizedBox(height: 16),
            Text(
              _message,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
