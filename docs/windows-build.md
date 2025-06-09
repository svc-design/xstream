# Windows 开发环境搭建

本指引帮助在 Windows 上完成 XStream 的编译。依赖 Go 用于生成桥接库，并需要安装编译器以支持 CGO。

## 1. 安装 Go 与 MinGW-w64

1. 安装 [Go](https://go.dev/dl/) 1.20 及以上版本，并确保 `go` 命令在 `PATH` 中。
2. 安装 MinGW-w64 工具链，可在 PowerShell 中执行：
   ```powershell
   winget install -e --id MSYS2.MSYS2
   pacman -Syu mingw-w64-x86_64-gcc
   ```
   安装完成后，确认 `gcc --version` 能正确输出版本信息。

## 2. 生成 Go 静态库

进入项目的 `windows/go` 目录，执行：

```powershell
cd windows/go
# 确认 CGO 已启用
go env CGO_ENABLED
```

若输出不是 `1`，可在当前终端设置并重新构建：

```powershell
$env:CGO_ENABLED="1"
```

随后执行构建：

```powershell
go build -buildmode=c-archive -o libgo_logic.a
```

成功后会在该目录生成 `libgo_logic.a` 与 `libgo_logic.h`，供 CMake 链接。

## 3. 构建 Flutter 桌面应用

```
flutter clean
flutter pub get
flutter build windows
```

若环境配置正确，CMake 会在构建过程中自动调用以上 Go 命令生成桥接库。
