# Windows 构建指南

本项目通过 Go 和 Dart FFI 在 Windows 上实现核心功能。构建前需要先编译提供给 Flutter 的 DLL。

## 1. 安装依赖

1. 安装 [Go](https://go.dev/dl/) 1.20+ 并确保 `go` 在 `PATH` 中。
2. 安装 [Flutter](https://docs.flutter.dev/get-started/install/windows) SDK。

## 2. 编译桥接库

执行脚本 `build_scripts/build_windows.sh` 在 `bindings/` 目录下生成 `libbridge.dll`：

```bash
./build_scripts/build_windows.sh
生成的 DLL 会被 Dart 通过 `DynamicLibrary.open` 加载。
## 3. 构建 Flutter 应用

在完成 DLL 构建后，运行：
```bash
flutter build windows --release
生成的应用位于 `build/windows/x64/runner/Release/`。
```

加入 `--debug` 参数会在控制台输出启动日志，便于排查依赖路径或权限问题。

## 6. Release Packaging

GitHub Actions will compress the entire `build/windows/x64/runner/Release`
directory into `xstream-windows.zip` for distribution. The archive includes
`flutter_windows.dll` so the application can run on systems without Flutter
installed.
