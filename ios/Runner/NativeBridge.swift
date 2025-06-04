import Flutter
import UIKit

extension AppDelegate {
  func setupMethodChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: "com.xstream/native", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "writeConfigFiles", "startNodeService", "stopNodeService", "checkNodeStatus", "performAction":
        self?.unsupported(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func unsupported(result: FlutterResult) {
    logToFlutter("warn", "\(result) feature not supported on iOS")
    result(FlutterError(code: "UNSUPPORTED", message: "Not supported on iOS", details: nil))
  }

  func logToFlutter(_ level: String, _ message: String) {
    let fullLog = "[\(level.uppercased())] \(Date()): \(message)"
    DispatchQueue.main.async {
      if let controller = self.window?.rootViewController as? FlutterViewController {
        let messenger = controller.engine.binaryMessenger
        let loggerChannel = FlutterMethodChannel(name: "com.xstream/logger", binaryMessenger: messenger)
        loggerChannel.invokeMethod("log", arguments: fullLog)
      }
    }
  }
}
