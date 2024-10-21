import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';

class LockButton extends StatefulWidget {
  @override
  _LockButtonState createState() => _LockButtonState();
}

class _LockButtonState extends State<LockButton> {
  bool _isLocked = true;

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
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
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

  Future<void> _attemptUnlock(String password) async {
    var shell = Shell();
    try {
      // 示例命令，使用 sudo 提权
      var results = await shell.run('''
        echo $password | sudo -S echo "Checking permissions"
      ''');

      // 取第一个 ProcessResult 来检查 exitCode
      if (results.first.exitCode == 0) {
        setState(() {
          _isLocked = false;
        });
      } else {
        _showError('密码错误或权限不足');
      }
    } catch (e) {
      _showError('解锁失败: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('错误'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _toggleLock() async {
    if (_isLocked) {
      await _promptForPassword();
    } else {
      setState(() {
        _isLocked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
      onPressed: _toggleLock,
    );
  }
}
