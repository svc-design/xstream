# XStream v0.1.0 - First Public Preview

_Release Date: 2025-06-06_

## ✨ Features

- 🎯 **Cross-platform network acceleration engine powered by XTLS / VLESS**
- 💻 macOS native integration via Swift + LaunchAgent + Xray
- 🛠️ Integrated `xray` binaries for both `arm64` and `x86_64` architectures
- 📂 Per-user config persistence in `ApplicationSupport` directory
- 📡 Built-in Flutter UI for node selection and management
- 📤 One-click sync to write config and generate launchd service

## ✅ Changes

- Migrated `xray` binaries into `macos/Resources/xray/` (unified resource location)
- Implemented Swift-side logic to:
  - Detect platform architecture (`arm64` / `x86_64`)
  - Copy correct binary into `/opt/homebrew/bin/xray`
  - Set execution permissions
- Added `url_launcher` plugin support with macOS integration (`url_launcher_macos`)
- Simplified `project.pbxproj` to remove unused `inputPaths` / `outputPaths`
- Removed old `macos/xray/` location and binaries

## 🔧 Dev & Build

- Updated `Makefile` to support both `arm64` and `x86_64` macOS targets
- Rebuilt `Podfile.lock` to include new plugins (`url_launcher_macos`)
- Optimized Swift AppleScript command formatting for stability and shell-escaping
- Code cleanup and refactor in `NativeBridge+XrayInit.swift`

## 🧪 Known Limitations

- Current version supports only **basic node config** – advanced Xray routing not yet exposed
- No system tray or background daemon control UI yet
- Tested only on macOS 12+ (Apple Silicon and Intel)

## 🔜 Roadmap

- [ ] GUI for custom route / rule editing
- [ ] Windows and Linux GUI support
- [ ] Built-in diagnostics and log viewer
