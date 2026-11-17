import Flutter
import UIKit

public class FerretMediaPlugin: NSObject, FlutterPlugin, FerretMediaPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMediaPlugin()
    FerretMediaPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
