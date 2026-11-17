import Flutter
import UIKit

public class FerretHandoffPlugin: NSObject, FlutterPlugin, FerretHandoffPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretHandoffPlugin()
    FerretHandoffPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
