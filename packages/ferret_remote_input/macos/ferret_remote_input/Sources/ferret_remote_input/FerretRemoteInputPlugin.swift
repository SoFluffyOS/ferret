import Cocoa
import FlutterMacOS

/// Injects pointer and keyboard input for a remote controller with CGEvent.
/// Posting events needs the person's permission, listed under
/// Accessibility in System Settings.
public class FerretRemoteInputPlugin: NSObject, FlutterPlugin, RemoteInputHostApi {
  private let injector = QuartzInjector()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretRemoteInputPlugin()
    RemoteInputHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func access() throws -> NativeAccess {
    let granted = QuartzInjector.hasAccess
    return NativeAccess(granted: granted, needsPermission: !granted)
  }

  func requestAccess() throws -> Bool {
    QuartzInjector.requestAccess()
  }

  func openAccessSettings() throws {
    let address = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    guard let url = URL(string: address) else {
      return
    }

    NSWorkspace.shared.open(url)
  }

  func inject(events: [NativeInputEvent]) throws {
    guard QuartzInjector.hasAccess else {
      throw PigeonError(
        code: "no_access", message: "Accessibility access is off", details: nil)
    }

    injector.inject(events)
  }

  func releaseAll() throws {
    injector.releaseAll()
  }
}
