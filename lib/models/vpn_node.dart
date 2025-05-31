class VpnNode {
  String name;
  String countryCode;
  String configPath;
  String plistName;
  String server;
  int port;
  String uuid;
  bool enabled;

  VpnNode({
    required this.name,
    required this.countryCode,
    required this.configPath,
    required this.plistName,
    required this.server,
    required this.port,
    required this.uuid,
    this.enabled = true,
  });

  factory VpnNode.fromJson(Map<String, dynamic> json) => VpnNode(
        name: json['name'],
        countryCode: json['countryCode'],
        configPath: json['configPath'],
        plistName: json['plistName'],
        server: json['server'],
        port: json['port'],
        uuid: json['uuid'],
        enabled: json['enabled'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'countryCode': countryCode,
        'configPath': configPath,
        'plistName': plistName,
        'server': server,
        'port': port,
        'uuid': uuid,
        'enabled': enabled,
      };
}
