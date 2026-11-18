import Cocoa

/// Shrinks album art to a small JPEG that fits in one media message.
enum ArtworkEncoder {
  static let maxBytes = 64 * 1024
  private static let steps: [(side: CGFloat, quality: Double)] = [(256, 0.8), (192, 0.7), (128, 0.6)]

  static func jpeg(from data: Data) -> Data? {
    guard !data.isEmpty, let image = NSImage(data: data), image.size.width > 0, image.size.height > 0 else {
      return nil
    }

    for step in steps {
      guard let encoded = encode(image, side: step.side, quality: step.quality) else { return nil }
      if encoded.count <= maxBytes {
        return encoded
      }
    }
    return nil
  }

  private static func encode(_ image: NSImage, side: CGFloat, quality: Double) -> Data? {
    let scale = min(1, side / max(image.size.width, image.size.height))
    let width = max(1, Int((image.size.width * scale).rounded()))
    let height = max(1, Int((image.size.height * scale).rounded()))
    guard
      let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)
    else {
      return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
      in: NSRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .copy,
      fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
  }
}
