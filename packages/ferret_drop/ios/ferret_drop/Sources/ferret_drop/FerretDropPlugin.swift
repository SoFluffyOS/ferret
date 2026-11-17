import Flutter
import UIKit

public class FerretDropPlugin: NSObject, FlutterPlugin, FerretDropPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretDropPlugin()
    FerretDropPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
