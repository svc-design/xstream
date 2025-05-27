import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.xstream/native",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "SELF_IS_NIL", message: "Internal error", details: nil))
        return
      }

      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Arguments not a dictionary", details: nil))
        return
      }

      guard let suffix = args["nodeSuffix"] as? String,
            let sudoPassword = args["sudoPassword"] as? String,
            !suffix.isEmpty, !sudoPassword.isEmpty else {
        result(FlutterError(code: "INVALID_VALUES", message: "Missing or empty nodeSuffix/sudoPassword", details: args))
        return
      }

      let plistPath = "\(NSHomeDirectory())/Library/LaunchAgents/com.xstream.xray-node-\(suffix).plist"
      let uid = getuid()
      let safePath = plistPath.replacingOccurrences(of: "\"", with: "\\\"")  // 防止路径中包含引号

      switch call.method {
      case "startNodeService":
        let cmd = "launchctl bootstrap gui/\(uid) \"\(safePath)\""
        self.runShellWithAdminPrivileges(command: cmd, password: sudoPassword, result: result)

      case "stopNodeService":
        let cmd = "launchctl bootout gui/\(uid) \"\(safePath)\""
        self.runShellWithAdminPrivileges(command: cmd, password: sudoPassword, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  private func runShellWithAdminPrivileges(command: String, password: String, result: @escaping FlutterResult) {
    logToFlutter("info", "🛠️ Running command: \(command)")

    let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
    let scriptSource = """
    do shell script "\(escapedCommand)" user name "\(NSUserName())" password "\(password)" with administrator privileges
    """

    guard let script = NSAppleScript(source: scriptSource) else {
      result(FlutterError(code: "SCRIPT_ERROR", message: "Unable to create AppleScript", details: scriptSource))
      return
    }

    var errorDict: NSDictionary?
    let output = script.executeAndReturnError(&errorDict)

    if let error = errorDict {
      let brief = error[NSAppleScript.errorBriefMessage] as? String ?? "Execution failed"
      let number = error[NSAppleScript.errorNumber] as? Int ?? -1
      logToFlutter("error", "❌ Command failed [\(number)]: \(brief)\nDetails: \(error)")
      result(FlutterError(code: "EXEC_FAILED", message: brief, details: error))
    } else {
      let outputStr = output.stringValue ?? "success"
      logToFlutter("info", "✅ Command succeeded: \(outputStr)")
      result(outputStr)
    }
  }

  private func logToFlutter(_ level: String, _ message: String) {
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
