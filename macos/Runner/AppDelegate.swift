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
        case "startXrayService":
          self.runWithPrivileges(command: "nohup /opt/homebrew/bin/xray run -c /opt/homebrew/etc/xray-vpn.json &> /tmp/xray-vpn-log &")
          result("启动命令已执行")
        case "stopXrayService":
          self.runWithPrivileges(command: "pkill -f '/opt/homebrew/bin/xray run'")
          result("停止命令已执行")
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
