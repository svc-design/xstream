import 'package:flutter/services.dart';
import 'vpn_config.dart';
import 'global_state.dart'; // ✅ 引入 GlobalState 获取 sudoPassword

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');

  /// 启动 VPN 节点服务
  static Future<String> startNodeService(String nodeName) async {
    final suffix = vpnPlistNameMap[nodeName];
    if (suffix == null) return '未知节点: $nodeName';

    final password = GlobalState.sudoPassword;
    if (password.isEmpty) return '⚠️ 尚未提供管理员密码';

    try {
      final result = await _channel.invokeMethod<String>(
        'startNodeService',
        {
          'nodeSuffix': suffix,
          'sudoPassword': password,
        },
      );
      return result ?? '启动成功';
    } catch (e) {
      return '启动失败: $e';
    }
  }

  /// 停止 VPN 节点服务
  static Future<String> stopNodeService(String nodeName) async {
    final suffix = vpnPlistNameMap[nodeName];
    if (suffix == null) return '未知节点: $nodeName';

    final password = GlobalState.sudoPassword;
    if (password.isEmpty) return '⚠️ 尚未提供管理员密码';

    try {
      final result = await _channel.invokeMethod<String>(
        'stopNodeService',
        {
          'nodeSuffix': suffix,
          'sudoPassword': password,
        },
      );
      return result ?? '已停止';
    } catch (e) {
      return '停止失败: $e';
    }
  }

  /// 检查 VPN 服务是否正在运行
  static Future<bool> checkNodeStatus(String nodeName) async {
    final suffix = vpnPlistNameMap[nodeName];
    if (suffix == null) return false;

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

  /// 注册原生日志监听器
  static void initializeLogger(Function(String log) onLog) {
    _loggerChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final log = call.arguments as String?;
        if (log != null) onLog(log);
      }
    });
  }
}
