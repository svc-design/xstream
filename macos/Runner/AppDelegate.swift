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
        guard let args = call.arguments as? [String: Any],
              let suffix = args["nodeSuffix"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing node suffix", details: nil))
          return
        }

        let userName = NSUserName()
        let uid = getuid()
        let plistPath = "/Users/\(userName)/Library/LaunchAgents/com.xstream.xray-node-\(suffix).plist"
        let serviceName = "com.xstream.xray-node-\(suffix)"

        switch call.method {
        case "startNodeService":
          let cmd = "launchctl bootstrap gui/\(uid) \"\(plistPath)\""
          self.runShellScript(command: cmd, returnsBool: false, result: result)

        case "stopNodeService":
          let cmd = "launchctl bootout gui/\(uid) \"\(plistPath)\""
          self.runShellScript(command: cmd, returnsBool: false, result: result)

        case "checkNodeStatus":
          let cmd = "launchctl list | grep \"\(serviceName)\""
          self.runShellScript(command: cmd, returnsBool: true, result: result)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  func runShellScript(command: String, returnsBool: Bool, result: @escaping FlutterResult) {
    logToFlutter("info", "🛠️ 运行命令: \(command)")

    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.terminationHandler = { process in
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""

      if returnsBool {
        let found = output.contains("com.xstream")
        self.logToFlutter("info", "🔍 服务状态: \(found ? "运行中 ✅" : "未运行 ❌")")
        result(found)
      } else {
        if process.terminationStatus == 0 {
          self.logToFlutter("info", "✅ 命令执行成功\n\(output)")
          result("success")
        } else {
          self.logToFlutter("error", "❌ 命令执行失败: \(output)")
          result(FlutterError(code: "EXEC_FAILED", message: "Command failed", details: output))
        }
      }
    }

    do {
      try task.run()
    } catch {
      result(FlutterError(code: "EXEC_ERROR", message: "Failed to start process", details: error.localizedDescription))
    }
  }

  func logToFlutter(_ level: String, _ message: String) {
    let fullLog = "[\(level.uppercased())] \(Date()): \(message)"
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let messenger = controller.engine.binaryMessenger
      let loggerChannel = FlutterMethodChannel(name: "com.xstream/logger", binaryMessenger: messenger)
      loggerChannel.invokeMethod("log", arguments: fullLog)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
