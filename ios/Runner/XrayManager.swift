import Flutter
import Foundation

class XrayManager {
    static let shared = XrayManager()
    private var task: Process?

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
            result("xray started")
        } catch {
            result("failed: \(error.localizedDescription)")
        }
    }
}
