import Cocoa
import FlutterMacOS

public class FerretRemoteInputPlugin: NSObject, FlutterPlugin, FerretRemoteInputPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretRemoteInputPlugin()
    FerretRemoteInputPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
