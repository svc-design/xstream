import 'package:flutter/foundation.dart';

/// 全局应用状态管理（使用 ValueNotifier 实现响应式绑定）
class GlobalState {
  /// 解锁状态（true 表示已解锁）
  static final ValueNotifier<bool> isUnlocked = ValueNotifier(false);

  /// 当前解锁使用的 sudo 密码（可供原生调用或配置操作使用）
  static final ValueNotifier<String> sudoPassword = ValueNotifier('');
}
