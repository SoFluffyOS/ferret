import Flutter
import Network
import UIKit

/// Says whether iOS lets Ferret on the local network. iOS has no way to
/// ask, so this browses Ferret's own Bonjour service for a moment: a
/// browser that isn't allowed waits with a policy-denied error. Only
/// called once Ferret already asked, since browsing is what makes iOS ask.
public class FerretBonjourPlugin: NSObject, FlutterPlugin {
  private static let serviceType = "_ferret._tcp"
  private static let wait: TimeInterval = 1.5

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretBonjourPlugin()
    let methods = FlutterMethodChannel(
      name: "io.sofluffy.ferret_bonjour/local_network",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "check":
      check(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Answers "denied", "allowed" or "unknown".
  private func check(_ result: @escaping FlutterResult) {
    let browser = NWBrowser(
      for: .bonjour(type: Self.serviceType, domain: "local."), using: .tcp)
    var answered = false
    var ready = false
    let finish: (String) -> Void = { answer in
      guard !answered else { return }
      answered = true
      browser.cancel()
      result(answer)
    }

    browser.stateUpdateHandler = { state in
      switch state {
      case .ready:
        ready = true
      case .waiting(let error):
        if case .dns(let code) = error, code == DNSServiceErrorType(kDNSServiceErr_PolicyDenied) {
          finish("denied")
        }
      case .failed:
        finish("unknown")
      default:
        break
      }
    }
    browser.start(queue: .main)
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.wait) {
      finish(ready ? "allowed" : "unknown")
    }
  }
}
