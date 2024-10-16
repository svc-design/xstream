import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class ConnectionForm extends StatefulWidget {
  const ConnectionForm({Key? key}) : super(key: key);

  @override
  _ConnectionFormState createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _uuidController = TextEditingController();

  Future<void> _generateConfigFile() async {
    // 获取用户输入
    String serverDomain = _serverController.text.trim();
    String uuid = _uuidController.text.trim();

    if (serverDomain.isEmpty || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的 XTLS Server 域名和 UUID')),
      );
      return;
    }

    try {
      // 读取 assets/xray-template.json 文件
      String templateContent = await rootBundle.loadString('assets/xray-template.json');

      // 替换模板中的占位符
      String updatedContent = templateContent
          .replaceAll('<SERVER_DOMAIN>', serverDomain)
          .replaceAll('<UUID>', uuid);

      // 定义最终的文件路径
      String outputPath = '/opt/homebrew/etc/xray-vpn.json';

      // 写入最终的配置文件
      final file = File(outputPath);
      await file.writeAsString(updatedContent);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('配置文件已成功生成: $outputPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成配置文件时出错: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'XTLS Server 域名',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入有效的 XTLS Server 域名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _uuidController,
              decoration: const InputDecoration(
                labelText: 'XTLS UUID',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入有效的 XTLS UUID';
                }
                return null;
              },
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _generateConfigFile,
              child: const Text('生成配置文件'),
            ),
          ],
        ),
      ),
    );
  }
}
