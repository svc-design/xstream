// lib/services/update/update_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/update_info.dart';
import '../../utils/global_config.dart';

class UpdateService {
  static const String baseUrl = kUpdateBaseUrl; // ⚙️ 配置在 global_config.dart 中

  static Future<UpdateInfo?> checkUpdate({
    required String repoUrl,
    required String currentVersion,
  }) async {
    try {
      final indexUrl = '$repoUrl/index.json'; // ⬅️ 建议服务器提供这个 JSON 索引
      final response = await http.get(Uri.parse(indexUrl));
      if (response.statusCode != 200) return null;

      final list = jsonDecode(response.body) as List;
      final fileEntry = list.firstWhere(
        (e) => _isNewerVersion(currentVersion, e['version']),
        orElse: () => null,
      );

      if (fileEntry == null) return null;

      return UpdateInfo(
        version: fileEntry['version'],
        url: '$repoUrl${fileEntry['filename']}',
        notes: fileEntry['notes'] ?? '发现新版本 ${fileEntry['version']}',
      );
    } catch (_) {
      return null;
    }
  }

  static bool _isNewerVersion(String local, String remote) {
    final l = local.split('.').map(int.parse).toList();
    final r = remote.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }
}
