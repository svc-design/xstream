import 'package:flutter/services.dart';
import 'vpn_config.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');

  static Future<String> startNodeService(String nodeName) async {
    final node = VpnConfigManager.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';
    final suffix = node.plistName;

    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {'nodeSuffix': suffix},
      );
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  static Future<String> stopNodeService(String nodeName) async {
    final node = VpnConfigManager.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';
    final suffix = node.plistName;

    try {
      final result = await _channel.invokeMethod<String>(
        'stopNodeService',
        {'nodeSuffix': suffix},
      );
      return result ?? '已停止';
    } catch (e) {
      return '停止失败: $e';
    }
  }

  static Future<bool> checkNodeStatus(String nodeName) async {
    final node = VpnConfigManager.getNodeByName(nodeName);
    if (node == null) return false;
    final suffix = node.plistName;

    try {
      final result = await _channel.invokeMethod<bool>(
        'checkNodeStatus',
        {'nodeSuffix': suffix},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static void initializeLogger(Function(String log) onLog) {
    _loggerChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final log = call.arguments as String?;
        if (log != null) onLog(log);
      }
    });
  }

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
