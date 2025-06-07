import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String url;
  UpdateInfo({required this.version, required this.url});
}

class UpdateService {
  static const String releaseUrl =
      'https://mirrors-oss.oss-cn-wulanchabu.aliyuncs.com/xstream-release-v0.1.0.dmg';
  static const String dailyUrl =
      'https://mirrors-oss.oss-cn-wulanchabu.aliyuncs.com/xstream-daily-latest.dmg';

  static Future<UpdateInfo?> checkUpdate({
    required String currentVersion,
    bool daily = false,
  }) async {
    final url = daily ? dailyUrl : releaseUrl;
    final match = RegExp(r'v(\d+\.\d+\.\d+)').firstMatch(url);
    if (match == null) return null;
    final remoteVersion = match.group(1)!;
    if (_isNewerVersion(currentVersion, remoteVersion)) {
      final available = await _urlExists(url);
      if (available) {
        return UpdateInfo(version: remoteVersion, url: url);
      }
    }
    return null;
  }

  static Future<bool> _urlExists(String url) async {
    try {
      final resp = await http.head(Uri.parse(url));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
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

  static Future<void> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
