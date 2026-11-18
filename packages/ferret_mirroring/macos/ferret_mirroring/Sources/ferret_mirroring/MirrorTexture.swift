import CoreVideo
import FlutterMacOS
import Foundation

/// The Flutter texture the mirrored screen is drawn to: always the newest
/// decoded picture.
final class MirrorTexture: NSObject, FlutterTexture {
  private let lock = NSLock()
  private var latest: CVPixelBuffer?

  func show(_ pixelBuffer: CVPixelBuffer) {
    lock.lock()
    latest = pixelBuffer
    lock.unlock()
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    lock.lock()
    defer { lock.unlock() }
    guard let latest else {
      return nil
    }

    return Unmanaged.passRetained(latest)
  }
}
