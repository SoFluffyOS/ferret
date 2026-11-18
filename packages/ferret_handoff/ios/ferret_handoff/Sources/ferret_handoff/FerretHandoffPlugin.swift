import Flutter
import UIKit

/// Handoff on iOS: takes the links and text left by Ferret's Share
/// extension when Ferret comes to the front.
public class FerretHandoffPlugin: NSObject, FlutterPlugin, HandoffHostApi {
  private let events: HandoffEventsApi
  private let inbox = LinkInbox()
  private var isListening = false
  private var waiting: [SharedItem] = []

  init(events: HandoffEventsApi) {
    self.events = events
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretHandoffPlugin(
      events: HandoffEventsApi(binaryMessenger: registrar.messenger()))
    HandoffHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    NotificationCenter.default.addObserver(
      instance, selector: #selector(becameActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  /// iOS only lets Ferret send while it is on screen, so shares are taken
  /// as it comes to the front.
  @objc private func becameActive() {
    waiting.append(contentsOf: inbox.take())
    guard isListening, !waiting.isEmpty else {
      return
    }

    let items = waiting
    waiting = []
    Task { @MainActor in
      for item in items {
        do {
          _ = try await events.onShared(item: item)
        } catch {
          waiting.append(item)
        }
      }
    }
  }

  func setDevices(devices: [HandoffDevice]) throws {}

  func takePending() throws -> [SharedItem] {
    isListening = true
    let taken = waiting + inbox.take()
    waiting = []
    return taken
  }

  /// iOS opens a link in the app that claims it, never one Ferret picks.
  func openInApp(uri: String, appId: String) async throws -> Bool { false }

  func isAssistantEnabled() throws -> Bool { false }

  func openAssistantSettings() throws {}

  func currentBrowserTab() async throws -> BrowserTab? { nil }

  func browserAccess() async throws -> BrowserAccess { .unsupported }

  func setBrowserWatch(enabled: Bool) throws {}
}
