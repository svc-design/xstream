import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';
import 'widgets/lock_button.dart'; // 导入锁按钮

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

  bool _isUnlocked = false; // 全局解锁状态
  String _sudoPassword = ''; // 全局 sudo 密码

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // 初始化各个页面，并将解锁状态共享给所有页面
    _pages.addAll([
      HomeScreen(
        isUnlocked: _isUnlocked,
        sudoPassword: _sudoPassword,
      ),
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
      SettingsScreen(
        isUnlocked: _isUnlocked,
        sudoPassword: _sudoPassword,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('XStream'),
        actions: [
          LockButton(
            onUnlock: (password) {
              setState(() {
                _isUnlocked = true;
                _sudoPassword = password;
                // 更新所有页面的解锁状态和 sudo 密码
                _pages[0] = HomeScreen(
                  isUnlocked: _isUnlocked,
                  sudoPassword: _sudoPassword,
                );
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
                _pages[2] = SettingsScreen(
                  isUnlocked: _isUnlocked,
                  sudoPassword: _sudoPassword,
                );
              });
            },
            onLock: () { // 处理锁定逻辑
              setState(() {
                _isUnlocked = false; // 锁定时重置解锁状态
                _sudoPassword = '';  // 清空 sudo 密码
                // 更新所有页面的解锁状态
                _pages[0] = HomeScreen(
                  isUnlocked: _isUnlocked,
                  sudoPassword: _sudoPassword,
                );
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
                _pages[2] = SettingsScreen(
                  isUnlocked: _isUnlocked,
                  sudoPassword: _sudoPassword,
                );
              });
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Subscriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}