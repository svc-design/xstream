// NativeBridge+XrayInit.swift

import Foundation
import FlutterMacOS

extension AppDelegate {
  func handlePerformAction(call: FlutterMethodCall, bundleId: String, result: @escaping FlutterResult) {
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
  }

  func runInitXray(bundleId: String, result: @escaping FlutterResult) {
    guard let resourcePath = Bundle.main.resourcePath else {
      result("❌ 无法获取 Resources 路径")
      return
    }

    let escapedPath = resourcePath.replacingOccurrences(of: "\"", with: "\\\"")

    var commands: [String] = []
    commands.append("HB_PREFIX=/opt/homebrew")
    commands.append("mkdir -p \"$HB_PREFIX/etc\"")
    commands.append("mkdir -p \"$HB_PREFIX/bin\"")
    commands.append("mkdir -p \"$HOME/Library/LaunchAgents\"")
    commands.append("arch=$(uname -m)")
    commands.append("""
if [ "$arch" = "arm64" ]; then
  cp -f "\(escapedPath)/xray" "$HB_PREFIX/bin/xray"
elif [ "$arch" = "i386" ]; then
  cp -f "\(escapedPath)/xray.i386" "$HB_PREFIX/bin/xray"
elif [ "$arch" = "x86_64" ]; then
  cp -f "\(escapedPath)/xray.x86_64" "$HB_PREFIX/bin/xray"
else
  echo "Unsupported architecture: $arch"
  exit 1
fi
""")
    commands.append("chmod +x \"$HB_PREFIX/bin/xray\"")

    let joinedCommand = commands.joined(separator: " ; ")
    let escapedCommand = joinedCommand.replacingOccurrences(of: "\"", with: "\\\"")

    let script = """
    do shell script \"\(escapedCommand)\" with administrator privileges
    """

    if let appleScript = NSAppleScript(source: script) {
      var error: NSDictionary? = nil
      let output = appleScript.executeAndReturnError(&error)

      if let error = error {
        result("❌ AppleScript 执行失败: \(error)")
        logToFlutter("error", "Xray 初始化失败: \(error)")
      } else {
        let outputStr: String
        if output.descriptorType == typeUnicodeText, let string = output.stringValue {
          outputStr = string
        } else {
          outputStr = "Success"
        }

        result("✅ Xray 初始化完成: \(outputStr)")
        logToFlutter("info", "Xray 初始化完成: \(outputStr)")
      }
    } else {
      result("❌ 无法构建 AppleScript")
      logToFlutter("error", "Xray 初始化失败: 无法构建 AppleScript")
    }
  }
}
