import 'dart:io';
import 'package:flutter/services.dart';
import '../../services/vpn_config_service.dart'; // 引入新的 VpnConfig 类

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  // 启动节点服务（防止重复启动）
  static Future<String> startNodeService(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';

    if (!_isDesktop) return '当前平台暂不支持';

    // ✅ 新增：避免重复启动
    final isRunning = await checkNodeStatus(nodeName);
    if (isRunning) return '服务已在运行';

    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {'serviceName': node.serviceName},
      );
      return result ?? '启动成功';
    } on MissingPluginException {
      return '插件未实现';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  // 停止节点服务
  static Future<String> stopNodeService(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';

    if (!_isDesktop) return '当前平台暂不支持';

    try {
      final result = await _channel.invokeMethod<String>(
        'stopNodeService',
        {'serviceName': node.serviceName},
      );
      return result ?? '已停止';
    } on MissingPluginException {
      return '插件未实现';
    } catch (e) {
      return '停止失败: $e';
    }
  }

  // 检查节点状态
  static Future<bool> checkNodeStatus(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return false;

    if (!_isDesktop) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'checkNodeStatus',
        {'serviceName': node.serviceName}, // 直接传递服务名称
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // 初始化日志监听（用于原生发送 log 到 Dart）
  static void initializeLogger(Function(String log) onLog) {
    _loggerChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final log = call.arguments;
        if (log is String) onLog(log);
      }
    });
  }

  // 初始化 Xray：会触发原生 performAction:initXray
  static Future<String> initXray() async {
    if (!_isDesktop) return '当前平台暂不支持';

    try {
      final result = await _channel.invokeMethod<String>(
        'performAction',
        {'action': 'initXray'},
      );
      return result ?? '初始化完成，但无返回内容';
    } on MissingPluginException {
      return '插件未实现';
    } catch (e) {
      return '初始化失败: $e';
    }
  }

  // 重置配置和 Xray 文件：触发 performAction:resetXrayAndConfig
  static Future<String> resetXrayAndConfig(String password) async {
    if (!_isDesktop) return '当前平台暂不支持';

    try {
      final result = await _channel.invokeMethod<String>(
        'performAction',
        {
          'action': 'resetXrayAndConfig',
          'password': password,
        },
      );
      return result ?? '重置完成';
    } on MissingPluginException {
      return '插件未实现';
    } catch (e) {
      return '重置失败: $e';
    }
  }
}
