import Cocoa
import FlutterMacOS

public class FerretIphonePlugin: NSObject, FlutterPlugin {
  private static var central: AppleGattCentral?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let central = AppleGattCentral(messenger: registrar.messenger)
    AppleGattHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: central)
    FerretIphonePlugin.central = central
  }
}
