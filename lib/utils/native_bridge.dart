import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');

  /// 启动指定节点的 Xray 服务（通过 LaunchAgent 名称自动推导）
  static Future<String> startNodeService(String nodeName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {
          'node': nodeName,
        },
      );
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  /// 停止指定节点的 Xray 服务（通过 LaunchAgent 名称自动推导）
  static Future<String> stopNodeService(String nodeName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'stopNodeService',
        {
          'node': nodeName,
        },
      );
      return result ?? '已停止';
    } catch (e) {
      return '停止失败: $e';
    }
  }
}
