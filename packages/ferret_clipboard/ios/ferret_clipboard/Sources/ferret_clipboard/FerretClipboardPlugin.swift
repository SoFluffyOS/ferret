import Flutter
import UIKit
import UniformTypeIdentifiers

/// Reads and writes UIPasteboard. iOS only lets apps in front touch it, and
/// reading may ask the user first, so Dart reads only when someone asks.
public class FerretClipboardPlugin: NSObject, FlutterPlugin, ClipboardHostApi {
  private static let concealedType = "org.nspasteboard.ConcealedType"
  private static let transientType = "org.nspasteboard.TransientType"
  private static let sensitiveLifetime: TimeInterval = 120

  private let pasteboard = UIPasteboard.general
  private let flutterApi: ClipboardFlutterApi
  private var observers: [NSObjectProtocol] = []
  private var lastChangeCount: Int

  init(flutterApi: ClipboardFlutterApi) {
    self.flutterApi = flutterApi
    lastChangeCount = UIPasteboard.general.changeCount
  }

  deinit {
    removeObservers()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretClipboardPlugin(
      flutterApi: ClipboardFlutterApi(binaryMessenger: registrar.messenger()))
    ClipboardHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  func read() throws -> PlatformClip? {
    let types = pasteboard.types
    let sensitive = types.contains(Self.concealedType) || types.contains(Self.transientType)

    if pasteboard.hasStrings, let text = pasteboard.string, !text.isEmpty {
      return PlatformClip(text: text, sensitive: sensitive)
    }

    if pasteboard.hasImages, let png = pasteboard.image?.pngData() {
      return PlatformClip(
        image: FlutterStandardTypedData(bytes: png), imageMime: "image/png", sensitive: sensitive)
    }

    return nil
  }

  func write(clip: PlatformClip) throws {
    var item: [String: Any] = [:]
    if let text = clip.text {
      item[UTType.utf8PlainText.identifier] = text
    } else if let image = clip.image {
      let type = UTType(mimeType: clip.imageMime ?? "") ?? .png
      item[type.identifier] = image.data
    }

    guard !item.isEmpty else {
      return
    }

    var options: [UIPasteboard.OptionsKey: Any] = [:]
    if clip.sensitive {
      item[Self.concealedType] = Data()
      options[.localOnly] = true
      options[.expirationDate] = Date().addingTimeInterval(Self.sensitiveLifetime)
    }

    pasteboard.setItems([item], options: options)
    lastChangeCount = pasteboard.changeCount
  }

  func startWatching() throws {
    guard observers.isEmpty else {
      return
    }

    let center = NotificationCenter.default
    let onChange: (Notification) -> Void = { [weak self] _ in
      self?.checkForChange()
    }
    observers = [
      center.addObserver(
        forName: UIPasteboard.changedNotification, object: nil, queue: .main, using: onChange),
      center.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main,
        using: onChange),
    ]
  }

  func stopWatching() throws {
    removeObservers()
  }

  private func removeObservers() {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
    observers = []
  }

  private func checkForChange() {
    let changeCount = pasteboard.changeCount
    guard changeCount != lastChangeCount else {
      return
    }

    lastChangeCount = changeCount
    Task { @MainActor [flutterApi] in
      try? await flutterApi.onChanged()
    }
  }
}
