import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import '../../services/vpn_config_service.dart'; // 引入新的 VpnConfig 类

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.xstream/native');
  static const MethodChannel _loggerChannel = MethodChannel('com.xstream/logger');

  static ffi.DynamicLibrary? _lib;
  static bool get _useFfi => Platform.isWindows || Platform.isLinux;

  // Windows bindings
  static int Function(ffi.Pointer<ffi.Utf8>)? _startNodeServiceWin;
  static int Function(ffi.Pointer<ffi.Utf8>)? _stopNodeServiceWin;
  static int Function(ffi.Pointer<ffi.Utf8>)? _checkNodeStatusWin;
  static int Function()? _initXrayWin;
  static int Function(ffi.Pointer<ffi.Utf8>)? _resetXrayWin;
  static int Function(
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>)? _writeConfigFilesWin;

  // Linux bindings
  static ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>)? _startNodeServiceLinux;
  static ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>)? _stopNodeServiceLinux;
  static int Function(ffi.Pointer<ffi.Utf8>)? _checkNodeStatusLinux;
  static ffi.Pointer<ffi.Utf8> Function()? _initXrayLinux;
  static ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>)? _resetXrayLinux;
  static ffi.Pointer<ffi.Utf8> Function(
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>,
      ffi.Pointer<ffi.Utf8>)? _writeConfigFilesLinux;
  static void Function(ffi.Pointer<ffi.Utf8>)? _freeCString;

  static void _ensureLibLoaded() {
    if (!_useFfi || _lib != null) return;
    try {
      if (Platform.isWindows) {
        _lib = ffi.DynamicLibrary.open('nativebridge.dll');
        _startNodeServiceWin = _lib!.lookupFunction<ffi.Int32 Function(ffi.Pointer<ffi.Utf8>), int Function(ffi.Pointer<ffi.Utf8>)>('StartNodeService');
        _stopNodeServiceWin = _lib!.lookupFunction<ffi.Int32 Function(ffi.Pointer<ffi.Utf8>), int Function(ffi.Pointer<ffi.Utf8>)>('StopNodeService');
        _checkNodeStatusWin = _lib!.lookupFunction<ffi.Int32 Function(ffi.Pointer<ffi.Utf8>), int Function(ffi.Pointer<ffi.Utf8>)>('CheckNodeStatus');
        _initXrayWin = _lib!.lookupFunction<ffi.Int32 Function(), int Function()>('InitXray');
        _resetXrayWin = _lib!.lookupFunction<ffi.Int32 Function(ffi.Pointer<ffi.Utf8>), int Function(ffi.Pointer<ffi.Utf8>)>('ResetXrayAndConfig');
        _writeConfigFilesWin = _lib!.lookupFunction<
            ffi.Int32 Function(ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>),
            int Function(ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>)>('WriteConfigFiles');
      } else if (Platform.isLinux) {
        _lib = ffi.DynamicLibrary.open('libnative_bridge.so');
        _startNodeServiceLinux = _lib!.lookupFunction<ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>), ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>)>('StartNodeService');
        _stopNodeServiceLinux = _lib!.lookupFunction<ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>), ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>)>('StopNodeService');
        _checkNodeStatusLinux = _lib!.lookupFunction<ffi.Int32 Function(ffi.Pointer<ffi.Utf8>), int Function(ffi.Pointer<ffi.Utf8>)>('CheckNodeStatus');
        _initXrayLinux = _lib!.lookupFunction<ffi.Pointer<ffi.Utf8> Function(), ffi.Pointer<ffi.Utf8> Function()>('InitXray');
        _resetXrayLinux = _lib!.lookupFunction<ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>), ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>)>('ResetXrayAndConfig');
        _writeConfigFilesLinux = _lib!.lookupFunction<
            ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>),
            ffi.Pointer<ffi.Utf8> Function(ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>, ffi.Pointer<ffi.Utf8>)>('WriteConfigFiles');
        _freeCString = _lib!.lookupFunction<ffi.Void Function(ffi.Pointer<ffi.Utf8>), void Function(ffi.Pointer<ffi.Utf8>)>('FreeCString');
      }
    } catch (e) {
      _lib = null;
    }
  }

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

    _ensureLibLoaded();
    if (_lib != null) {
      final ptr = node.serviceName.toNativeUtf8();
      try {
        if (Platform.isWindows) {
          final ret = _startNodeServiceWin!(ptr);
          return ret == 0 ? '启动成功' : '启动失败';
        } else {
          final resPtr = _startNodeServiceLinux!(ptr);
          final res = resPtr.toDartString();
          _freeCString!(resPtr);
          return res;
        }
      } finally {
        malloc.free(ptr);
      }
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

    _ensureLibLoaded();
    if (_lib != null) {
      final ptr = node.serviceName.toNativeUtf8();
      try {
        if (Platform.isWindows) {
          final ret = _stopNodeServiceWin!(ptr);
          return ret == 0 ? '已停止' : '停止失败';
        } else {
          final resPtr = _stopNodeServiceLinux!(ptr);
          final res = resPtr.toDartString();
          _freeCString!(resPtr);
          return res;
        }
      } finally {
        malloc.free(ptr);
      }
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

    _ensureLibLoaded();
    if (_lib != null) {
      final ptr = node.serviceName.toNativeUtf8();
      try {
        int ret;
        if (Platform.isWindows) {
          ret = _checkNodeStatusWin!(ptr);
        } else {
          ret = _checkNodeStatusLinux!(ptr);
        }
        return ret == 1;
      } finally {
        malloc.free(ptr);
      }
    }

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

  // 写入配置文件集合
  static Future<String> writeConfigFiles({
    required String xrayConfigPath,
    required String xrayConfigContent,
    required String servicePath,
    required String serviceContent,
    required String vpnNodesConfigPath,
    required String vpnNodesConfigContent,
    required String password,
  }) async {
    if (!_isDesktop) return '当前平台暂不支持';

    _ensureLibLoaded();
    if (_lib != null) {
      final xp = xrayConfigPath.toNativeUtf8();
      final xc = xrayConfigContent.toNativeUtf8();
      final sp = servicePath.toNativeUtf8();
      final sc = serviceContent.toNativeUtf8();
      final vp = vpnNodesConfigPath.toNativeUtf8();
      final vc = vpnNodesConfigContent.toNativeUtf8();
      final pw = password.toNativeUtf8();
      try {
        if (Platform.isWindows) {
          final ret = _writeConfigFilesWin!(xp, xc, sp, sc, vp, vc);
          return ret == 0 ? 'success' : 'failed';
        } else {
          final resPtr = _writeConfigFilesLinux!(xp, xc, sp, sc, vp, vc, pw);
          final res = resPtr.toDartString();
          _freeCString!(resPtr);
          return res;
        }
      } finally {
        malloc
          ..free(xp)
          ..free(xc)
          ..free(sp)
          ..free(sc)
          ..free(vp)
          ..free(vc)
          ..free(pw);
      }
    }

    try {
      final result = await _channel.invokeMethod<String>('writeConfigFiles', {
        'xrayConfigPath': xrayConfigPath,
        'xrayConfigContent': xrayConfigContent,
        'servicePath': servicePath,
        'serviceContent': serviceContent,
        'vpnNodesConfigPath': vpnNodesConfigPath,
        'vpnNodesConfigContent': vpnNodesConfigContent,
        'password': password,
      });
      return result ?? 'success';
    } on MissingPluginException {
      return '插件未实现';
    } catch (e) {
      return 'failed: $e';
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

    _ensureLibLoaded();
    if (_lib != null) {
      if (Platform.isWindows) {
        final ret = _initXrayWin!();
        return ret == 0 ? '初始化完成' : '初始化失败';
      } else {
        final resPtr = _initXrayLinux!();
        final res = resPtr.toDartString();
        _freeCString!(resPtr);
        return res;
      }
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

    _ensureLibLoaded();
    if (_lib != null) {
      final ptr = password.toNativeUtf8();
      try {
        if (Platform.isWindows) {
          final ret = _resetXrayWin!(ptr);
          return ret == 0 ? '重置完成' : '重置失败';
        } else {
          final resPtr = _resetXrayLinux!(ptr);
          final res = resPtr.toDartString();
          _freeCString!(resPtr);
          return res;
        }
      } finally {
        malloc.free(ptr);
      }
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
}
