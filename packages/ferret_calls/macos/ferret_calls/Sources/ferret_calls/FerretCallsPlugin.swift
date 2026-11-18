import Cocoa
import FlutterMacOS

public class FerretCallsPlugin: NSObject, FlutterPlugin, FerretCallsPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretCallsPlugin()
    FerretCallsPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
