import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import ImageIO

/// Writes a decoded picture to a file.
enum PictureFile {
  private static let png = "public.png" as CFString

  /// Reads the pixels back from `buffer` and saves them as a PNG at `url`,
  /// making the folder when it isn't there. False when either fails.
  static func writePNG(_ buffer: CVPixelBuffer, to url: URL) -> Bool {
    let image = CIImage(cvPixelBuffer: buffer)
    guard let pixels = CIContext().createCGImage(image, from: image.extent) else {
      return false
    }

    do {
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    } catch {
      return false
    }

    guard let file = CGImageDestinationCreateWithURL(url as CFURL, png, 1, nil) else {
      return false
    }

    CGImageDestinationAddImage(file, pixels, nil)
    return CGImageDestinationFinalize(file)
  }
}
