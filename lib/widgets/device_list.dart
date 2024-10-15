import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildDeviceTile('341 958 790', 'macbookairmimashimima@macbookdemacbook-air.local', Icons.laptop_mac),
        _buildDeviceTile('37 678 284', 'eric@erics-macbook-pro-2.local', Icons.computer),
        _buildDeviceTile('1 413 347 755', 'android@HUAWEI-ADY-AL00', Icons.android),
      ],
    );
  }

  ListTile _buildDeviceTile(String id, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(id),
      subtitle: Text(description),
      trailing: Icon(Icons.more_vert),
    );
  }
}
