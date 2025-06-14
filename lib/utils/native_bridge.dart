import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import '../../services/vpn_config_service.dart'; // 引入新的 VpnConfig 类

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');

  static DynamicLibrary? _lib;
  static DynamicLibrary get _library {
    _lib ??= () {
      final name = Platform.isWindows ? 'libgo_logic.dll' : 'libnative_bridge.so';
      return DynamicLibrary.open(name);
    }();
    return _lib!;
  }

  static Pointer<Utf8> _toNative(String s) => s.toNativeUtf8();

  static String _fromNative(Pointer<Utf8> ptr) {
    final result = ptr.toDartString();
    if (Platform.isLinux) {
      final freeFn = _library.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>('FreeCString');
      freeFn(ptr);
    }
    return result;
  }

  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  // 启动节点服务（防止重复启动）
  static Future<String> startNodeService(String nodeName) async {
    final node = VpnConfig.getNodeByName(nodeName);
    if (node == null) return '未知节点: $nodeName';

    if (!_isDesktop) return '当前平台暂不支持';

    final isRunning = await checkNodeStatus(nodeName);
    if (isRunning) return '服务已在运行';

    if (Platform.isWindows) {
      final fn = _library.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('StartNodeService');
      final ptr = _toNative(node.serviceName);
      final code = fn(ptr);
      calloc.free(ptr);
      return code == 0 ? '启动成功' : '启动失败';
    } else if (Platform.isLinux) {
      final fn = _library.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('StartNodeService');
      final ptr = _toNative(node.serviceName);
      final resPtr = fn(ptr);
      calloc.free(ptr);
      final res = _fromNative(resPtr);
      return res.startsWith('error:') ? '启动失败: ${res.substring(6)}' : res;
    }

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

    if (Platform.isWindows) {
      final fn = _library.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('StopNodeService');
      final ptr = _toNative(node.serviceName);
      final code = fn(ptr);
      calloc.free(ptr);
      return code == 0 ? '已停止' : '停止失败';
    } else if (Platform.isLinux) {
      final fn = _library.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('StopNodeService');
      final ptr = _toNative(node.serviceName);
      final resPtr = fn(ptr);
      calloc.free(ptr);
      final res = _fromNative(resPtr);
      return res.startsWith('error:') ? '停止失败: ${res.substring(6)}' : res;
    }

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
    if (Platform.isWindows) {
      final fn = _library.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('CheckNodeStatus');
      final ptr = _toNative(node.serviceName);
      final code = fn(ptr);
      calloc.free(ptr);
      return code == 1;
    } else if (Platform.isLinux) {
      final fn = _library.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('CheckNodeStatus');
      final ptr = _toNative(node.serviceName);
      final code = fn(ptr);
      calloc.free(ptr);
      return code == 1;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'checkNodeStatus',
        {'serviceName': node.serviceName},
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
    if (Platform.isWindows) {
      final fn = _library.lookupFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>), int Function(Pointer<Utf8>, Pointer<Utf8>)>('PerformAction');
      final action = _toNative('initXray');
      final code = fn(action, nullptr);
      calloc.free(action);
      return code == 0 ? '初始化完成' : '初始化失败';
    } else if (Platform.isLinux) {
      final fn = _library.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('InitXray');
      final resPtr = fn();
      final res = _fromNative(resPtr);
      return res.startsWith('error:') ? '初始化失败: ${res.substring(6)}' : res;
    }

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
    if (Platform.isWindows) {
      final fn = _library.lookupFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>), int Function(Pointer<Utf8>, Pointer<Utf8>)>('PerformAction');
      final action = _toNative('resetXrayAndConfig');
      final pwd = _toNative(password);
      final code = fn(action, pwd);
      calloc.free(action);
      calloc.free(pwd);
      return code == 0 ? '重置完成' : '重置失败';
    } else if (Platform.isLinux) {
      final fn = _library.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('ResetXrayAndConfig');
      final pwd = _toNative(password);
      final resPtr = fn(pwd);
      calloc.free(pwd);
      final res = _fromNative(resPtr);
      return res.startsWith('error:') ? '重置失败: ${res.substring(6)}' : res;
    }

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

  static Future<void> writeConfigFiles({
    required String xrayPath,
    required String xrayContent,
    required String servicePath,
    required String serviceContent,
    required String vpnNodesPath,
    required String vpnNodesContent,
    required String password,
  }) async {
    if (!_isDesktop) return;

    if (Platform.isWindows) {
      final fn = _library.lookupFunction<
          Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
          int Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>('WriteConfigFiles');
      final p1 = _toNative(xrayPath);
      final p2 = _toNative(xrayContent);
      final p3 = _toNative(servicePath);
      final p4 = _toNative(serviceContent);
      final p5 = _toNative(vpnNodesPath);
      final p6 = _toNative(vpnNodesContent);
      final code = fn(p1, p2, p3, p4, p5, p6);
      calloc.free(p1);
      calloc.free(p2);
      calloc.free(p3);
      calloc.free(p4);
      calloc.free(p5);
      calloc.free(p6);
      if (code != 0) throw Exception('WriteConfigFiles failed');
      return;
    } else if (Platform.isLinux) {
      final fn = _library.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)>('WriteConfigFiles');
      final p1 = _toNative(xrayPath);
      final p2 = _toNative(xrayContent);
      final p3 = _toNative(servicePath);
      final p4 = _toNative(serviceContent);
      final p5 = _toNative(vpnNodesPath);
      final p6 = _toNative(vpnNodesContent);
      final p7 = _toNative(password);
      final resPtr = fn(p1, p2, p3, p4, p5, p6, p7);
      calloc.free(p1);
      calloc.free(p2);
      calloc.free(p3);
      calloc.free(p4);
      calloc.free(p5);
      calloc.free(p6);
      calloc.free(p7);
      final res = _fromNative(resPtr);
      if (res.startsWith('error:')) throw Exception(res.substring(6));
      return;
    }

    await _channel.invokeMethod('writeConfigFiles', {
      'xrayConfigPath': xrayPath,
      'xrayConfigContent': xrayContent,
      'servicePath': servicePath,
      'serviceContent': serviceContent,
      'vpnNodesConfigPath': vpnNodesPath,
      'vpnNodesConfigContent': vpnNodesContent,
      'password': password,
    });
  }
}
