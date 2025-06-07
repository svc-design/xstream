import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/global_config.dart';
import '../../utils/native_bridge.dart';
import '../../services/vpn_config_service.dart';
import '../../services/update_service.dart';
import '../widgets/log_console.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'log';
  static const platform = MethodChannel('com.xstream/native');

  static const TextStyle _menuTextStyle = TextStyle(fontSize: 14);
  static final ButtonStyle _menuButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(36),
    textStyle: _menuTextStyle,
  );

  String _buildVersion() {
    const branch = String.fromEnvironment('BRANCH_NAME', defaultValue: '');
    const buildId = String.fromEnvironment('BUILD_ID', defaultValue: 'local');
    const buildDate = String.fromEnvironment('BUILD_DATE', defaultValue: 'unknown');

    if (branch.startsWith('release/')) {
      final version = branch.replaceFirst('release/', '');
      return 'v$version-$buildDate-$buildId';
    }
    if (branch == 'main') {
      return 'latest-$buildDate-$buildId';
    }
    return 'dev-$buildDate-$buildId';
  }

  String _currentVersion() {
    final match = RegExp(r'v(\d+\.\d+\.\d+)').firstMatch(_buildVersion());
    return match?.group(1) ?? '0.0.0';
  }

  void _onGenerateDefaultNodes() async {
    final isUnlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以执行生成操作', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始生成默认节点...');
    await VpnConfig.generateDefaultNodes(
      password: password,
      platform: platform,
      setMessage: (msg) => logConsoleKey.currentState?.addLog(msg),
      logMessage: (msg) => logConsoleKey.currentState?.addLog(msg),
    );
  }

  void _onInitXray() async {
    final isUnlocked = GlobalState.isUnlocked.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以初始化 Xray', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始初始化 Xray...');
    try {
      final output = await NativeBridge.initXray();
      logConsoleKey.currentState?.addLog(output);
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] $e', level: LogLevel.error);
    }
  }

  void _onResetAll() async {
    final isUnlocked = GlobalState.isUnlocked.value;
    final password = GlobalState.sudoPassword.value;

    if (!isUnlocked) {
      logConsoleKey.currentState?.addLog('请先解锁以执行重置操作', level: LogLevel.warning);
      return;
    }

    logConsoleKey.currentState?.addLog('开始重置配置与文件...');
    try {
      final result = await NativeBridge.resetXrayAndConfig(password);
      logConsoleKey.currentState?.addLog(result);
    } catch (e) {
      logConsoleKey.currentState?.addLog('[错误] 重置失败: $e', level: LogLevel.error);
    }
  }

  void _onCheckUpdate() async {
    logConsoleKey.currentState?.addLog('开始检查更新...');
    final info = await UpdateService.checkUpdate(
      currentVersion: _currentVersion(),
      daily: GlobalState.useDailyBuild.value,
    );
    if (!mounted) return;
    if (info != null) {
      logConsoleKey.currentState?.addLog('发现新版本 ${info.version}');
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('发现新版本 ${info.version}'),
          content: Text(info.notes.isNotEmpty ? info.notes : '是否前往下载?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('下载'),
            ),
          ],
        ),
      );
      if (go == true) {
        await UpdateService.launchDownload(info.url);
      }
    } else {
      logConsoleKey.currentState?.addLog('已是最新版本');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已是最新版本')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧菜单栏
        Container(
          width: 220,
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '⚙️ 设置中心',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: GlobalState.isUnlocked,
                  builder: (context, isUnlocked, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: _menuButtonStyle,
                            icon: const Icon(Icons.build),
                            label: const Text('初始化 Xray', style: _menuTextStyle),
                            onPressed: isUnlocked ? _onInitXray : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: _menuButtonStyle,
                            icon: const Icon(Icons.settings),
                            label: const Text('生成默认节点', style: _menuTextStyle),
                            onPressed: isUnlocked ? _onGenerateDefaultNodes : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: _menuButtonStyle.copyWith(
                              backgroundColor: MaterialStateProperty.all(Colors.red[400]),
                            ),
                            icon: const Icon(Icons.restore),
                            label: const Text('重置所有配置', style: _menuTextStyle),
                            onPressed: isUnlocked ? _onResetAll : null,
                          ),
                        ),
                        if (!isUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              '请先解锁以执行初始化操作',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('📜 查看日志', style: _menuTextStyle),
                selected: _selectedTab == 'log',
                onTap: () {
                  setState(() {
                    _selectedTab = 'log';
                  });
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.bolt),
                title: const Text('升级 DailyBuild', style: _menuTextStyle),
                value: GlobalState.useDailyBuild.value,
                onChanged: (v) => setState(() => GlobalState.useDailyBuild.value = v),
              ),
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('检查更新', style: _menuTextStyle),
                onTap: _onCheckUpdate,
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('帮助', style: _menuTextStyle),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('关于', style: _menuTextStyle),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'XStream',
                    applicationVersion: _buildVersion(),
                    applicationLegalese: '© 2025 svc.plus – Based on Xray-core 25.3.6\n\n'
                        'This software includes unmodified components from the Xray-core project,\n'
                        'licensed under the GNU General Public License v3.0.\n\n'
                        'Xray-core (c) XTLS Authors – https://github.com/XTLS/Xray-core',
                    children: const [
                      Text('XStream 是一个多节点代理配置管理工具。\n'
                          '本软件基于 Flutter 构建，支持 macOS/iOS 等平台。'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // 右侧日志输出面板
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _selectedTab == 'log'
                ? LogConsole(key: logConsoleKey)
                : const Center(child: Text('请选择左侧菜单')),
          ),
        ),
      ],
    );
  }
}
