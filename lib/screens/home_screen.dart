import 'package:flutter/material.dart';
import '../../utils/native_bridge.dart';

class HomeScreen extends StatefulWidget {
  final bool isUnlocked;
  final String sudoPassword;

  HomeScreen({Key? key, required this.isUnlocked, required this.sudoPassword}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeNode = '';

  final List<Map<String, String>> vpnNodes = [
    {'name': '🇺🇸 US-VPN', 'protocol': 'VLESS'},
    {'name': '🇨🇦 CA-VPN', 'protocol': 'VMess'},
    {'name': '🇯🇵 Tokyo-VPN', 'protocol': 'Trojan'},
  ];

  void _toggleNode(String nodeName) async {
    if (_activeNode == nodeName) {
      final msg = await NativeBridge.stopXrayService();
      setState(() {
        _activeNode = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      final msg = await NativeBridge.startXrayService();
      setState(() {
        _activeNode = nodeName;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;
        bool isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.windows;

        return isLargeScreen && isDesktop
            ? Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Address: Socks5://127.0.0.1:1080'),
                          SizedBox(height: 8),
                          Text('Latency: N/A'),
                          SizedBox(height: 8),
                          Text('Loss: N/A'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      itemCount: vpnNodes.length,
                      itemBuilder: (context, index) {
                        final node = vpnNodes[index];
                        final isActive = _activeNode == node['name'];
                        return ListTile(
                          title: Text(node['name']!),
                          subtitle: Text('${node['protocol']} | tcp'),
                          trailing: IconButton(
                            icon: Icon(isActive ? Icons.stop_circle : Icons.play_circle_fill,
                                color: isActive ? Colors.red : Colors.green),
                            onPressed: () => _toggleNode(node['name']!),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: vpnNodes.length,
                itemBuilder: (context, index) {
                  final node = vpnNodes[index];
                  final isActive = _activeNode == node['name'];
                  return ListTile(
                    title: Text(node['name']!),
                    subtitle: Text('${node['protocol']} | tcp'),
                    trailing: IconButton(
                      icon: Icon(isActive ? Icons.stop_circle : Icons.play_circle_fill,
                          color: isActive ? Colors.red : Colors.green),
                      onPressed: () => _toggleNode(node['name']!),
                    ),
                  );
                },
              );
      },
    );
  }
}
