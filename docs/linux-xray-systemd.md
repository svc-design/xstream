# 在 Linux 上使用 systemd 运行 Xray

本文档说明如何在 Linux 桌面环境中通过 systemd 管理 Xray 进程。示例使用用户级服务，可避免修改全局配置。

## 准备

1. 安装 Xray 可执行文件。项目提供的 `InitXray` 方法会将二进制复制到 `~/.local/bin/xray` 并赋予执行权限。
2. 确保 `~/.local/bin` 已加入 `PATH`，或在 service 文件中填写完整路径。

## 创建服务文件

在 `~/.config/systemd/user` 目录下创建 `xray.service`：

```ini
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=%h/.local/bin/xray run -c %h/.config/xray/xray-config.json
Restart=on-failure

[Install]
WantedBy=default.target
```

## 启动与管理

```bash
systemctl --user daemon-reload      # 重新加载用户级服务
systemctl --user enable xray.service
systemctl --user start xray.service
```

查看运行状态：

```bash
systemctl --user status xray.service
```

停止服务：

```bash
systemctl --user stop xray.service
```

## 参考

如果希望在系统级别运行，可将 `xray.service` 放置在 `/etc/systemd/system` 并去掉 `%h` 前缀，同时使用 `sudo systemctl` 管理。
