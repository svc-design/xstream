// lib/services/vpn_config_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/global_config.dart';
import '../templates/xray_config_template.dart';
import '../templates/xray_plist_template.dart';
import '../templates/xray_service_template.dart';

class VpnNode {
  String name;
  String countryCode;
  String configPath;
  String plistName;
  bool enabled;

  VpnNode({
    required this.name,
    required this.countryCode,
    required this.configPath,
    required this.plistName,
    this.enabled = true,
  });

  factory VpnNode.fromJson(Map<String, dynamic> json) {
    return VpnNode(
      name: json['name'],
      countryCode: json['countryCode'],
      configPath: json['configPath'],
      plistName: json['plistName'],
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'countryCode': countryCode,
      'configPath': configPath,
      'plistName': plistName,
      'enabled': enabled,
    };
  }
}

class VpnConfig {
  static List<VpnNode> _nodes = [];

  static Future<String> getConfigPath() async {
    return await GlobalApplicationConfig.getLocalConfigPath();
  }

  static Future<void> load() async {
    List<VpnNode> fromLocal = [];

    try {
      final path = await GlobalApplicationConfig.getLocalConfigPath();
      final file = File(path);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonStr);
        fromLocal = jsonList.map((e) => VpnNode.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load local vpn_nodes.json: $e');
    }

    _nodes = fromLocal;
  }

  static List<VpnNode> get nodes => _nodes;

  static VpnNode? getNodeByName(String name) {
    try {
      return _nodes.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  static void addNode(VpnNode node) {
    _nodes.add(node);
  }

  static void removeNode(String name) {
    _nodes.removeWhere((e) => e.name == name);
  }

  static void updateNode(VpnNode updated) {
    final index = _nodes.indexWhere((e) => e.name == updated.name);
    if (index != -1) {
      _nodes[index] = updated;
    }
  }

  static String exportToJson() {
    return json.encode(_nodes.map((e) => e.toJson()).toList());
  }

  static Future<String> saveToFile() async {
    final path = await GlobalApplicationConfig.getLocalConfigPath();
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(exportToJson());
    return path;
  }

  static Future<void> importFromJson(String jsonStr) async {
    final List<dynamic> jsonList = json.decode(jsonStr);
    _nodes = jsonList.map((e) => VpnNode.fromJson(e)).toList();
    await saveToFile();
  }

  static Future<void> deleteNodeFiles(VpnNode node) async {
    try {
      final jsonFile = File(node.configPath);
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
      final plistPath = '$homeDir/Library/LaunchAgents/${node.plistName}';
      final plistFile = File(plistPath);
      if (await plistFile.exists()) {
        await plistFile.delete();
      }

      removeNode(node.name);
      await saveToFile();
    } catch (e) {
      debugPrint('⚠️ 删除节点文件失败: $e');
    }
  }

  static Future<void> generateDefaultNodes({
    required String password,
    required MethodChannel platform,
    required Function(String) setMessage,
    required Function(String) logMessage,
  }) async {
    final bundleId = await GlobalApplicationConfig.getBundleId();

    const port = '1443';
    const uuid = '18d270a9-533d-4b13-b3f1-e7f55540a9b2';
    const nodes = [
      {'name': 'US-VPN', 'domain': 'us-connector.onwalk.net'},
      {'name': 'CA-VPN', 'domain': 'ca-connector.onwalk.net'},
      {'name': 'JP-VPN', 'domain': 'tky-connector.onwalk.net'},
    ];

    for (final node in nodes) {
      await generateContent(
        nodeName: node['name']!,
        domain: node['domain']!,
        port: port,
        uuid: uuid,
        password: password,
        bundleId: bundleId,
        platform: platform,
        setMessage: setMessage,
        logMessage: logMessage,
      );
    }
  }

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
    final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
    final code = nodeName.split('-').first.toLowerCase();
    final xrayConfigPath = '/opt/homebrew/etc/xray-vpn-node-$code.json';

    final xrayConfigContent = await _generateXrayJsonConfig(domain, port, uuid, setMessage, logMessage);
    if (xrayConfigContent.isEmpty) return;

    final plistName = '$bundleId.xray-node-$code.plist';
    final plistPath = '$homeDir/Library/LaunchAgents/$plistName';

    final plistContent = _generatePlistFile(code, bundleId, xrayConfigPath);
    if (plistContent.isEmpty) return;

    final vpnNodesConfigPath = await GlobalApplicationConfig.getLocalConfigPath();
    final vpnNodesConfigContent = await _generateVpnNodesJsonContent(
      nodeName,
      code,
      plistName,
      xrayConfigPath,
      setMessage,
      logMessage,
    );

    try {
      await platform.invokeMethod('writeConfigFiles', {
        'xrayConfigPath': xrayConfigPath,
        'xrayConfigContent': xrayConfigContent,
        'plistPath': plistPath,
        'plistContent': plistContent,
        'vpnNodesConfigPath': vpnNodesConfigPath,
        'vpnNodesConfigContent': vpnNodesConfigContent,
        'password': password,
      });

      setMessage('✅ 配置已保存: $xrayConfigPath');
      setMessage('✅ 服务项已生成: $plistPath');
      setMessage('✅ 菜单项已更新: $vpnNodesConfigPath');
      logMessage('配置已成功保存并生成');
    } on PlatformException catch (e) {
      setMessage('生成配置失败: $e');
      logMessage('生成配置失败: $e');
    }
  }

  static Future<String> _generateXrayJsonConfig(String domain, String port, String uuid, Function(String) setMessage, Function(String) logMessage) async {
    try {
      final replaced = defaultXrayJsonTemplate
          .replaceAll('<SERVER_DOMAIN>', domain)
          .replaceAll('<PORT>', port)
          .replaceAll('<UUID>', uuid);

      final jsonObj = jsonDecode(replaced);
      final formatted = JsonEncoder.withIndent('  ').convert(jsonObj);
      logMessage('✅ XrayJson 配置内容生成完成');
      return formatted;
    } catch (e) {
      setMessage('❌ XrayJson 生成失败: $e');
      logMessage('XrayJson 错误: $e');
      return '';
    }
  }

  static String _generatePlistFile(String nodeCode, String bundleId, String configPath) {
    try {
      return renderXrayPlist(
        bundleId: bundleId,
        name: nodeCode.toLowerCase(),
        configPath: configPath,
      );
    } catch (e) {
      return '';
    }
  }

  static Future<String> _generateVpnNodesJsonContent(
    String nodeName,
    String nodeCode,
    String plistName,
    String xrayConfigPath,
    Function(String) setMessage,
    Function(String) logMessage,
  ) async {
    if (nodeName.trim().isEmpty || nodeCode.trim().isEmpty || plistName.trim().isEmpty || xrayConfigPath.trim().isEmpty) {
      final err = 'VPN 节点信息不完整，无法生成 JSON 配置';
      setMessage('❌ $err');
      logMessage(err);
      return '';
    }

    final vpnNode = {
      'name': nodeName,
      'countryCode': nodeCode,
      'plistName': plistName,
      'configPath': xrayConfigPath,
      'enabled': true,
    };

    final vpnNodesJsonContent = json.encode([vpnNode]);
    logMessage('✅ vpn_nodes.json 内容生成完成');
    return vpnNodesJsonContent;
  }
}
