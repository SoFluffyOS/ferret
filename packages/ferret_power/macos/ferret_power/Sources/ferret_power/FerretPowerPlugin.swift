import Cocoa
import FlutterMacOS

public class FerretPowerPlugin: NSObject, FlutterPlugin, FerretPowerPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretPowerPlugin()
    FerretPowerPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
