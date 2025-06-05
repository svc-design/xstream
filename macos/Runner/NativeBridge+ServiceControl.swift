import Foundation
import FlutterMacOS

extension AppDelegate {
  func handleServiceControl(call: FlutterMethodCall, bundleId: String, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let plistName = args["plistName"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing plistName", details: nil))
      return
    }

    let userName = NSUserName()
    let uid = getuid()
    let plistPath = "/Users/\(userName)/Library/LaunchAgents/\(plistName)"
    let serviceName = plistName.replacingOccurrences(of: ".plist", with: "")

    // 检查 macOS 是否为现代版本（>= 10.15）
    let os = ProcessInfo.processInfo.operatingSystemVersion
    let useModernLaunchctl = os.majorVersion >= 11 || (os.majorVersion == 10 && os.minorVersion >= 15)

    switch call.method {
    case "startNodeService":
      let command = useModernLaunchctl
        ? "launchctl bootstrap gui/\(uid) \"\(plistPath)\""
        : "launchctl load \"\(plistPath)\""
      runShellScript(command: command, returnsBool: false, result: result)

    case "stopNodeService":
      let command = useModernLaunchctl
        ? "launchctl bootout gui/\(uid) \"\(plistPath)\""
        : "launchctl unload \"\(plistPath)\""
      runShellScript(command: command, returnsBool: false, result: result)

    case "checkNodeStatus":
      let command = useModernLaunchctl
        ? "launchctl print gui/\(uid)/\(serviceName)"
        : "launchctl list | grep \"\(serviceName)\""
      runShellScript(command: command, returnsBool: true, result: result)

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

    do {
      try task.run()
      task.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8) ?? ""
      let found = output.contains("xray-node")
      let isSuccess = (task.terminationStatus == 0)

      if returnsBool {
        result(found)
      } else if isSuccess {
        result("success")
        self.logToFlutter("info", "命令执行成功: \nCommand: \(command)\nOutput: \(output)")
      } else {
        result(FlutterError(code: "EXEC_FAILED", message: "Command failed", details: output))
        self.logToFlutter("error", "命令执行失败: \nCommand: \(command)\nOutput: \(output)")
      }
    } catch {
      result(FlutterError(code: "EXEC_ERROR", message: "Process failed to run", details: error.localizedDescription))
      self.logToFlutter("error", "Process failed to run: \(error.localizedDescription)")
    }
  }
}
