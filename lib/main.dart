import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';
import 'utils/native_bridge.dart';
import 'utils/log_store.dart'; // ✅ 添加漏引的 log_store.dart
import 'widgets/log_console.dart'; // ✅ 提供 LogLevel 类型支持
import 'widgets/lock_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XStream',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _isUnlocked = false;
  String _sudoPassword = '';
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // ✅ 修复后的日志回调写法
    NativeBridge.initializeLogger((log) {
      LogStore.add(LogEntry(LogLevel.info, "[macOS] $log"));
    });

    _pages.addAll([
      HomeScreen(isUnlocked: _isUnlocked, sudoPassword: _sudoPassword),
      SubscriptionScreen(
        isUnlocked: _isUnlocked,
        sudoPassword: _sudoPassword,
        onRequestUnlock: (password) {
          setState(() {
            _isUnlocked = true;
            _sudoPassword = password;
          });
        },
      ),
      SettingsScreen(isUnlocked: _isUnlocked, sudoPassword: _sudoPassword),
    ]);
  }

  void _updatePages() {
    _pages[0] = HomeScreen(isUnlocked: _isUnlocked, sudoPassword: _sudoPassword);
    _pages[1] = SubscriptionScreen(
      isUnlocked: _isUnlocked,
      sudoPassword: _sudoPassword,
      onRequestUnlock: (password) {
        setState(() {
          _isUnlocked = true;
          _sudoPassword = password;
        });
      },
    );
    _pages[2] = SettingsScreen(isUnlocked: _isUnlocked, sudoPassword: _sudoPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XStream'),
        actions: [
          LockButton(
            onUnlock: (password) {
              setState(() {
                _isUnlocked = true;
                _sudoPassword = password;
                _updatePages();
              });
            },
            onLock: () {
              setState(() {
                _isUnlocked = false;
                _sudoPassword = '';
                _updatePages();
              });
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Subscriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
