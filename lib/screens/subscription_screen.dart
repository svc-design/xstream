import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于加载资产

class SubscriptionScreen extends StatefulWidget {
  final bool isUnlocked; // 接收全局解锁状态
  final String sudoPassword; // 接收全局 sudo 密码
  final Function(String password) onRequestUnlock; // 解锁时的回调

  SubscriptionScreen({
    required this.isUnlocked,
    required this.sudoPassword,
    required this.onRequestUnlock,
  });

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _domainController = TextEditingController();
  final _uuidController = TextEditingController();
  String _message = '';

  Future<String> _loadTemplate() async {
    // 从 assets 目录加载模板文件
    return await rootBundle.loadString('assets/xray-template.json');
  }

  Future<void> _generateConfig(String password) async {
    final domain = _domainController.text;
    final uuid = _uuidController.text;

    // 非空检查
    if (domain.isEmpty || uuid.isEmpty) {
      setState(() {
        _message = '域名和 UUID 不能为空';
      });
      return;
    }

    // 加载模板
    String template;
    try {
      template = await _loadTemplate();
    } catch (e) {
      setState(() {
        _message = '加载模板失败: $e';
      });
      return;
    }

    // 替换模板中的占位符
    String configContent = template
        .replaceAll('<SERVER_DOMAIN>', domain)
        .replaceAll('<UUID>', uuid);

    // 验证生成的配置是否为有效的 JSON 格式
    try {
      jsonDecode(configContent); // 尝试解析 JSON，确保其有效
    } catch (e) {
      setState(() {
        _message = '生成的配置文件无效: $e';
      });
      return;
    }

    // 使用 sudo 执行 shell 命令来创建文件
    try {
      final process = await Process.start('sh', ['-c', '''
        echo "$password" | sudo -S bash -c 'echo "$configContent" > /opt/homebrew/etc/xray-vpn.json'
      '''], runInShell: true);

      // 捕获输出结果
      final result = await process.exitCode;
      if (result == 0) {
        setState(() {
          _message = '配置文件生成成功: /opt/homebrew/etc/xray-vpn.json';
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
    // 检查是否已经解锁
    if (!widget.isUnlocked) {
      setState(() {
        _message = '请先使用右上角的解锁按钮。然后输入域名和 UUID，执行创建配置项。';
      });
    } else if (widget.sudoPassword.isNotEmpty) {
      // 使用解锁后的 sudo 密码生成配置文件
      _generateConfig(widget.sudoPassword);
    } else {
      setState(() {
        _message = '无法获取 sudo 密码。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Config'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                labelText: 'XTLS Server 域名',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _uuidController,
              decoration: InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onCreateConfig, // 点击时调用 _onCreateConfig
              child: Text('创建配置项'),
            ),
            SizedBox(height: 16),
            Text(
              _message,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}