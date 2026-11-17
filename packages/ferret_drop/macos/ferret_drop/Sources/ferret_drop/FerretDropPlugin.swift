import Cocoa
import FlutterMacOS

public class FerretDropPlugin: NSObject, FlutterPlugin, FerretDropPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretDropPlugin()
    FerretDropPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
