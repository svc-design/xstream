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

    let escapedPath = resourcePath.replacingOccurrences(of: "'", with: "'\\''")
    let plistSuffixes = ["ca", "us", "tky"]
    let plistCopy = plistSuffixes.map {
      "cp -f '\(escapedPath)/\(bundleId).xray-node-\($0).plist' $HOME/Library/LaunchAgents;"
    }.joined(separator: "\n")

    let jsonFiles = ["xray-vpn-node-ca.json", "xray-vpn-node-tky.json", "xray-vpn-node-us.json", "xray-vpn.json"]
    let jsonCopy = jsonFiles.map {
      "cp -f '\(escapedPath)/\($0)' /opt/homebrew/etc/;"
    }.joined(separator: "\n")

    let script = """
    do shell script \
      \"mkdir -p /opt/homebrew/etc; mkdir -p $HOME/Library/LaunchAgents; arch=$(uname -m); \\
      if [ \"$arch\" = \"arm64\" ]; then cp -f '\(escapedPath)/xray' /opt/homebrew/bin/xray; chmod +x /opt/homebrew/bin/xray; fi; \\
      chmod +x /opt/homebrew/bin/xray; \(plistCopy) \(jsonCopy)\" \\
    with administrator privileges
    """

    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary? = nil
    let output = appleScript?.executeAndReturnError(&error)

    if let error = error {
        result("❌ AppleScript 执行失败: \(error)")
        logToFlutter("error", "Xray 初始化失败: \(error)")
    } else {
        result("✅ Xray 初始化完成: \(output?.stringValue ?? "Success")")
        logToFlutter("info", "Xray 初始化完成: \(output?.stringValue ?? "Success")")
    }
  }
}
