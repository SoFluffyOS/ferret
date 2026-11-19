import Flutter
import Photos
import PhotosUI
import UIKit

/// Reads the photo library with PhotoKit for Dart: pages newest first,
/// thumbnails, a copy of one photo, and new screenshots while Dart listens.
/// Read only, and only while Ferret is open: iOS doesn't let it run in the
/// background. Never logs names.
public class FerretPhotosPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  PHPhotoLibraryChangeObserver
{
  private var sink: FlutterEventSink?
  private var screenshots: PHFetchResult<PHAsset>?
  private var sent = Set<String>()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretPhotosPlugin()
    let methods = FlutterMethodChannel(
      name: "io.sofluffy.ferret_photos", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: "io.sofluffy.ferret_photos/screenshots", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "access":
      result(Self.accessName())
    case "requestAccess":
      requestAccess(result)
    case "list":
      guard Self.canRead() else {
        result(["entries": [Any]()])
        return
      }
      let cursor = arguments["cursor"] as? String
      let limit = min(max(arguments["limit"] as? Int ?? 60, 1), 200)
      result(Self.page(cursor: cursor, limit: limit))
    case "thumbnail":
      guard Self.canRead(), let id = arguments["id"] as? String else {
        result(nil)
        return
      }
      let maxPx = min(max(arguments["maxPx"] as? Int ?? 256, 32), 2048)
      Self.thumbnail(id: id, maxPx: maxPx, result: result)
    case "export":
      guard Self.canRead(), let id = arguments["id"] as? String else {
        result(nil)
        return
      }
      Self.export(id: id, result: result)
    case "openSettings":
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }
      UIApplication.shared.open(url) { opened in result(opened) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    sent.removeAll()
    screenshots = Self.fetchScreenshots(after: Date())
    PHPhotoLibrary.shared().register(self)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
    sink = nil
    screenshots = nil
    return nil
  }

  public func photoLibraryDidChange(_ changeInstance: PHChange) {
    guard let current = screenshots, let details = changeInstance.changeDetails(for: current)
    else {
      return
    }

    screenshots = details.fetchResultAfterChanges
    let inserted = details.insertedObjects
    DispatchQueue.main.async { [weak self] in
      guard let self, let sink = self.sink else {
        return
      }
      for asset in inserted where !self.sent.contains(asset.localIdentifier) {
        self.sent.insert(asset.localIdentifier)
        sink(Self.entry(asset))
      }
    }
  }

  private func requestAccess(_ result: @escaping FlutterResult) {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    if status == .limited, let root = Self.topController() {
      PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: root) { _ in
        DispatchQueue.main.async { result(Self.accessName()) }
      }
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
      DispatchQueue.main.async { result(Self.accessName()) }
    }
  }

  private static func accessName() -> String {
    switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
    case .authorized: return "full"
    case .limited: return "limited"
    case .denied, .restricted: return "denied"
    case .notDetermined: return "notAsked"
    @unknown default: return "unavailable"
    }
  }

  private static func canRead() -> Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    return status == .authorized || status == .limited
  }

  /// Cursors are offsets into the newest-first list. A photo added while
  /// someone pages shifts it by one; the computer drops the repeat by id.
  private static func page(cursor: String?, limit: Int) -> [String: Any] {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    options.predicate = NSPredicate(
      format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue,
      PHAssetMediaType.video.rawValue)
    let assets = PHAsset.fetchAssets(with: options)
    let start = Int(cursor ?? "") ?? 0
    let end = min(start + limit, assets.count)
    var entries: [[String: Any]] = []
    if start < end {
      for index in start..<end {
        entries.append(entry(assets.object(at: index)))
      }
    }
    let next = end < assets.count ? String(end) : ""
    return ["entries": entries, "nextCursor": next]
  }

  private static func fetchScreenshots(after date: Date) -> PHFetchResult<PHAsset> {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(
      format: "(mediaSubtypes & %d) != 0 AND creationDate > %@",
      PHAssetMediaSubtype.photoScreenshot.rawValue, date as NSDate)
    return PHAsset.fetchAssets(with: .image, options: options)
  }

  private static func entry(_ asset: PHAsset) -> [String: Any] {
    let isVideo = asset.mediaType == .video
    let isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
    let kind = isVideo ? "video" : (isScreenshot ? "screenshot" : "photo")
    let name = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? ""
    let taken = asset.creationDate ?? Date()
    return [
      "id": asset.localIdentifier,
      "takenAtMs": Int(taken.timeIntervalSince1970 * 1000),
      "kind": kind,
      "width": asset.pixelWidth,
      "height": asset.pixelHeight,
      "name": name,
      "durationMs": isVideo ? Int(asset.duration * 1000) : 0,
    ]
  }

  private static func asset(_ id: String) -> PHAsset? {
    PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
  }

  private static func thumbnail(id: String, maxPx: Int, result: @escaping FlutterResult) {
    guard let asset = asset(id) else {
      result(nil)
      return
    }

    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    options.isNetworkAccessAllowed = false
    options.isSynchronous = false
    let size = CGSize(width: maxPx, height: maxPx)
    PHImageManager.default().requestImage(
      for: asset, targetSize: size, contentMode: .aspectFit, options: options
    ) { image, _ in
      let data = image?.jpegData(compressionQuality: 0.8)
      DispatchQueue.main.async {
        result(data.map { FlutterStandardTypedData(bytes: $0) })
      }
    }
  }

  private static func export(id: String, result: @escaping FlutterResult) {
    guard let asset = asset(id) else {
      result(nil)
      return
    }

    let resources = PHAssetResource.assetResources(for: asset)
    let primary =
      resources.first { $0.type == .photo || $0.type == .video || $0.type == .fullSizePhoto }
      ?? resources.first
    guard let resource = primary else {
      result(nil)
      return
    }

    let folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("ferret_photos", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let cleaned = resource.originalFilename
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: ":", with: "_")
    let name = cleaned.isEmpty ? "photo" : cleaned
    let target = folder.appendingPathComponent(name)
    do {
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    } catch {
      result(nil)
      return
    }

    let options = PHAssetResourceRequestOptions()
    options.isNetworkAccessAllowed = true
    PHAssetResourceManager.default().writeData(for: resource, toFile: target, options: options) {
      error in
      if error == nil, let taken = asset.creationDate {
        try? FileManager.default.setAttributes(
          [.modificationDate: taken], ofItemAtPath: target.path)
      }
      DispatchQueue.main.async {
        result(error == nil ? target.path : nil)
      }
    }
  }

  private static func topController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
