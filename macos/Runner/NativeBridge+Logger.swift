import Foundation
import FlutterMacOS

extension AppDelegate {
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
}
