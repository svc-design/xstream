# XStream

<p align="center">
  <img src="assets/logo.png" alt="Project Logo" width="200"/>
</p>

**XStream** 是一个用户友好的图形化客户端，用于便捷管理 Xray-core 多节点连接配置，优化网络体验，助您畅享流媒体、跨境电商与开发者服务（如 GitHub）。

---

## ✨ 功能亮点

- 多节点支持，快速切换
- 实时日志输出与故障诊断
- 支持 macOS 权限验证与服务管理
- 解耦式界面设计，支持跨平台构建

---

## 📦 支持平台

| 平台     | 架构     | 测试状态   |
|----------|----------|------------|
| macOS    | arm64    | ✅ 已测试   |
| macOS    | x64      | ⚠️ 未测试   |
| Linux    | x64      | ⚠️ 未测试   |
| Linux    | arm64    | ⚠️ 未测试   |
| Windows  | x64      | ⚠️ 未测试   |
| Android  | arm64    | ⚠️ 未测试   |
| iOS      | arm64    | ⚠️ 未测试   |

---


## 🚀 快速开始

请根据使用身份选择：

- 📘 [用户使用手册](docs/user-manual.md)
- 🛠️ [开发者文档（macOS 开发环境搭建）](docs/dev-guide.md)

## 🛡 App Store 策略

Release 构建已默认启用 macOS 沙盒（`com.apple.security.app-sandbox`），
满足 App Store 上架要求。如需自行构建请确认 `macos/Runner/Release.entitlements`
中的该项已设置为 `true`。

## 🖼 更新应用图标

使用 `scripts/generate_icons.sh` 可一键生成并替换 Android、iOS、macOS、Linux 与 Windows 平台的应用图标。
依赖 ImageMagick，若未安装请先安装 `convert` 命令。
