# macOS 沙盒与权限提升流程

当应用启用 `com.apple.security.app-sandbox` 后，无法直接执行需要管理员权限的脚本。
本项目通过安装一个受信任的 Helper Tool 以 root 身份执行命令，整体调用顺序如下：

```text
[Flutter UI]
   ↓
[Dart MethodChannel]
   ↓
[AppDelegate.swift]
   ├── AuthorizationCreate() → 系统弹窗授权
   ├── SMJobBless() → 安装 helper
   └── NSXPCConnection → 调用 helper
       ↓
[HelperTool (root)]
   └── 执行 shell 命令并返回结果
       ↓
[Flutter 显示执行反馈]
```

`AppDelegate` 在启动时首先通过 `AuthorizationCreate` 请求管理员授权，
然后使用 `SMJobBless` 将 Helper Tool 安装到系统。安装完成后，
使用 `NSXPCConnection` 与 Helper 建立通信，通过 `HelperToolProtocol`
发送需要执行的命令，并将结果回传给 Flutter 层。

此流程可满足沙盒环境下仍需执行系统级操作的场景，
符合 App Store 的安全要求。

