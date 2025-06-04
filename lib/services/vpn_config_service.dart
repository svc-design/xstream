import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/global_config.dart';

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

  // 添加 getConfigPath 方法
  static Future<String> getConfigPath() async {
    return await GlobalApplicationConfig.getLocalConfigPath();  // 获取配置路径
  }

  /// 加载 VPN 节点配置（本地文件优先，其次 assets）并合并
  static Future<void> load() async {
    List<VpnNode> fromAssets = [];
    List<VpnNode> fromLocal = [];

    try {
      final String jsonStr = await rootBundle.loadString('assets/vpn_nodes.json');
      final List<dynamic> jsonList = json.decode(jsonStr);
      fromAssets = jsonList.map((e) => VpnNode.fromJson(e)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to load assets/vpn_nodes.json: $e');
    }

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

    final Map<String, VpnNode> merged = {
      for (var node in fromAssets) node.name: node,
      for (var node in fromLocal) node.name: node,
    };

    _nodes = merged.values.toList();
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

  /// 删除节点相关文件
  static Future<void> deleteNodeFiles(VpnNode node) async {
    try {
      final jsonFile = File(node.configPath);
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
      final bundleId = await GlobalApplicationConfig.getBundleId();
      final plistPath = '$homeDir/Library/LaunchAgents/$bundleId.xray-node-${node.plistName}.plist';
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


    // HOME 路径
    final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';

    // Xray 配置文件路径
    final xrayConfigPath = '/opt/homebrew/etc/xray-node-${nodeName.toLowerCase()}.json';
    // 生成 Xray 配置
    final xrayConfigContent = await _generateXrayJsonConfig(domain, port, uuid, setMessage, logMessage);
    if (xrayConfigContent.isEmpty) return;

    // Plist 文件路径
    final plistName = '$bundleId.xray-node-${nodeName.toLowerCase()}.plist';
    final plistPath = '$homeDir/Library/LaunchAgents/$bundleId.xray-node-${nodeName.toLowerCase()}.plist';
    // 生成 Plist 配置
    final plistContent = await _generatePlistFile(nodeName, bundleId, xrayConfigPath, setMessage, logMessage);
    if (plistContent.isEmpty) return;

    // 获取不同路径
    final vpnNodesConfigPath = await GlobalApplicationConfig.getLocalConfigPath(); // vpn_nodes.json 路径
    // 生成 vpn_nodes.json 内容
    final vpnNodesConfigContent = await _generateVpnNodesJsonContent(nodeName, plistName, xrayConfigPath, setMessage, logMessage);

    // 通过原生代码写入文件
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

      setMessage('✅ 配置已保存: $plistPath\n✅ 服务项已生成: $plistPath');
      setMessage('✅ 配置已保存: $xrayConfigPath\n✅ 服务项已生成: $xrayConfigPath');
      setMessage('✅ 配置已保存: $vpnNodesConfigPath\n✅ 服务项已生成: $vpnNodesConfigPath');
      logMessage('配置已成功保存并生成');
    } on PlatformException catch (e) {
      setMessage('生成配置失败: $e');
      logMessage('生成配置失败: $e');
    }
  }


  /// Helper function to handle Xray JSON file generation
  static Future<String> _generateXrayJsonConfig(String domain, String port, String uuid, Function(String) setMessage, Function(String) logMessage) async {
    String configTemplate;
    try {
      configTemplate = await rootBundle.loadString('assets/xray-template.json');
      logMessage('xrayJson 模板加载成功');
    } catch (e) {
      setMessage('xrayJson 加载模板失败: $e');
      logMessage('xrayJson 加载模板失败: $e');
      return ''; // Return empty string to indicate failure
    }

    String rawJson = configTemplate
        .replaceAll('<SERVER_DOMAIN>', domain)
        .replaceAll('<PORT>', port)
        .replaceAll('<UUID>', uuid);

    late String xrayJsonContent;
    try {
      final jsonObj = jsonDecode(rawJson);
      xrayJsonContent = JsonEncoder.withIndent('  ').convert(jsonObj);
      logMessage('xrayJson 配置文件创建成功');
    } catch (e) {
      setMessage('✅ XrayJson 配置内容生成完成');
      logMessage('✅ XrayJson 配置内容生成完成');
      return ''; // Return empty string to indicate failure
    }

    return xrayJsonContent;
  }

  /// Helper function to handle Plist file generation
  static Future<String> _generatePlistFile(
    String nodeName,
    String bundleId,
    String configPath,
    Function(String) setMessage,
    Function(String) logMessage,
  ) async {
    if (nodeName.length < 2) {
      final err = '节点名长度不足，无法提取国家码';
      setMessage('❌ $err');
      logMessage(err);
      return '';
    }

    String plistTemplate;
    try {
      plistTemplate = await rootBundle.loadString('assets/xray-template.plist');
      logMessage('✅ Plist 模板加载成功');
    } catch (e) {
      final err = '加载 Plist 模板失败: $e';
      setMessage('❌ $err');
      logMessage(err);
      return '';
    }

    final plistContent = plistTemplate
        .replaceAll('<BUNDLE_ID>', bundleId)
        .replaceAll('<NAME>', nodeName.toLowerCase())
        .replaceAll('<CONFIG_PATH>', configPath);

    logMessage('✅ Plist 内容生成完成');
    return plistContent;
  }

  /// Helper function to generate vpn_nodes.json content
  static Future<String> _generateVpnNodesJsonContent(
    String nodeName,
    String plistPath,
    String xrayConfigPath,
    Function(String) setMessage,
    Function(String) logMessage,
  ) async {
    if (nodeName.trim().isEmpty || plistPath.trim().isEmpty || xrayConfigPath.trim().isEmpty) {
      final err = 'VPN 节点信息不完整，无法生成 JSON 配置';
      setMessage('❌ $err');
      logMessage(err);
      return '';
    }

    final vpnNode = {
      'name': nodeName,
      'countryCode': nodeName.substring(0, 2),
      'plistName': plistPath,
      'configPath': xrayConfigPath,
      'enabled': true,
    };

    final vpnNodesJsonContent = json.encode([vpnNode]);
    logMessage('✅ vpn_nodes.json 内容生成完成');
    return vpnNodesJsonContent;
  }
}
