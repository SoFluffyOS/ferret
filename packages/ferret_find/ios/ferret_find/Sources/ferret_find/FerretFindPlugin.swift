import Flutter
import UIKit

public class FerretFindPlugin: NSObject, FlutterPlugin, FerretFindPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretFindPlugin()
    FerretFindPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
