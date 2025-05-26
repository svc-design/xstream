import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {

      let channel = FlutterMethodChannel(
        name: "com.xstream/native",
        binaryMessenger: controller.engine.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {

        case "startNodeService":
          if let args = call.arguments as? [String: Any],
             let nodeName = args["node"] as? String {
            let safeName = nodeName.lowercased().replacingOccurrences(of: "-", with: "_")
            let plistPath = "/Users/\(NSUserName())/Library/LaunchAgents/com.xstream.xray-node-\(safeName).plist"
            let cmd = "launchctl load \(plistPath)"
            self.runWithPrivileges(command: cmd)
            result("✅ 节点 \(nodeName) 启动完成")
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing node name", details: nil))
          }

        case "stopNodeService":
          if let args = call.arguments as? [String: Any],
             let nodeName = args["node"] as? String {
            let safeName = nodeName.lowercased().replacingOccurrences(of: "-", with: "_")
            let plistPath = "/Users/\(NSUserName())/Library/LaunchAgents/com.xstream.xray-node-\(safeName).plist"
            let cmd = "launchctl unload \(plistPath)"
            self.runWithPrivileges(command: cmd)
            result("🛑 节点 \(nodeName) 已停止")
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing node name", details: nil))
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  /// 使用 AppleScript 执行带管理员权限的 shell 命令
  func runWithPrivileges(command: String) {
    let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
    let script = """
    do shell script "\(escapedCommand)" with administrator privileges
    """
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)
    if let err = error {
      print("🚨 命令执行失败: \(err)")
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
