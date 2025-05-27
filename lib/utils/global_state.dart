import 'package:flutter/foundation.dart';

class GlobalState {
  static final ValueNotifier<bool> isUnlocked = ValueNotifier(false);
  /// 当前 sudo 密码，仅用于向原生传递，不建议绑定 UI
  static String sudoPassword = '';
}

