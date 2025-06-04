import Foundation
import FlutterMacOS

extension AppDelegate {
  func handleServiceControl(call: FlutterMethodCall, bundleId: String, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let plistName = args?["plistName"] as? String

    let userName = NSUserName()
    let uid = getuid()
    let plistPath = plistName != nil ? "/Users/\(userName)/Library/LaunchAgents/\(plistName!)" : ""
    let serviceName = plistName?.replacingOccurrences(of: ".plist", with: "") ?? ""

    // 检查 macOS 是否为现代版本（>= 10.15）
    let os = ProcessInfo.processInfo.operatingSystemVersion
    let useModernLaunchctl = os.majorVersion >= 11 || (os.majorVersion == 10 && os.minorVersion >= 15)

    switch call.method {
    case "startNodeService":
      if let plistName = plistName {
        let command = useModernLaunchctl
          ? "launchctl bootstrap gui/\(uid) \"\(plistPath)\""
          : "launchctl load \"\(plistPath)\""
        runShellScript(command: command, returnsBool: false, result: result)
      } else {
        startLocalXray(result: result)
      }

    case "stopNodeService":
      if let _ = plistName {
        let command = useModernLaunchctl
          ? "launchctl bootout gui/\(uid) \"\(plistPath)\""
          : "launchctl unload \"\(plistPath)\""
        runShellScript(command: command, returnsBool: false, result: result)
      } else {
        stopLocalXray(result: result)
      }

    case "checkNodeStatus":
      if let _ = plistName {
        let command = useModernLaunchctl
          ? "launchctl print gui/\(uid)/\(serviceName)"
          : "launchctl list | grep \"\(serviceName)\""
        runShellScript(command: command, returnsBool: true, result: result)
      } else {
        result(false)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func runShellScript(command: String, returnsBool: Bool, result: @escaping FlutterResult) {
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    let fileHandle = pipe.fileHandleForReading
    var outputBuffer = ""

    fileHandle.readabilityHandler = { handle in
      if let output = String(data: handle.availableData, encoding: .utf8), !output.isEmpty {
        outputBuffer += output
      }
    }

    task.terminationHandler = { process in
      fileHandle.readabilityHandler = nil
      let found = outputBuffer.contains("xray-node")
      let isSuccess = (process.terminationStatus == 0)

      DispatchQueue.main.async {
        if returnsBool {
          result(found)
        } else if isSuccess {
          result("success")
          self.logToFlutter("info", "命令执行成功: \nCommand: \(command)\nOutput: \(outputBuffer)")
        } else {
          result(FlutterError(code: "EXEC_FAILED", message: "Command failed", details: outputBuffer))
          self.logToFlutter("error", "命令执行失败: \nCommand: \(command)\nOutput: \(outputBuffer)")
        }
      }
    }

    do {
      try task.run()
    } catch {
      result(FlutterError(code: "EXEC_ERROR", message: "Process failed to run", details: error.localizedDescription))
      DispatchQueue.main.async {
        self.logToFlutter("error", "Process failed to run: \(error.localizedDescription)")
      }
    }
  }
}

  private func startLocalXray(result: @escaping FlutterResult) {
    guard let resourcePath = Bundle.main.resourcePath else {
      result("❌ Resource path not found")
      return
    }
    let script = """
    do shell script \"arch=$(uname -m); bin=\\\"\(resourcePath)/xray\\\"; if [ \\\"$arch\\\" = \\\"x86_64\\\" ]; then bin=\\\"\(resourcePath)/xray-x86_64\\\"; fi; chmod +x \\\"$bin\\\"; \\\"$bin\\\" -config \\\"\(resourcePath)/xray-vpn.json\\\" >/tmp/xray.log 2>&1 &; networksetup -listallnetworkservices | tail -n +2 | while read svc; do networksetup -setwebproxy \\\"$svc\\\" 127.0.0.1 1080; networksetup -setsecurewebproxy \\\"$svc\\\" 127.0.0.1 1080; networksetup -setsocksfirewallproxy \\\"$svc\\\" 127.0.0.1 1080; done\" with administrator privileges
    """
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    appleScript?.executeAndReturnError(&error)
    if let error = error {
      result("❌ Xray 启动失败: \(error)")
      logToFlutter("error", "Xray 启动失败: \(error)")
    } else {
      result("✅ Xray 已启动")
      logToFlutter("info", "Xray 已启动")
    }
  }

  private func stopLocalXray(result: @escaping FlutterResult) {
    let script = """
    do shell script \"pkill -f xray-vpn.json || true; networksetup -listallnetworkservices | tail -n +2 | while read svc; do networksetup -setwebproxystate \\\"$svc\\\" off; networksetup -setsecurewebproxystate \\\"$svc\\\" off; networksetup -setsocksfirewallproxystate \\\"$svc\\\" off; done\" with administrator privileges
    """
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    appleScript?.executeAndReturnError(&error)
    if let error = error {
      result("❌ Xray 停止失败: \(error)")
      logToFlutter("error", "Xray 停止失败: \(error)")
    } else {
      result("✅ Xray 已停止")
      logToFlutter("info", "Xray 已停止")
    }
  }
}

