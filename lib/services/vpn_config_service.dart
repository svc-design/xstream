// lib/services/vpn_config_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../utils/global_config.dart';  // 引入 global_application_config.dart

class VpnConfigService {
  static Future<void> generateContent({
    required String nodeName,
    required String domain,
    required String port,
    required String uuid,
    required String password,
    required String bundleId,
    required MethodChannel platform,
    required Function(String) setMessage,
    required Function(String) logMessage,
  }) async {
    if (nodeName.isEmpty || domain.isEmpty || port.isEmpty || uuid.isEmpty) {
      setMessage('所有字段均不能为空');
      logMessage('所有字段均不能为空');
      return;
    }

    String configTemplate;
    try {
      configTemplate = await rootBundle.loadString('assets/xray-template.json');
      logMessage('模板加载成功');
    } catch (e) {
      setMessage('加载模板失败: $e');
      logMessage('加载模板失败: $e');
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
      logMessage('配置文件 JSON 生成成功');
    } catch (e) {
      setMessage('生成的配置文件无效: $e');
      logMessage('生成的配置文件无效: $e');
      return;
    }

    // Generate paths dynamically
    final configPath = await GlobalApplicationConfig.getLocalConfigPath(); // 获取 configPath
    final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
    final plistPath = '$homeDir/Library/LaunchAgents/$bundleId.xray-node-${nodeName.toLowerCase()}.plist';

    String plistTemplate;
    try {
      plistTemplate = await rootBundle.loadString('assets/xray-template.plist');
      logMessage('Plist 模板加载成功');
    } catch (e) {
      setMessage('加载 Plist 模板失败: $e');
      logMessage('加载 Plist 模板失败: $e');
      return;
    }

    final plistContent = plistTemplate
        .replaceAll('<BUNDLE_ID>', bundleId)
        .replaceAll('<NAME>', nodeName.toLowerCase())
        .replaceAll('<CONFIG_PATH>', configPath);

    // Log the vpn_nodes.json path before update
    logMessage('即将更新 vpn_nodes.json: $configPath');

    // Now communicate with AppDelegate to write files to system paths
    try {
      await platform.invokeMethod('writeConfigFiles', {
        'configPath': configPath,
        'configContent': fixedJsonContent,
        'plistPath': plistPath,
        'plistContent': plistContent,
        'nodeName': nodeName,
        'countryCode': nodeName.substring(0, 2),
        'password': password,
        'vpnNodesJsonPath': configPath,  // Using configPath as vpnNodesJsonPath
      });

      // Log success message
      setMessage('✅ 配置已保存: $configPath\n✅ 服务项已生成: $plistPath');
      logMessage('配置已成功保存并生成');
    } on PlatformException catch (e) {
      setMessage('生成配置失败: $e');
      logMessage('生成配置失败: $e');
    }
  }
}
