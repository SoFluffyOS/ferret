import Cocoa
import FlutterMacOS

public class FerretIphonePlugin: NSObject, FlutterPlugin, FerretIphonePluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretIphonePlugin()
    FerretIphonePluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
