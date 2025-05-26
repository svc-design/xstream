/// VPN 节点对应的 Xray 配置文件路径
final Map<String, String> vpnConfigMap = {
  'US-VPN': '/opt/homebrew/etc/xray-vpn-us-node.json',
  'CA-VPN': '/opt/homebrew/etc/xray-vpn-ca-node.json',
  'Tokyo-VPN': '/opt/homebrew/etc/xray-vpn-tky-node.json',
};

/// VPN 节点对应的 macOS LaunchAgent plist 文件名后缀（不含完整路径）
final Map<String, String> vpnPlistNameMap = {
  'US-VPN': 'us',
  'CA-VPN': 'ca',
  'Tokyo-VPN': 'tky',
};

