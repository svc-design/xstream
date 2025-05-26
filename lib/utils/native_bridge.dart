import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');

  /// 启动指定节点的 Xray 服务
  static Future<String> startNodeService(String nodeName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {'node': nodeName},
      );
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  /// 停止指定节点的 Xray 服务
  static Future<String> stopNodeService(String nodeName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'stopNodeService',
        {'node': nodeName},
      );
      return result ?? '已停止';
    } catch (e) {
      return '停止失败: $e';
    }
  }

  /// 初始化日志监听
  static void initializeLogger(void Function(String logLine) onLog) {
    const logChannel = MethodChannel('com.xstream/logger');
    logChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        onLog(call.arguments as String);
      }
    });
  }
}
