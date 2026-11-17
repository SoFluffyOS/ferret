import Cocoa
import FlutterMacOS

public class FerretHandoffPlugin: NSObject, FlutterPlugin, FerretHandoffPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretHandoffPlugin()
    FerretHandoffPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
