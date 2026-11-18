import Cocoa
import FlutterMacOS

/// Reads and writes NSPasteboard and reports changes by watching its
/// changeCount, which is the only change signal macOS offers.
public class FerretClipboardPlugin: NSObject, FlutterPlugin, ClipboardHostApi {
  /// Password managers add these types so clipboard tools leave secrets alone
  /// (see nspasteboard.org).
  private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
  private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
  private static let watchInterval: TimeInterval = 0.5

  private let pasteboard = NSPasteboard.general
  private let flutterApi: ClipboardFlutterApi
  private var timer: Timer?
  private var lastChangeCount: Int

  init(flutterApi: ClipboardFlutterApi) {
    self.flutterApi = flutterApi
    lastChangeCount = NSPasteboard.general.changeCount
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretClipboardPlugin(
      flutterApi: ClipboardFlutterApi(binaryMessenger: registrar.messenger))
    ClipboardHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func read() throws -> PlatformClip? {
    let types = pasteboard.types ?? []
    let sensitive = types.contains(Self.concealedType) || types.contains(Self.transientType)

    if let text = pasteboard.string(forType: .string), !text.isEmpty {
      return PlatformClip(text: text, sensitive: sensitive)
    }

    if let png = pasteboard.data(forType: .png) {
      return PlatformClip(
        image: FlutterStandardTypedData(bytes: png), imageMime: "image/png", sensitive: sensitive)
    }

    if let tiff = pasteboard.data(forType: .tiff),
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
    {
      return PlatformClip(
        image: FlutterStandardTypedData(bytes: png), imageMime: "image/png", sensitive: sensitive)
    }

    return nil
  }

  func write(clip: PlatformClip) throws {
    pasteboard.clearContents()

    if let text = clip.text {
      pasteboard.setString(text, forType: .string)
    } else if let image = clip.image {
      let data = image.data
      if clip.imageMime == "image/png" {
        pasteboard.setData(data, forType: .png)
      }
      if let tiff = NSImage(data: data)?.tiffRepresentation {
        pasteboard.setData(tiff, forType: .tiff)
      }
    }

    if clip.sensitive {
      pasteboard.setData(Data(), forType: Self.concealedType)
    }

    lastChangeCount = pasteboard.changeCount
  }

  func startWatching() throws {
    guard timer == nil else {
      return
    }

    lastChangeCount = pasteboard.changeCount
    let timer = Timer(timeInterval: Self.watchInterval, repeats: true) { [weak self] _ in
      self?.checkForChange()
    }
    timer.tolerance = Self.watchInterval / 2
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func stopWatching() throws {
    timer?.invalidate()
    timer = nil
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
