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

      // Dynamically load the bundle identifier
      let bundleId = Bundle.main.bundleIdentifier ?? "com.xstream" // Fallback to default if not found

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "writeConfigFiles":
          self.writeConfigFiles(call: call, result: result) // Call writeConfigFiles method
        case "startNodeService", "stopNodeService", "checkNodeStatus":
          guard let args = call.arguments as? [String: Any],
                let suffix = args["nodeSuffix"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing node suffix", details: nil))
            return
          }

          let userName = NSUserName()
          let uid = getuid()
          let serviceName = "\(bundleId).xray-node-\(suffix)"
          let plistPath = "/Users/\(userName)/Library/LaunchAgents/\(serviceName).plist"

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
            self.runInitXray(bundleId: bundleId, result: result)
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

  private func runInitXray(bundleId: String, result: @escaping FlutterResult) {
    guard let resourcePath = Bundle.main.resourcePath else {
        result("❌ 无法获取 Resources 路径")
        return
    }

    let escapedPath = resourcePath.replacingOccurrences(of: "'", with: "'\\''")

    let plistSuffixes = ["ca", "us", "tky"]
    let plistCopy = plistSuffixes.map {
      "cp -f '\(escapedPath)/\(bundleId).xray-node-\($0).plist' $HOME/Library/LaunchAgents;"
    }.joined(separator: "\n")

    let jsonFiles = [
      "xray-vpn-node-ca.json",
      "xray-vpn-node-tky.json",
      "xray-vpn-node-us.json",
      "xray-vpn.json"
    ]
    let jsonCopy = jsonFiles.map {
      "cp -f '\(escapedPath)/\($0)' /opt/homebrew/etc/;"
    }.joined(separator: "\n")

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
      \(plistCopy)
      \(jsonCopy)
    \" with administrator privileges
    """

    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    let output = appleScript?.executeAndReturnError(&error)

    if let error = error {
        result("❌ AppleScript 执行失败: \(error)")
    } else {
        result("✅ Xray 初始化完成: \(output?.stringValue ?? "Success")")
    }
  }

  func writeConfigFiles(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let configPath = args["configPath"] as? String,
          let configContent = args["configContent"] as? String,
          let plistPath = args["plistPath"] as? String,
          let plistContent = args["plistContent"] as? String,
          let nodeName = args["nodeName"] as? String,
          let countryCode = args["countryCode"] as? String,
          let sudoPass = args["password"] as? String,
          let vpnNodesJsonPath = args["vpnNodesJsonPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        return
    }

    // Log the vpn_nodes.json path before update
    logToFlutter("info", "即将更新 vpn_nodes.json: \(vpnNodesJsonPath)")

    // Read existing vpn_nodes.json file and parse it into a list
    let fileManager = FileManager.default
    var vpnNodes: [[String: Any]] = []

    if fileManager.fileExists(atPath: vpnNodesJsonPath) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: vpnNodesJsonPath))
            vpnNodes = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
            logToFlutter("info", "vpn_nodes.json 文件读取成功: \(vpnNodesJsonPath)")
        } catch {
            result(FlutterError(code: "READ_ERROR", message: "Unable to read vpn_nodes.json file", details: error.localizedDescription))
            return
        }
    } else {
        logToFlutter("warning", "未找到 vpn_nodes.json 文件: \(vpnNodesJsonPath)")
        return
    }

    // Create new node information
    let newNode: [String: Any] = [
        "name": nodeName,
        "countryCode": countryCode,
        "plistPath": plistPath,
        "configPath": configPath
    ]
    vpnNodes.append(newNode)

    // Log the updated vpn_nodes.json data to verify
    logToFlutter("info", "即将更新 vpn_nodes.json 内容: \(vpnNodesJsonPath)")

    // Write updated vpn_nodes.json file
    do {
        // Write the config and plist files
        writeFile(path: configPath, content: configContent, password: sudoPass)
        writeFile(path: plistPath, content: plistContent, password: sudoPass)

        // Write updated vpn_nodes.json file
        let updatedJsonContent = try JSONSerialization.data(withJSONObject: vpnNodes, options: .prettyPrinted)
        // Write to the vpn_nodes.json file
        writeFile(path: vpnNodesJsonPath, content: String(data: updatedJsonContent, encoding: .utf8) ?? "", password: sudoPass)

        // Log success
        logToFlutter("info", "vpn_nodes.json 更新成功: \(vpnNodesJsonPath)")

        result("Configuration files written successfully")
    } catch {
        result(FlutterError(code: "WRITE_ERROR", message: "Unable to write vpn_nodes.json file", details: error.localizedDescription))
        logToFlutter("error", "写入 vpn_nodes.json 失败: \(error.localizedDescription)")
    }
 }

  private func writeFile(path: String, content: String, password: String) {
    let script = """
    echo "\(password)" | sudo -S bash -c 'echo "\(content)" > \(path)'
    """

    // Execute the shell command to write the file
    runShellScript(command: script, returnsBool: false, result: { _ in
        // Can handle feedback here if necessary
    })
  }

  func runShellScript(command: String, returnsBool: Bool, result: @escaping FlutterResult) {
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    var outputBuffer = ""
    pipe.fileHandleForReading.readabilityHandler = { handle in
      let data = handle.availableData
      if let output = String(data: data, encoding: .utf8), !output.isEmpty {
        outputBuffer += output
      }
    }

    task.terminationHandler = { process in
      pipe.fileHandleForReading.readabilityHandler = nil

      DispatchQueue.main.async {
        if returnsBool {
          let found = outputBuffer.contains("xray-node")
          result(found)
        } else {
          if process.terminationStatus == 0 {
            result("success")
          } else {
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
