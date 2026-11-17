import Flutter
import UIKit

public class FerretNotificationsPlugin: NSObject, FlutterPlugin, FerretNotificationsPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretNotificationsPlugin()
    FerretNotificationsPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
