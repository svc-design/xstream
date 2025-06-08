// lib/services/cloud_sync_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;
import 'package:http/http.dart' as http;
import 'package:azblob/azblob.dart';

import '../utils/global_config.dart';
import 'vpn_config_service.dart';

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class CloudSyncService {
  static const MethodChannel _channel = MethodChannel('com.xstream/cloud');
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gdrive.DriveApi.driveFileScope],
  );

  static Future<gdrive.DriveApi?> _driveApi() async {
    final account = await _googleSignIn.signInSilently();
    final headers = await account?.authHeaders;
    if (headers == null) return null;
    final client = _GoogleAuthClient(headers);
    return gdrive.DriveApi(client);
  }

  static Future<void> uploadConfig() async {
    final path = await VpnConfig.getConfigPath();
    final file = File(path);
    if (!await file.exists()) return;

    if (Platform.isIOS || Platform.isMacOS) {
      try {
        await _channel.invokeMethod('uploadToICloud', {'path': path});
      } catch (_) {}
    }

    final drive = await _driveApi();
    if (drive != null) {
      final media = gdrive.Media(file.openRead(), await file.length());
      await drive.files.create(
        gdrive.File()..name = 'vpn_nodes.json',
        uploadMedia: media,
      );
    }

    final conn = Platform.environment['AZURE_STORAGE_CONNECTION_STRING'];
    if (conn != null && conn.isNotEmpty) {
      final storage = AzureStorage.parse(conn);
      await storage.putBlob('/xstream/vpn_nodes.json',
          bodyBytes: await file.readAsBytes(),
          contentType: 'application/json');
    }
  }

  static Future<void> downloadConfig() async {
    final path = await VpnConfig.getConfigPath();
    final file = File(path);

    if (Platform.isIOS || Platform.isMacOS) {
      try {
        final data = await _channel.invokeMethod<String>('downloadFromICloud',
            {'path': path});
        if (data != null) await file.writeAsString(data);
      } catch (_) {}
    }

    final drive = await _driveApi();
    if (drive != null) {
      final list = await drive.files.list(q: "name='vpn_nodes.json'");
      if (list.files?.isNotEmpty == true) {
        final id = list.files!.first.id!;
        final media = await drive.files.get(id,
            downloadOptions: gdrive.DownloadOptions.fullMedia) as gdrive.Media;
        final bytes = await media.stream.toBytes();
        await file.writeAsBytes(bytes);
      }
    }

    final conn = Platform.environment['AZURE_STORAGE_CONNECTION_STRING'];
    if (conn != null && conn.isNotEmpty) {
      final storage = AzureStorage.parse(conn);
      final bytes = await storage.getBlob('/xstream/vpn_nodes.json');
      await file.writeAsBytes(bytes);
    }

    await VpnConfig.load();
  }
}
