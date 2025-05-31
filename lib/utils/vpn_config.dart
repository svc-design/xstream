import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/vpn_node.dart';

class VpnConfigManager {
  static List<VpnNode> _nodes = [];

  /// 加载 VPN 节点配置（从 assets/vpn_nodes.json）
  static Future<void> load() async {
    final String jsonStr = await rootBundle.loadString('assets/vpn_nodes.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _nodes = jsonList.map((e) => VpnNode.fromJson(e)).toList();
  }

  /// 获取全部节点
  static List<VpnNode> get nodes => _nodes;

  /// 获取指定节点
  static VpnNode? getNodeByName(String name) {
    try {
      return _nodes.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 添加新节点
  static void addNode(VpnNode node) {
    _nodes.add(node);
  }

  /// 删除节点
  static void removeNode(String name) {
    _nodes.removeWhere((e) => e.name == name);
  }

  /// 更新已有节点
  static void updateNode(VpnNode updated) {
    final index = _nodes.indexWhere((e) => e.name == updated.name);
    if (index != -1) {
      _nodes[index] = updated;
    }
  }

  /// 导出当前节点列表为 JSON 字符串
  static String exportToJson() {
    return json.encode(_nodes.map((e) => e.toJson()).toList());
  }

  /// 从 JSON 字符串导入节点列表（覆盖原数据）
  static void importFromJson(String jsonStr) {
    final List<dynamic> jsonList = json.decode(jsonStr);
    _nodes = jsonList.map((e) => VpnNode.fromJson(e)).toList();
  }

  /// 保存到文件（可选：用于调试）
  static Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.writeAsString(exportToJson());
  }
}
