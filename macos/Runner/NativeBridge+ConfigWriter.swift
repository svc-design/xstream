// NativeBridge+ConfigWriter.swift
import Foundation
import FlutterMacOS

extension AppDelegate {
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

    do {
      try writeXrayJson(path: configPath, content: configContent, password: sudoPass, result: result)
      try writePlistFile(path: plistPath, content: plistContent, password: sudoPass, result: result)
      try updateVpnNodesJson(path: vpnNodesJsonPath, nodeName: nodeName, countryCode: countryCode, plistPath: plistPath, configPath: configPath, password: sudoPass, result: result)

      result("Configuration files written successfully")
    } catch {
      result(FlutterError(code: "WRITE_ERROR", message: "写入失败", details: error.localizedDescription))
      logToFlutter("error", "写入失败: \(error.localizedDescription)")
    }
  }

  private func writeXrayJson(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    logToFlutter("info", "创建 Xray 配置文件: \(path)")
    try runPrivilegedWrite(path: path, content: content, password: password, result: result)
  }

  private func writePlistFile(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    logToFlutter("info", "写入 LaunchAgent plist: \(path)")
    try runPrivilegedWrite(path: path, content: content, password: password, result: result)
  }

  private func updateVpnNodesJson(path: String, nodeName: String, countryCode: String, plistPath: String, configPath: String, password: String, result: @escaping FlutterResult) throws {
    logToFlutter("info", "更新 vpn_nodes.json: \(path)")
    let fileManager = FileManager.default
    var vpnNodes: [[String: Any]] = []

    if fileManager.fileExists(atPath: path) {
      let data = try Data(contentsOf: URL(fileURLWithPath: path))
      vpnNodes = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
      logToFlutter("info", "读取成功: \(path)")
    }

    let newNode: [String: Any] = [
      "name": nodeName,
      "countryCode": countryCode,
      "plistPath": plistPath,
      "configPath": configPath
    ]
    vpnNodes.append(newNode)

    let updatedJson = try JSONSerialization.data(withJSONObject: vpnNodes, options: .prettyPrinted)
    try runPrivilegedWrite(path: path, content: String(data: updatedJson, encoding: .utf8) ?? "", password: password, result: result)
    logToFlutter("info", "vpn_nodes.json 写入成功: \(path)")
  }

  private func runPrivilegedWrite(path: String, content: String, password: String, result: @escaping FlutterResult) throws {
    let escapedContent = content.replacingOccurrences(of: "\"", with: "\\\"")
    let script = "echo \"\(password)\" | sudo -S bash -c 'echo \"\(escapedContent)\" > \"\(path)\"'"
    runShellScript(command: script, returnsBool: true, result: result)
  }

}
