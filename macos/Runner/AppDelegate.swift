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
        case "startNodeService", "stopNodeService", "checkNodeStatus":
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

        case "performAction":
          guard let args = call.arguments as? [String: Any],
                let action = args["action"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing action", details: nil))
            return
          }

          if action == "initXray" {
            self.runInitXray(result: result)
          } else {
            result(FlutterError(code: "UNKNOWN_ACTION", message: "Unsupported action", details: action))
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  // ✅ 使用 AppleScript 调用 cp 命令（弹出原生授权对话框）
  private func runInitXray(result: @escaping FlutterResult) {
    guard let resourcePath = Bundle.main.resourcePath else {
        result("❌ 无法获取 Resources 路径")
        return
    }

    // 处理路径中的空格和特殊字符
    let escapedPath = resourcePath.replacingOccurrences(of: "'", with: "'\\''")

    // 拼接正确的路径，确保没有空格问题
    let script = """
    do shell script \"
      mkdir -p /opt/homebrew/etc;
      mkdir -p $HOME/Library/LaunchAgents;
      arch=$(uname -m);
      if [ \\\"$arch\\\" = \\\"arm64\\\" ]; then
        cp -f '\(escapedPath)/xray' /opt/homebrew/bin/xray;
        chmod +x /opt/homebrew/bin/xray;
      fi;
      chmod +x /opt/homebrew/bin/xray;
      cp -f '\(escapedPath)/com.xstream.xray-node-ca.plist' $HOME/Library/LaunchAgents/;
      cp -f '\(escapedPath)/com.xstream.xray-node-us.plist' $HOME/Library/LaunchAgents/;
      cp -f '\(escapedPath)/com.xstream.xray-node-tky.plist' $HOME/Library/LaunchAgents/;
      cp -f '\(escapedPath)/xray-vpn.json' /opt/homebrew/etc/
      cp -f '\(escapedPath)/xray-vpn-ca-node.json' /opt/homebrew/etc/
      cp -f '\(escapedPath)/xray-vpn-us-node.json' /opt/homebrew/etc/
      cp -f '\(escapedPath)/xray-vpn-tky-node.json' /opt/homebrew/etc/
    \" with administrator privileges
    """

    // 执行 AppleScript
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    let output = appleScript?.executeAndReturnError(&error)

    if let error = error {
        result("❌ AppleScript 执行失败: \(error)")
    } else {
        result("✅ Xray 初始化完成: \(output?.stringValue ?? "Success")")
    }
  }

  func runShellScript(command: String, returnsBool: Bool, result: @escaping FlutterResult) {
    logToFlutter("info", "🛠️ 执行命令: \(command)")

    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    var outputBuffer = ""
    // ✅ 实时读取输出
    pipe.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      if let output = String(data: data, encoding: .utf8), !output.isEmpty {
        outputBuffer += output
        self.logToFlutter("info", output)
      }
    }

    task.terminationHandler = { process in
      pipe.fileHandleForReading.readabilityHandler = nil // 停止监听

      DispatchQueue.main.async {
        if returnsBool {
          let found = outputBuffer.contains("com.xstream")
          self.logToFlutter("info", "🔍 服务状态: \(found ? "运行中 ✅" : "未运行 ❌")")
          result(found)
        } else {
          if process.terminationStatus == 0 {
            self.logToFlutter("info", "✅ 命令执行成功")
            result("success")
          } else {
            self.logToFlutter("error", "❌ 命令执行失败: \(outputBuffer)")
            result(FlutterError(code: "EXEC_FAILED", message: "Command failed", details: outputBuffer))
          }
        }
      }
    }

    do {
      try task.run()
    } catch {
      result(FlutterError(code: "EXEC_ERROR", message: "Process failed to run", details: error.localizedDescription))
    }
  }

  func logToFlutter(_ level: String, _ message: String) {
    let fullLog = "[\(level.uppercased())] \(Date()): \(message)"
    DispatchQueue.main.async {
      if let controller = self.mainFlutterWindow?.contentViewController as? FlutterViewController {
        let messenger = controller.engine.binaryMessenger
        let loggerChannel = FlutterMethodChannel(name: "com.xstream/logger", binaryMessenger: messenger)
        loggerChannel.invokeMethod("log", arguments: fullLog)
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
