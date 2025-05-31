import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_node.dart';

class VpnConfigManager {
  static List<VpnNode> _nodes = [];

  /// 默认本地配置文件路径（macOS）
  static Future<String> _getLocalConfigPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/vpn_nodes.json';
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
      print('⚠️ Failed to load assets/vpn_nodes.json: $e');
    }

    try {
      final path = await _getLocalConfigPath();
      final file = File(path);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonStr);
        fromLocal = jsonList.map((e) => VpnNode.fromJson(e)).toList();
      }
    } catch (e) {
      print('⚠️ Failed to load local vpn_nodes.json: $e');
    }

    // 合并（本地配置覆盖 asset 中相同 name 的节点）
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

  /// 保存配置并返回保存路径
  static Future<String> saveToFile() async {
    final path = await _getLocalConfigPath();
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

  /// 删除节点对应的配置文件和 plist 文件（如果存在），并从内存移除
  static Future<void> deleteNodeFiles(VpnNode node) async {
    try {
      final jsonFile = File(node.configPath);
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      final homeDir = Platform.environment['HOME'] ?? '/Users/unknown';
      final plistPath = '$homeDir/Library/LaunchAgents/com.xstream.xray-node-${node.plistName}.plist';
      final plistFile = File(plistPath);
      if (await plistFile.exists()) {
        await plistFile.delete();
      }

      removeNode(node.name);
      await saveToFile();
    } catch (e) {
      print('⚠️ 删除节点文件失败: $e');
    }
  }
}
