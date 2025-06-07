import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String url;
  final String notes;

  UpdateInfo({required this.version, required this.url, this.notes = ''});
}

class UpdateService {
  static const String updateJsonUrl =
      'https://mirrors-oss.oss-cn-wulanchabu.aliyuncs.com/xstream/update.json';
  static const String baseDownloadUrl =
      'https://mirrors-oss.oss-cn-wulanchabu.aliyuncs.com/xstream';

  static Future<UpdateInfo?> checkUpdate({
    required String currentVersion,
    bool daily = false,
  }) async {
    try {
      final resp = await http.get(Uri.parse(updateJsonUrl));
      if (resp.statusCode != 200) return null;

      final map = jsonDecode(resp.body) as Map<String, dynamic>;

      final latestRaw = map['latest'] as String? ?? '';
      final match = RegExp(r'v?(\d+\.\d+\.\d+)').firstMatch(latestRaw);
      if (match == null) return null;

      final remoteVersion = match.group(1)!;
      if (!_isNewerVersion(currentVersion, remoteVersion)) return null;

      final String notes = map['release_notes'] as String? ?? '';
      final String releaseUrl = map['download_url'] as String? ?? '';
      final String dailyId = map['daily'] as String? ?? '';

      String url = releaseUrl;
      if (daily && dailyId.isNotEmpty) {
        url = '$baseDownloadUrl/$dailyId/xstream-release-$remoteVersion.dmg';
      }

      return UpdateInfo(version: remoteVersion, url: url, notes: notes);
    } catch (_) {
      // ignore errors and return null
    }
    return null;
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

  static Future<void> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
