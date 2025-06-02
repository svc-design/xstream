// AppDelegate.swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {

      let channel = FlutterMethodChannel(name: "com.xstream/native", binaryMessenger: controller.engine.binaryMessenger)

      let bundleId = Bundle.main.bundleIdentifier ?? "com.xstream"

      channel.setMethodCallHandler { [self] call, result in
        switch call.method {
        case "writeConfigFiles":
          self.writeConfigFiles(call: call, result: result)

        case "startNodeService", "stopNodeService", "checkNodeStatus":
          self.handleServiceControl(call: call, bundleId: bundleId, result: result)

        case "performAction":
          self.handlePerformAction(call: call, bundleId: bundleId, result: result)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
