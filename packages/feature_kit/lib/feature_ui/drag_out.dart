import 'package:flutter/foundation.dart';

/// Drags things out of Ferret into other apps: files on this computer,
/// files still to fetch (such as a photo on a phone), and text. A drag
/// starts from the mouse press under way in the view [viewId] (from
/// `View.of(context).viewId`), so call these when a drag starts on what
/// stands for the thing. Each is false when no drag could start.
abstract interface class DragOut {
  Future<bool> files(int viewId, List<String> paths);

  /// [files] are fetched only once they are dropped somewhere: the drag
  /// starts at once, and the app they land on waits for them.
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files);

  /// Plain text, and a web address too when [isLink].
  Future<bool> text(int viewId, String text, {bool isLink = false});
}

/// A file to drag out that isn't on this computer yet.
class PromisedFile {
  const PromisedFile({required this.name, required this.fetch, this.image});

  /// Its name where it lands, such as "IMG_2041.jpg".
  final String name;

  /// A picture to drag, such as a thumbnail; the icon of its type when
  /// null.
  final Uint8List? image;

  /// The path of a local copy, once there is one; null when it couldn't
  /// be had.
  final Future<String?> Function() fetch;
}
