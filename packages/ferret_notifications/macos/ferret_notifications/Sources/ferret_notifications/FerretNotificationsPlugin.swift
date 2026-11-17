import Cocoa
import FlutterMacOS

public class FerretNotificationsPlugin: NSObject, FlutterPlugin, FerretNotificationsPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretNotificationsPlugin()
    FerretNotificationsPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
