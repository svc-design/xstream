import '../widgets/log_console.dart';

class LogStore {
  static final List<LogEntry> _logs = [];

  static void add(LogEntry entry) {
    _logs.add(entry);
  }

  // 支持快捷写法：LogStore.add(LogLevel.info, "msg")
  static void addLog(LogLevel level, String message) {
    _logs.add(LogEntry(level, message));
  }

  static void clear() {
    _logs.clear();
  }

  static List<LogEntry> getAll() => List.unmodifiable(_logs);
}

