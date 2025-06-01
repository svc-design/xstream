import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/log_console.dart';

// LogConsole Global Key
final GlobalKey<LogConsoleState> logConsoleKey = GlobalKey<LogConsoleState>();

/// 全局应用状态管理（使用 ValueNotifier 实现响应式绑定）
class GlobalState {
  /// 解锁状态（true 表示已解锁）
  static final ValueNotifier<bool> isUnlocked = ValueNotifier<bool>(false);

  /// 当前解锁使用的 sudo 密码（可供原生调用或配置操作使用）
  static final ValueNotifier<String> sudoPassword = ValueNotifier<String>('');
}

/// 用于获取应用相关的配置信息
class GlobalApplicationConfig {
  /// 从 macOS 配置文件中动态获取 PRODUCT_BUNDLE_IDENTIFIER
  static Future<String> getBundleId() async {
    try {
      // 读取 macOS 配置文件，获取 PRODUCT_BUNDLE_IDENTIFIER
      final config = await rootBundle.loadString('macos/Runner/Configs/AppInfo.xcconfig');
      final line = config.split('\n').firstWhere((l) => l.startsWith('PRODUCT_BUNDLE_IDENTIFIER='));
      return line.split('=').last.trim();
    } catch (_) {
      return 'com.xstream'; // 返回默认值
    }
  }

  /// 默认本地配置文件路径（macOS）
  static Future<String> getLocalConfigPath() async {
    final bundleId = await getBundleId();  // 获取 PRODUCT_BUNDLE_IDENTIFIER
    final baseDir = await getApplicationSupportDirectory();  // 获取应用支持目录
    final xstreamDir = Directory('${baseDir.path}/$bundleId');  // 拼接目录路径
    await xstreamDir.create(recursive: true);  // 创建目录（如果不存在）
    return '${xstreamDir.path}/vpn_nodes.json';  // 返回完整路径
  }
}
