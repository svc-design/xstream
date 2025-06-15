# Windows 开发环境搭建

本指引帮助在 Windows 上完成 XStream 的编译。项目通过 FFI 调用 Go 实现，需安装 Go 以及支持 CGO 的编译器。

## 1. 安装 Go 与 MinGW-w64

1. 安装 [Go](https://go.dev/dl/) 1.20 及以上版本，并确保 `go` 命令在 `PATH` 中。
2. 安装 MinGW-w64 工具链，可在 PowerShell 中执行：
   ```powershell
   winget install -e --id MSYS2.MSYS2
   pacman -Syu mingw-w64-x86_64-gcc
   ```
   安装完成后，确认 `gcc --version` 能正确输出版本信息。

## 2. 生成 FFI 库

桌面端的原生逻辑位于 `go_core/` 目录，并通过 FFI 与 Flutter 通信。仓库提供脚本帮助
在 Windows 下生成 `libbridge.dll`：

```powershell
./build_scripts/build_windows.sh
```

执行后可在 `bindings/` 目录找到生成的 DLL，Flutter 构建会自动将其打包。

## 3. 构建 Flutter 桌面应用

```
flutter clean
flutter pub get
flutter build windows
```

若脚本执行成功，Flutter 构建过程会自动将生成的 DLL 打包至应用目录。

## 4. 调试模式

构建完成后，可在 `build/windows/x64/runner/Release` 目录下通过命令行运行

```powershell
./xstream.exe --debug
```

加入 `--debug` 参数会在控制台输出启动日志，便于排查依赖路径或权限问题。

## 5. Release Packaging

GitHub Actions will compress the entire `build/windows/x64/runner/Release`
directory into `xstream-windows.zip` for distribution. The archive includes
`flutter_windows.dll` so the application can run on systems without Flutter
installed.
