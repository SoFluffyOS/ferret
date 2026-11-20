import Flutter
import UIKit

/// Opens received files with a preview, shows them in the Files app, and
/// takes what the Share extension left.
public class FerretDropPlugin: NSObject, FlutterPlugin, FerretDropHostApi,
  UIDocumentInteractionControllerDelegate
{
  private let inbox = ShareInbox()
  private let flutterApi: FerretDropFlutterApi
  private var preview: UIDocumentInteractionController?
  private var isListening = false
  private var waiting: [SharedItems] = []

  init(flutterApi: FerretDropFlutterApi) {
    self.flutterApi = flutterApi
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretDropPlugin(
      flutterApi: FerretDropFlutterApi(binaryMessenger: registrar.messenger()))
    FerretDropHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    FreeSpace.register(with: registrar)
    NotificationCenter.default.addObserver(
      instance, selector: #selector(becameActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  /// The extension opens Ferret after leaving a request, or the user does:
  /// either way Ferret comes to the front, and only then can it send.
  @objc private func becameActive() {
    deliverRequests()
  }

  /// Requests wait here until Dart listens, so one left before launch
  /// isn't lost.
  private func deliverRequests() {
    waiting.append(contentsOf: inbox.takeRequests())
    guard isListening, !waiting.isEmpty else {
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

  /// Written only while Ferret is on screen: in the background iOS cuts
  /// its connections, and the share sheet should still offer the devices
  /// Ferret was last connected to, which it reconnects to on opening.
  func setShareTargets(targets: [ShareTarget]) throws {
    guard UIApplication.shared.applicationState == .active else {
      return
    }

    inbox.write(targets: targets)
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

    let controller = UIDocumentInteractionController(url: url)
    controller.delegate = self
    preview = controller
    return controller.presentPreview(animated: true)
  }

  func reveal(location: String) throws -> Bool {
    let folder = URL(fileURLWithPath: location).deletingLastPathComponent()
    guard
      var components = URLComponents(url: folder, resolvingAgainstBaseURL: false)
    else {
      return false
    }

    components.scheme = "shareddocuments"
    guard let filesUrl = components.url else {
      return false
    }

    UIApplication.shared.open(filesUrl)
    return true
  }

  public func documentInteractionControllerViewControllerForPreview(
    _ controller: UIDocumentInteractionController
  ) -> UIViewController {
    return topViewController() ?? UIViewController()
  }

  public func documentInteractionControllerDidEndPreview(
    _ controller: UIDocumentInteractionController
  ) {
    preview = nil
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }

    return top
  }
}
