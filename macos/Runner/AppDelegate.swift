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
            let safeName = nodeName.lowercased()
              .replacingOccurrences(of: "-", with: "_")
              .replacingOccurrences(of: "_vpn", with: "")
            let userName = NSUserName()
            let plistPath = "/Users/\(userName)/Library/LaunchAgents/com.xstream.xray-node-\(safeName).plist"
            let cmd = "launchctl load \"\(plistPath)\""
            self.runWithPrivileges(command: cmd)
            result("✅ 节点 \(nodeName) 启动完成")
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing node name", details: nil))
          }

        case "stopNodeService":
          if let args = call.arguments as? [String: Any],
             let nodeName = args["node"] as? String {
            let safeName = nodeName.lowercased()
              .replacingOccurrences(of: "-", with: "_")
              .replacingOccurrences(of: "_vpn", with: "")
            let userName = NSUserName()
            let plistPath = "/Users/\(userName)/Library/LaunchAgents/com.xstream.xray-node-\(safeName).plist"
            let cmd = "launchctl unload \"\(plistPath)\""
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

  func runWithPrivileges(command: String) {
    logToFlutter("info", "🛠️ 运行命令: \(command)")
    let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
    let script = "do shell script \"\(escapedCommand)\" with administrator privileges"
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    let result = appleScript?.executeAndReturnError(&error)
    if let err = error {
      logToFlutter("error", "❌ 执行失败: \(err)")
      print("🚨 命令执行失败: \(err)")
    } else {
      logToFlutter("info", "✅ 命令执行成功")
    }
  }

  func logToFlutter(_ level: String, _ message: String) {
    let fullLog = "[\(level.uppercased())] \(Date()): \(message)"
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let messenger = controller.engine.binaryMessenger
      let eventChannel = FlutterMethodChannel(name: "com.xstream/logger", binaryMessenger: messenger)
      eventChannel.invokeMethod("log", arguments: fullLog)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
