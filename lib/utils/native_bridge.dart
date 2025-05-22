import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');

  static Future<String> startXrayService() async {
    try {
      final result = await _channel.invokeMethod<String>('startXrayService');
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  static Future<String> stopXrayService() async {
    try {
      final result = await _channel.invokeMethod<String>('stopXrayService');
      return result ?? '停止成功';
    } catch (e) {
      return '停止失败: $e';
    }
  }
}

