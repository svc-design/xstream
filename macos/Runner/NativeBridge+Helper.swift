import Cocoa
import ServiceManagement
import Security

@objc protocol HelperToolProtocol {
  func runCommand(_ command: String, withReply reply: @escaping (String) -> Void)
}

extension AppDelegate {
  func authorizeAndBlessHelper(bundleId: String) {
    var authRef: AuthorizationRef?
    let status = AuthorizationCreate(nil, nil, [], &authRef)
    guard status == errAuthorizationSuccess else {
      logToFlutter("error", "Authorization failed: \(status)")
      return
    }

    var error: Unmanaged<CFError>?
    let helperId = bundleId + ".HelperTool"
    if SMJobBless(kSMDomainSystemLaunchd, helperId as CFString, authRef, &error) {
      logToFlutter("info", "Helper installed")
    } else if let takeRetainedValue = error?.takeRetainedValue() {
      logToFlutter("error", "Helper installation failed: \(takeRetainedValue)")
    }
  }

  func connectToHelper(bundleId: String) {
    let helperId = bundleId + ".HelperTool"
    let connection = NSXPCConnection(machServiceName: helperId, options: .privileged)
    connection.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
    connection.resume()
    self.helperConnection = connection
  }

  func runCommandPrivileged(_ command: String, completion: @escaping (String) -> Void) {
    guard let proxy = helperConnection?.remoteObjectProxyWithErrorHandler({ error in
      self.logToFlutter("error", "XPC error: \(error.localizedDescription)")
    }) as? HelperToolProtocol else {
      completion("")
      return
    }
    proxy.runCommand(command) { output in
      completion(output)
    }
  }
}
