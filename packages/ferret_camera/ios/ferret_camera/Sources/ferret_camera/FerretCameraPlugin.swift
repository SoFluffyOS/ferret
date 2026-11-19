import AVFoundation
import Flutter
import UIKit
import VisionKit

/// Opens the iPhone camera for one photo, or VisionKit's document scanner,
/// over Ferret's screen. The person sees it and presses the shutter;
/// nothing is captured otherwise, and only while Ferret is open. Photos
/// come back as JPEGs turned the right way up, without their location.
/// Never logs paths.
public class FerretCameraPlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate,
  UINavigationControllerDelegate, VNDocumentCameraViewControllerDelegate
{
  private var pending: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretCameraPlugin()
    let methods = FlutterMethodChannel(
      name: "io.sofluffy.ferret_camera", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "abilities":
      result([
        "photo": UIImagePickerController.isSourceTypeAvailable(.camera),
        "document": VNDocumentCameraViewController.isSupported,
      ])
    case "takePhoto":
      takePhoto(result)
    case "scanDocument":
      scanDocument(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func takePhoto(_ result: @escaping FlutterResult) {
    guard pending == nil else {
      result(Self.outcome("failed"))
      return
    }
    guard UIImagePickerController.isSourceTypeAvailable(.camera),
      let presenter = Self.presenter()
    else {
      result(Self.outcome("unavailable"))
      return
    }
    if Self.cameraDenied() {
      result(Self.outcome("noPermission"))
      return
    }

    pending = result
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  private func scanDocument(_ result: @escaping FlutterResult) {
    guard pending == nil else {
      result(Self.outcome("failed"))
      return
    }
    guard VNDocumentCameraViewController.isSupported, let presenter = Self.presenter() else {
      result(Self.outcome("unavailable"))
      return
    }
    if Self.cameraDenied() {
      result(Self.outcome("noPermission"))
      return
    }

    pending = result
    let scanner = VNDocumentCameraViewController()
    scanner.delegate = self
    presenter.present(scanner, animated: true)
  }

  // MARK: Photo

  public func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage else {
      finish(Self.outcome("failed"))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let answer = Self.save(jpegOf: Self.upright(image), name: Self.fileName("Photo"))
      DispatchQueue.main.async { self.finish(answer) }
    }
  }

  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    finish(Self.outcome("cancelled"))
  }

  // MARK: Document

  public func documentCameraViewController(
    _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
  ) {
    controller.dismiss(animated: true)
    let pages = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
    guard !pages.isEmpty else {
      finish(Self.outcome("cancelled"))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let name = Self.fileName("Scan")
      let answer: [String: Any]
      if pages.count == 1 {
        answer = Self.save(jpegOf: Self.upright(pages[0]), name: name)
      } else {
        answer = Self.save(pdfOf: pages, name: name)
      }
      DispatchQueue.main.async { self.finish(answer) }
    }
  }

  public func documentCameraViewControllerDidCancel(
    _ controller: VNDocumentCameraViewController
  ) {
    controller.dismiss(animated: true)
    finish(Self.outcome("cancelled"))
  }

  public func documentCameraViewController(
    _ controller: VNDocumentCameraViewController, didFailWithError error: Error
  ) {
    controller.dismiss(animated: true)
    finish(Self.outcome("failed"))
  }

  // MARK: Helpers

  private func finish(_ answer: [String: Any]) {
    guard let result = pending else {
      return
    }
    pending = nil
    result(answer)
  }

  private static func outcome(_ name: String) -> [String: Any] {
    ["outcome": name]
  }

  private static func cameraDenied() -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .denied, .restricted:
      return true
    default:
      return false
    }
  }

  private static func presenter() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window =
      scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  /// Redraws [image] so its pixels stand the way it is seen: the JPEG then
  /// carries no turn and no EXIF, so no location either.
  private static func upright(_ image: UIImage) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let size = CGSize(
      width: image.size.width * image.scale, height: image.size.height * image.scale)
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }

  private static func save(jpegOf image: UIImage, name: String) -> [String: Any] {
    guard let data = image.jpegData(compressionQuality: 0.9),
      let url = target(name: name, extension: "jpg"),
      (try? data.write(to: url)) != nil
    else {
      return outcome("failed")
    }
    return ["outcome": "taken", "path": url.path, "mimeType": "image/jpeg"]
  }

  private static func save(pdfOf pages: [UIImage], name: String) -> [String: Any] {
    guard let url = target(name: name, extension: "pdf"), let first = pages.first else {
      return outcome("failed")
    }

    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: first.size))
    do {
      try renderer.writePDF(to: url) { context in
        for page in pages {
          let bounds = CGRect(origin: .zero, size: page.size)
          context.beginPage(withBounds: bounds, pageInfo: [:])
          page.draw(in: bounds)
        }
      }
    } catch {
      return outcome("failed")
    }
    return ["outcome": "taken", "path": url.path, "mimeType": "application/pdf"]
  }

  private static func target(name: String, extension ext: String) -> URL? {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
      "ferret_camera", isDirectory: true)
    guard (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true))
      != nil
    else {
      return nil
    }
    return folder.appendingPathComponent(name).appendingPathExtension(ext)
  }

  private static func fileName(_ prefix: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
    return "\(prefix) \(formatter.string(from: Date()))"
  }
}
