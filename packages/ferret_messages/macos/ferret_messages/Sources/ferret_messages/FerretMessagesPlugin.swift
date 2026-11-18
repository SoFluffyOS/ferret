import Cocoa
import FlutterMacOS

public class FerretMessagesPlugin: NSObject, FlutterPlugin, FerretMessagesPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMessagesPlugin()
    FerretMessagesPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
