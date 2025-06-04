# 开发者构建指南（Windows）

本指南帮助您在 Windows 7/10/11 上构建和调试 XStream 项目。

## 环境准备

1. 安装 [Flutter](https://docs.flutter.dev/get-started/install/windows) 并配置环境变量。
2. 安装最新的 [Visual Studio](https://visualstudio.microsoft.com/) ，确保包含 "Desktop development with C++" 工作负载。

## 构建步骤

```powershell
flutter pub get
flutter build windows --release
```

构建完成后，可在 `build\windows\runner\Release` 目录找到可执行文件。
