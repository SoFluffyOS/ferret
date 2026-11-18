import Cocoa
import FlutterMacOS

/// Handoff on macOS: opens links in a given app and, when the user opted in,
/// reads the current browser page through Automation.
public class FerretHandoffPlugin: NSObject, FlutterPlugin, HandoffHostApi {
  private let events: HandoffEventsApi
  private let browsers = BrowserReader()
  private var observers: [NSObjectProtocol] = []

  init(events: HandoffEventsApi) {
    self.events = events
    super.init()
    observers.append(
      NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didActivateApplicationNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        self?.browsers.noteActivated(Self.bundleId(of: notification))
      })
  }

  deinit {
    for observer in observers {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretHandoffPlugin(events: HandoffEventsApi(binaryMessenger: registrar.messenger))
    HandoffHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func setDevices(devices: [HandoffDevice]) throws {}

  func takePending() throws -> [SharedItem] { [] }

  func openInApp(uri: String, appId: String) async throws -> Bool {
    guard let url = URL(string: uri),
      let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appId)
    else {
      return false
    }

    return await withCheckedContinuation { continuation in
      NSWorkspace.shared.open(
        [url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()
      ) { _, error in
        continuation.resume(returning: error == nil)
      }
    }
  }

  func isAssistantEnabled() throws -> Bool { false }

  func openAssistantSettings() throws {}

  func currentBrowserTab() async throws -> BrowserTab? {
    try await browsers.currentTab()
  }

  func browserAccess() async throws -> BrowserAccess {
    await withCheckedContinuation { continuation in
      browsers.access { continuation.resume(returning: $0) }
    }
  }

  func setBrowserWatch(enabled: Bool) throws {
    if !enabled {
      stopWatching()
      return
    }

    if observers.count > 1 {
      return
    }

    observers.append(
      NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didDeactivateApplicationNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        guard let self, let bundleId = Self.bundleId(of: notification),
          BrowserReader.isSupported(bundleId)
        else {
          return
        }

        Task { @MainActor in
          try? await self.events.onBrowserDeactivated(bundleId: bundleId)
        }
      })
  }

  private func stopWatching() {
    while observers.count > 1 {
      NSWorkspace.shared.notificationCenter.removeObserver(observers.removeLast())
    }
  }

  private static func bundleId(of notification: Notification) -> String? {
    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    return app?.bundleIdentifier
  }
}
