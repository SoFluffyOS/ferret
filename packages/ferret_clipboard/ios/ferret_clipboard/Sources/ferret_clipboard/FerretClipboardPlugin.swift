import Flutter
import UIKit

public class FerretClipboardPlugin: NSObject, FlutterPlugin, FerretClipboardPluginApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretClipboardPlugin()
    FerretClipboardPluginApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func getPlatformVersion() throws -> String {
    return "iOS " + UIDevice.current.systemVersion
  }
}
