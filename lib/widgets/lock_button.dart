import 'package:flutter/material.dart';

class LockButton extends StatefulWidget {
  final Function(String)? onUnlock; // Callback to pass the password to another component

  const LockButton({Key? key, this.onUnlock}) : super(key: key);

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

  void _attemptUnlock(String password) {
    // Call the provided callback function with the password
    if (widget.onUnlock != null) {
      widget.onUnlock!(password);
    }

    setState(() {
      _isLocked = false; // Assume unlock is successful for now
    });
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
