import 'package:flutter/material.dart';
import '../../utils/native_bridge.dart';
import '../../utils/global_state.dart';
import '../../models/vpn_node.dart';
import '../../utils/vpn_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeNode = '';
  List<VpnNode> vpnNodes = [];

  @override
  void initState() {
    super.initState();
    _loadNodes(); // 不再重新 load，只从已缓存的数据读取
  }

  Future<void> _loadNodes() async {
    setState(() {
      vpnNodes = VpnConfigManager.nodes;
    });
  }

  Future<void> _toggleNode(VpnNode node) async {
    final nodeName = node.name;
    if (_activeNode == nodeName) {
      final msg = await NativeBridge.stopNodeService(nodeName);
      setState(() => _activeNode = '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      if (_activeNode.isNotEmpty) {
        await NativeBridge.stopNodeService(_activeNode);
      }
      final msg = await NativeBridge.startNodeService(nodeName);
      setState(() => _activeNode = nodeName);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobalState.isUnlocked,
      builder: (context, isUnlocked, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isLargeScreen = constraints.maxWidth > 600;
            bool isDesktop = Theme.of(context).platform == TargetPlatform.macOS ||
                Theme.of(context).platform == TargetPlatform.linux ||
                Theme.of(context).platform == TargetPlatform.windows;

            final content = ListView.builder(
              itemCount: vpnNodes.length,
              itemBuilder: (context, index) {
                final node = vpnNodes[index];
                final isActive = _activeNode == node.name;
                return ListTile(
                  title: Text('${node.countryCode.toUpperCase()} | ${node.name}'),
                  subtitle: Text('VLESS | tcp'),
                  trailing: IconButton(
                    icon: Icon(
                      isActive ? Icons.stop_circle : Icons.play_circle_fill,
                      color: isActive ? Colors.red : Colors.green,
                    ),
                    onPressed: isUnlocked ? () => _toggleNode(node) : null,
                  ),
                );
              },
            );

            return isLargeScreen && isDesktop
                ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.grey[200],
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
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
                      Expanded(flex: 2, child: content),
                    ],
                  )
                : content;
          },
        );
      },
    );
  }
}
