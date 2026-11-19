import 'dart:typed_data';

/// Puts a picture on this computer's clipboard. The app wires it to the
/// clipboard feature, so the picture isn't sent back out as a new clip.
abstract interface class CapturePaste {
  /// False when the clipboard couldn't take it.
  Future<bool> putImage(Uint8List image, {required String mimeType});
}
