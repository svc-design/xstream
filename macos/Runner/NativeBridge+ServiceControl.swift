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

    switch call.method {
    case "startNodeService":
      runShellScript(command: "launchctl bootstrap gui/\(uid) \"\(plistPath)\"", returnsBool: false, result: result)

    case "stopNodeService":
      runShellScript(command: "launchctl bootout gui/\(uid) \"\(plistPath)\"", returnsBool: false, result: result)

    case "checkNodeStatus":
      runShellScript(command: "launchctl list | grep \"\(plistName)\"", returnsBool: true, result: result)

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
