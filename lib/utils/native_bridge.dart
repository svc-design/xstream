import 'package:flutter/services.dart';
import '../../services/vpn_config_service.dart';  // 引入新的 VpnConfig 类

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');

  // 启动节点服务
  static Future<String> startNodeService(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';

    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {'plistName': node.plistName},  // 直接传递 plistName
      );
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  // 停止节点服务
  static Future<String> stopNodeService(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';

    try {
      final result = await _channel.invokeMethod<String>(
        'stopNodeService',
        {'plistName': node.plistName},  // 直接传递 plistName
      );
      return result ?? '已停止';
    } catch (e) {
      return '停止失败: $e';
    }
  }

  // 检查节点状态
  static Future<bool> checkNodeStatus(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'checkNodeStatus',
        {'plistName': node.plistName},  // 直接传递 plistName
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // 初始化日志
  static void initializeLogger(Function(String log) onLog) {
    _loggerChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final log = call.arguments;
        if (log is String) onLog(log);
      }
    });
  }

  // 初始化 Xray
  static Future<String> initXray() async {
    try {
      final result = await _channel.invokeMethod<String>(
        'performAction',
        {'action': 'initXray'},
      );
      return result ?? '初始化完成，但无返回内容';
    } catch (e) {
      return '初始化失败: $e';
    }
  }
}
