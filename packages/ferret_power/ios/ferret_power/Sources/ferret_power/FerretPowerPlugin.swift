import Flutter
import UIKit

public class FerretPowerPlugin: NSObject, FlutterPlugin, FerretPowerPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretPowerPlugin()
    FerretPowerPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
