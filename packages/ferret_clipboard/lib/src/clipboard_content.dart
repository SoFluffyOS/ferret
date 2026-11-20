import 'dart:typed_data';

/// Text or an image on the clipboard.
class ClipboardContent {
  const ClipboardContent.text(
    String this.text, {
    this.sensitive = false,
    this.files = const [],
  }) : image = null,
       imageMime = null;

  const ClipboardContent.image(
    Uint8List this.image, {
    required String this.imageMime,
    this.sensitive = false,
  }) : text = null,
       files = const [];

  final String? text;
  final Uint8List? image;

  /// Media type of [image], such as `image/png`.
  final String? imageMime;

  /// The source app marked it as private, such as a password manager, or it
  /// should be marked so when written.
  final bool sensitive;

  /// Files copied in a file manager, by their paths, where the platform
  /// says so; [text] holds their names then. Only read, never written.
  final List<String> files;

  bool get isImage => image != null;
}
