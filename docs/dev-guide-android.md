# 开发者构建指南（Android）

本指南适用于希望在 Android 环境下本地构建和调试 XStream 项目的开发者。

## 环境准备

1. **安装 Flutter**
   - 参考官方安装文档：<https://docs.flutter.dev/get-started/install>

2. **安装 Android Studio**
   - 下载并安装最新版本 Android Studio（包含 Android SDK 和 Emulator）
   - 在 *SDK Manager* 中确保安装了 Android SDK Platform 33 及以下版本

3. **配置环境变量**
   - 设置 `ANDROID_HOME` 指向 Android SDK 路径
   - 将 `platform-tools` 目录加入 `PATH`

4. **拉取依赖**
   ```bash
   flutter pub get
   ```

5. **准备设备**
   - 使用 Android Studio 的 Device Manager 创建模拟器
   - 或启用 USB 调试并连接真机

## 构建与调试

在连接的设备或模拟器上运行：

```bash
flutter run -d android
```

也可在 Android Studio 或 VS Code 中点击调试按钮。

## 常见问题

- 报错 `license for package Android SDK` 未接受：执行 `flutter doctor --android-licenses` 并全部接受
- 设备无法识别：确认已开启 USB 调试，必要时安装对应驱动程序
