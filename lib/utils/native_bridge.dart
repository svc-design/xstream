import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');

  /// 启动指定节点的 Xray 服务
  static Future<String> startNodeService(String configPath, String nodeName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {'config': configPath, 'node': nodeName},
      );
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  /// 停止所有 Xray 服务（通过 pkill 实现）
  static Future<String> stopXrayService() async {
    try {
      final result = await _channel.invokeMethod<String>('stopXrayService');
      return result ?? '停止成功';
    } catch (e) {
      return '停止失败: $e';
    }
  }
}
