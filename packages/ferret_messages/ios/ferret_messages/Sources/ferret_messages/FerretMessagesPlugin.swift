import Flutter
import UIKit

public class FerretMessagesPlugin: NSObject, FlutterPlugin, FerretMessagesPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMessagesPlugin()
    FerretMessagesPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
