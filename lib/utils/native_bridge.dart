import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../services/vpn_config_service.dart';  // 引入新的 VpnConfig 类

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');
  static Process? _xrayProcess; // Windows proxy process

  // 启动节点服务
  static Future<String> startNodeService(String nodeName) async {
    if (Platform.isWindows) {
      return _startXrayProxy();
    }
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
    if (Platform.isWindows) {
      return _stopXrayProxy();
    }
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
    if (Platform.isWindows) {
      return _xrayProcess != null;
    }
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

  // Windows-specific: start xray-core proxy
  static Future<String> _startXrayProxy() async {
    if (_xrayProcess != null) return 'Xray 已在运行';
    try {
      final dir = await getApplicationSupportDirectory();
      final configPath = p.join(dir.path, 'xray-vpn.json');
      final file = File(configPath);
      if (!await file.exists()) {
        final data = await rootBundle.loadString('assets/xray-vpn.json');
        await file.writeAsString(data);
      }
      _xrayProcess = await Process.start('xray.exe', ['run', '-c', configPath], runInShell: true);
      return 'Xray 已启动';
    } catch (e) {
      _xrayProcess = null;
      return '启动失败: $e';
    }
  }

  // Windows-specific: stop xray-core proxy
  static Future<String> _stopXrayProxy() async {
    if (_xrayProcess == null) return 'Xray 未启动';
    try {
      _xrayProcess!.kill();
      _xrayProcess = null;
      return 'Xray 已停止';
    } catch (e) {
      return '停止失败: $e';
    }
  }
}
