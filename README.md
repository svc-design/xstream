# XStream

A Cutting-Edge Network Accelerator Powered by XTLS VLESS

XStream 是一个强大的网络加速工具，旨在提升您的在线体验。利用 XTLS VLESS 的先进功能，XStream 优化您的互联网连接，提供更快的速度和更可靠的访问，助您畅享流媒体、跨境电商以及 GitHub 等在线服务，确保流畅的性能和最低的延迟。

通过 XStream 用户友好的界面，您可以轻松管理连接和设置。在享受更快互联网的同时，保持安全和匿名，无论您身处何地，XStream 都能为您提供无缝的连接体验。选择 XStream，提升您的浏览体验，让您保持连接、安全和高效。

## 支持的平台

XStream 支持以下平台：

- **Linux**
  - x64
  - arm64
- **Windows**
  - x64
- **macOS**
  - x64
  - arm64
- **Android**
  - arm64
- **iOS**
  - arm64

## 安装和运行

1. 确保您已安装 [Flutter SDK](https://flutter.dev/docs/get-started/install)。
2. 克隆或下载该项目到本地目录。
3. 在终端中，导航到项目目录，然后运行以下命令以创建项目：

flutter create .
flutter pub get
flutter run

# 在 macOS 下构建开发环境

要在 macOS 上构建和开发 XStream，请按照以下步骤操作：
1. 首先，确保您已经安装了 Flutter。可以通过 Homebrew 安装 Flutter`
    brew install --cask flutter
2. 安装 Xcode: 下载并安装 Xcode，通过 App Store 或访问 Xcode 下载页面。
3. 配置 Xcode: 安装 Xcode 后，运行以下命令来配置开发工具：
    sudo xcodebuild -runFirstLaunch
确保您已安装 Xcode 的命令行工具。
4. 安装 CocoaPods: CocoaPods 是一个用于 iOS 和 macOS 的依赖管理工具。您可以通过以下命令安装 CocoaPods：
    sudo gem install cocoapods
5. 安装 Flutter 依赖: 在终端中，进入到 XStream 项目的根目录，并运行以下命令以获取 Flutter 依赖：
    flutter pub get
6. 构建项目: 在项目根目录下，使用以下命令构建项目：
    flutter build <platform>
将 <platform> 替换为您要构建的平台，例如 macos、ios 或 android。
7. 编辑构建
如果需要编辑项目文件，请打开您喜欢的文本编辑器或 IDE（如 Visual Studio Code 或 Android Studio），并根据需要进行修改。完成后，使用以下命令重新构建项目：
    flutter build <platform>
其他资源
有关 Flutter 开发的更多帮助，请查看 在线文档，该文档提供了教程、示例、移动开发的指导以及完整的 API 参考。


# 更新说明
- 添加了在 macOS 下构建开发环境的步骤，包括安装 Flutter、Xcode、CocoaPods 以及构建项目的命令。
- 提供了更详细的指导，方便开发者顺利进行项目构建与开发。
