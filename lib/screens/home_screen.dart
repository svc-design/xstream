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

  // VPN 节点配置列表，使用简化的 nodeName 映射（用于 plist 拼接）
  final List<Map<String, String>> vpnNodes = [
    {'name': 'US-VPN', 'label': '🇺🇸 US-VPN', 'protocol': 'VLESS'},
    {'name': 'CA-VPN', 'label': '🇨🇦 CA-VPN', 'protocol': 'VMess'},
    {'name': 'Tokyo-VPN', 'label': '🇯🇵 Tokyo-VPN', 'protocol': 'Trojan'},
  ];

  Future<void> _toggleNode(Map<String, String> node) async {
    final nodeName = node['name']!;

    if (_activeNode == nodeName) {
      // 停止当前节点
      final msg = await NativeBridge.stopNodeService(nodeName);
      setState(() => _activeNode = '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      // 停止旧节点（如有）
      if (_activeNode.isNotEmpty) {
        await NativeBridge.stopNodeService(_activeNode);
      }
      // 启动新节点
      final msg = await NativeBridge.startNodeService(nodeName);
      setState(() => _activeNode = nodeName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _buildVpnListView() {
    return ListView.builder(
      itemCount: vpnNodes.length,
      itemBuilder: (context, index) {
        final node = vpnNodes[index];
        final isActive = _activeNode == node['name'];
        return ListTile(
          title: Text(node['label']!),
          subtitle: Text('${node['protocol']} | tcp'),
          trailing: IconButton(
            icon: Icon(
              isActive ? Icons.stop_circle : Icons.play_circle_fill,
              color: isActive ? Colors.red : Colors.green,
            ),
            onPressed: widget.isUnlocked ? () => _toggleNode(node) : null,
          ),
        );
      },
    );
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
                  // 左侧：状态区域
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
                  // 右侧：VPN 节点列表
                  Expanded(flex: 2, child: _buildVpnListView()),
                ],
              )
            : _buildVpnListView();
      },
    );
  }
}
