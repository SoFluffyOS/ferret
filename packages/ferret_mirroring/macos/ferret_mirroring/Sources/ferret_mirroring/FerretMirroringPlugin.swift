import Cocoa
import FlutterMacOS

public class FerretMirroringPlugin: NSObject, FlutterPlugin, FerretMirroringPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMirroringPlugin()
    FerretMirroringPluginApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
  }
}
