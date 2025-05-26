import '../widgets/log_console.dart';

class LogStore {
  static final List<LogEntry> _logs = [];

  static void add(LogEntry entry) {
    _logs.add(entry);
  }

  static void clear() {
    _logs.clear();
  }

  static List<LogEntry> getAll() => List.unmodifiable(_logs);
}
