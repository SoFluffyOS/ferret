import Flutter
import UIKit

/// Opens received files with a preview, and shows them in the Files app.
public class FerretDropPlugin: NSObject, FlutterPlugin, FerretDropHostApi,
  UIDocumentInteractionControllerDelegate
{
  private var preview: UIDocumentInteractionController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretDropPlugin()
    FerretDropHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func takePendingShares() throws -> [SharedItems] {
    return []
  }

  func setShareTargets(targets: [ShareTarget]) throws {}

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
