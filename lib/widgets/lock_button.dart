// lib/widgets/lock_button.dart
import 'package:flutter/material.dart';
import '../../utils/global_state.dart';

class LockButton extends StatefulWidget {
  final Function(String)? onUnlock;
  final Function()? onLock;

  const LockButton({Key? key, this.onUnlock, this.onLock}) : super(key: key);

  @override
  _LockButtonState createState() => _LockButtonState();
}

class _LockButtonState extends State<LockButton> {
  bool get _isLocked => !GlobalState.isUnlocked.value;

  Future<void> _promptForPassword() async {
    String? password = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController passwordController = TextEditingController();
        return AlertDialog(
          title: Text('输入密码解锁'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(passwordController.text),
              child: Text('确认'),
            ),
          ],
        );
      },
    );

    if (password != null) {
      _attemptUnlock(password);
    }
  }

  void _attemptUnlock(String password) {
    GlobalState.isUnlocked.value = true;
    GlobalState.sudoPassword.value = password;
    widget.onUnlock?.call(password);
  }

  void _toggleLock() async {
    if (_isLocked) {
      await _promptForPassword();
    } else {
      GlobalState.isUnlocked.value = false;
      GlobalState.sudoPassword.value = '';
      widget.onLock?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalState.isUnlocked,
      builder: (context, isUnlocked, _) {
        return IconButton(
          icon: Icon(isUnlocked ? Icons.lock_open : Icons.lock),
          onPressed: _toggleLock,
        );
      },
    );
  }
}
