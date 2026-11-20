import Cocoa
import FlutterMacOS

/// Opens received files, shows them in Finder, and takes what the Share
/// extension hands over.
public class FerretDropPlugin: NSObject, FlutterPlugin, FerretDropHostApi {
  private let inbox = ShareInbox()
  private let flutterApi: FerretDropFlutterApi
  private var isListening = false
  private var waiting: [SharedItems] = []
  private var targets: [ShareTarget] = []

  init(flutterApi: FerretDropFlutterApi) {
    self.flutterApi = flutterApi
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretDropPlugin(
      flutterApi: FerretDropFlutterApi(binaryMessenger: registrar.messenger))
    FerretDropHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
    FreeSpace.register(with: registrar)
    registrar.addApplicationDelegate(instance)
    DistributedNotificationCenter.default().addObserver(
      instance, selector: #selector(shareArrived), name: ShareInbox.wakeNotification,
      object: nil, suspensionBehavior: .deliverImmediately)
    DistributedNotificationCenter.default().addObserver(
      instance, selector: #selector(announceTargets), name: ShareInbox.askDevicesNotification,
      object: nil, suspensionBehavior: .deliverImmediately)
    instance.deliverRequests()
  }

  /// The extension opens `ferret://send` after leaving a request, which
  /// also starts Ferret when it isn't running. The link carries the request
  /// itself when the two can't share a folder.
  public func handleOpen(_ urls: [URL]) -> Bool {
    let shares = urls.filter {
      $0.scheme == ShareInbox.wakeScheme && $0.host == ShareInbox.wakeHost
    }
    guard !shares.isEmpty else {
      return false
    }

    waiting.append(contentsOf: shares.compactMap { inbox.request(from: $0) })
    deliverRequests()
    return true
  }

  public func handleWillTerminate(_ notification: Notification) {
    targets = []
    inbox.write(targets: targets)
    announceTargets()
  }

  @objc private func announceTargets() {
    guard let data = inbox.encode(targets: targets), let list = String(data: data, encoding: .utf8)
    else {
      return
    }

    DistributedNotificationCenter.default().postNotificationName(
      ShareInbox.devicesNotification, object: list, userInfo: nil, deliverImmediately: true)
  }

  @objc private func shareArrived() {
    DispatchQueue.main.async {
      self.deliverRequests()
    }
  }

  /// Requests are taken off disk at once, which tells the extension they
  /// arrived, and wait here until Dart listens, so one that started the app
  /// isn't lost.
  private func deliverRequests() {
    waiting.append(contentsOf: inbox.takeRequests())
    guard isListening else {
      return
    }

    let requests = waiting
    waiting = []
    Task { @MainActor in
      for items in requests {
        try? await flutterApi.onShared(items: items)
      }
    }
  }

  func takePendingShares() throws -> [SharedItems] {
    isListening = true
    let taken = waiting + inbox.takeRequests()
    waiting = []
    return taken
  }

  func setShareTargets(targets: [ShareTarget]) throws {
    self.targets = targets
    inbox.write(targets: targets)
    announceTargets()
  }

  func canSaveToDownloads() throws -> Bool {
    return false
  }

  func saveToDownloads(
    sourcePath: String, fileName: String, mimeType: String, folder: String
  ) async throws -> SavedFile {
    throw PigeonError(
      code: "unsupported", message: "Save the file in the receive folder instead", details: nil)
  }

  func open(location: String, mimeType: String) throws -> Bool {
    let url = URL(fileURLWithPath: location)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return false
    }

    return NSWorkspace.shared.open(url)
  }

  func reveal(location: String) throws -> Bool {
    let url = URL(fileURLWithPath: location)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return false
    }

    NSWorkspace.shared.activateFileViewerSelecting([url])
    return true
  }
}
