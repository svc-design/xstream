import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.xstream/native", binaryMessenger: controller.binaryMessenger)
    let loggerChannel = FlutterMethodChannel(name: "com.xstream/logger", binaryMessenger: controller.binaryMessenger)

    XrayManager.shared.loggerChannel = loggerChannel

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "startXrayCore":
        if let args = call.arguments as? [String: Any], let mode = args["mode"] as? String {
          XrayManager.shared.startXrayCore(mode: mode, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing mode", details: nil))
        }
      case "startNodeService":
        if let args = call.arguments as? [String: Any], let mode = args["mode"] as? String {
          XrayManager.shared.startXrayCore(mode: mode, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing mode", details: nil))
        }
      case "stopNodeService":
        XrayManager.shared.stopXrayCore(result: result)
      case "checkNodeStatus":
        XrayManager.shared.checkXrayStatus(result: result)
      case "writeConfigFiles", "performAction":
        result(FlutterError(code: "UNSUPPORTED", message: "Not supported on iOS", details: nil))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
