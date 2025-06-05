import Flutter
import Foundation

class XrayManager {
    static let shared = XrayManager()
    private var task: Process?
    var loggerChannel: FlutterMethodChannel?

    func startXrayCore(mode: String, result: @escaping FlutterResult) {
        guard let xrayPath = Bundle.main.path(forResource: "xray", ofType: nil) else {
            result("xray binary not found")
            return
        }
        guard let configPath = Bundle.main.path(forResource: "xray-vpn", ofType: "json") else {
            result("config not found")
            return
        }
        let process = Process()
        process.launchPath = xrayPath
        process.arguments = ["-c", configPath]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            self.task = process
            UserDefaults.standard.setValue(mode, forKey: "proxy_mode")
            log("info", "xray started with mode: \(mode)")
            result("xray started")
        } catch {
            log("error", "failed to start xray: \(error.localizedDescription)")
            result("failed: \(error.localizedDescription)")
        }
    }

    func stopXrayCore(result: @escaping FlutterResult) {
        if let process = task {
            process.terminate()
            task = nil
            log("info", "xray stopped")
            result("stopped")
        } else {
            result("not running")
        }
    }

    func checkXrayStatus(result: @escaping FlutterResult) {
        result(task != nil)
    }

    private func log(_ level: String, _ message: String) {
        let full = "[\(level.uppercased())] \(Date()): \(message)"
        DispatchQueue.main.async { [weak self] in
            self?.loggerChannel?.invokeMethod("log", arguments: full)
        }
    }
}
