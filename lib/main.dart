import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'utils/app_theme.dart';
import 'utils/log_store.dart';
import 'utils/global_state.dart';
import 'utils/native_bridge.dart';
import 'widgets/log_console.dart';

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
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    NativeBridge.initializeLogger((log) {
      LogStore.addLog(LogLevel.info, "[macOS] $log");
    });
  }

  Future<void> _promptUnlockDialog() async {
    String? password = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('输入密码解锁'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('确认')),
          ],
        );
      },
    );

    if (password != null && password.isNotEmpty) {
      GlobalState.isUnlocked.value = true;
      GlobalState.sudoPassword.value = password;
    }
  }

  void _lock() {
    GlobalState.isUnlocked.value = false;
    GlobalState.sudoPassword.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XStream'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: GlobalState.isUnlocked,
            builder: (context, unlocked, _) {
              return IconButton(
                icon: Icon(unlocked ? Icons.lock_open : Icons.lock),
                onPressed: unlocked ? _lock : _promptUnlockDialog,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          SubscriptionScreen(),
          SettingsScreen(),
        ],
      ),
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

