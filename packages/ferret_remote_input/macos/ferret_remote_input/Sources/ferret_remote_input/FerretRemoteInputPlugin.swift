import Carbon.HIToolbox
import Cocoa
import FlutterMacOS

/// Injects pointer and keyboard input for a remote controller with CGEvent.
/// Posting events needs the person's permission, listed under
/// Accessibility in System Settings. Also takes this Mac's own keyboard and
/// mouse to use them on another computer, switched with ⌃⌥→ and ⌃⌥⎋.
public class FerretRemoteInputPlugin: NSObject, FlutterPlugin, RemoteInputHostApi,
  InputCaptureHostApi
{
  /// A second "next" this soon after one is the same press, heard both by
  /// the event tap and by the hot key.
  private static let samePressGap: TimeInterval = 0.3

  private let injector = QuartzInjector()
  private let capture = InputCapture()
  private let nextKey = SwitchHotKey(
    id: 3, keyCode: kVK_RightArrow, modifiers: controlKey | optionKey)
  private let homeKey = SwitchHotKey(
    id: 4, keyCode: kVK_Escape, modifiers: controlKey | optionKey)
  private var captureApi: InputCaptureFlutterApi?
  private var lastNextAt: TimeInterval = 0

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretRemoteInputPlugin()
    RemoteInputHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
    InputCaptureHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
    instance.captureApi = InputCaptureFlutterApi(binaryMessenger: registrar.messenger)
    instance.wireCapture()
  }

  func access() throws -> NativeAccess {
    let granted = QuartzInjector.hasAccess
    return NativeAccess(granted: granted, needsPermission: !granted)
  }

  func requestAccess() throws -> Bool {
    QuartzInjector.requestAccess()
  }

  func openAccessSettings() throws {
    Self.openPrivacy("Privacy_Accessibility")
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

  func captureAccess() throws -> NativeCaptureAccess {
    InputCapture.access
  }

  func requestCaptureAccess() throws -> Bool {
    InputCapture.requestAccess()
  }

  func openCaptureSettings() throws {
    guard InputCapture.access.inputMonitoring else {
      Self.openPrivacy("Privacy_ListenEvent")
      return
    }

    Self.openPrivacy("Privacy_Accessibility")
  }

  func secureInputOn() throws -> Bool {
    InputCapture.secureInputOn
  }

  func setSwitchKeys(enabled: Bool) throws -> Bool {
    guard enabled else {
      nextKey.unregister()
      homeKey.unregister()
      return true
    }

    let next = nextKey.register()
    let home = homeKey.register()
    return next && home
  }

  func startCapture() throws -> Int64 {
    capture.start()
  }

  func stopCapture() throws {
    capture.stop()
  }

  private func wireCapture() {
    capture.onEvents = { [weak self] events in
      Task { @MainActor in try? await self?.captureApi?.onCaptured(events: events) }
    }
    capture.onSwitchKey = { [weak self] key in self?.switchKey(key) }
    capture.onEnded = { [weak self] reason in
      Task { @MainActor in try? await self?.captureApi?.onCaptureEnded(reason: reason) }
    }
    nextKey.onPressed = { [weak self] in self?.switchKey(.next) }
    homeKey.onPressed = { [weak self] in
      guard let self else { return }

      if capture.isCapturing {
        capture.end(.homeKey)
        return
      }

      switchKey(.home)
    }
  }

  private func switchKey(_ key: NativeSwitchKey) {
    if key == .next {
      let now = ProcessInfo.processInfo.systemUptime
      guard now - lastNextAt > Self.samePressGap else { return }

      lastNextAt = now
    }

    Task { @MainActor in try? await captureApi?.onSwitchKey(key: key) }
  }

  private static func openPrivacy(_ anchor: String) {
    let address = "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
    guard let url = URL(string: address) else {
      return
    }

    NSWorkspace.shared.open(url)
  }
}
