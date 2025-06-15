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
- 🐧 [Linux systemd 运行指南](docs/linux-xray-systemd.md)
- 🪟 [Windows 服务运行指南](docs/windows-xray-sc.md)

## 🖼 更新应用图标

使用 `scripts/generate_icons.sh` 可一键生成并替换 Android、iOS、macOS、Linux 与 Windows 平台的应用图标。
依赖 ImageMagick，若未安装请先安装 `convert` 命令。

## 🪟 Windows 构建须知

Windows 平台需要依赖 Go 编译工具生成原生桥接库。请确保在构建前已安装 Go (推荐 1.20 及以上版本) 并将 `go` 命令加入 `PATH` 环境变量，否则 Visual Studio 构建阶段会报错 `MSB8066`。

如遇 `go build` 相关错误，可按照 [Windows 开发环境搭建](docs/windows-build.md) 文档安装 **MinGW-w64**，并在 `go_core` 目录执行

```powershell
go env CGO_ENABLED   # 应输出 1
go build -buildmode=c-archive -o libgo_logic.a
```

成功后会生成 `libgo_logic.a` 与 `libgo_logic.h`，再运行 `flutter build windows` 即可。
