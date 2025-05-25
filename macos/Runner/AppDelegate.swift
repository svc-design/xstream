import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {

      let channel = FlutterMethodChannel(name: "com.xstream/native",
                                         binaryMessenger: controller.engine.binaryMessenger)

      channel.setMethodCallHandler { call, result in
        switch call.method {

        case "startNodeService":
          if let args = call.arguments as? [String: Any],
             let configPath = args["config"] as? String,
             let nodeName = args["node"] as? String {
            let safeName = nodeName.lowercased().replacingOccurrences(of: "-", with: "_")
            let logPath = "/tmp/xray-vpn-\(safeName)-log"
            let cmd = "nohup /opt/homebrew/bin/xray run -c \(configPath) &> \(logPath) &"
            self.runWithPrivileges(command: cmd)
            result("已启动 \(nodeName)")
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing config or node", details: nil))
          }

        case "stopXrayService":
          self.runWithPrivileges(command: "pkill -f '/opt/homebrew/bin/xray run'")
          result("所有节点已停止")

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  /// 使用 AppleScript 以管理员权限运行 shell 命令
  func runWithPrivileges(command: String) {
    let script = "do shell script \"\(command.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)
    if let err = error {
      print("执行失败: \(err)")
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
