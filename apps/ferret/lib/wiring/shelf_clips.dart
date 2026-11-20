import 'dart:async';
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:engine/engine.dart';
import 'package:local_shelf/local_shelf.dart';

/// Puts each copy the clipboard takes on the shelf, through the
/// clipboard's own watcher. Clipboard and the shelf never import each
/// other, so the app joins them here. Only on a Mac for now, where the
/// shelf has its bar.
abstract final class ShelfClips {
  static StreamSubscription<ClipCopy>? attach(FerretEngine engine) {
    if (!Platform.isMacOS) {
      return null;
    }

    final shelf = engine.feature<ShelfFeature>();
    final clipboard = engine.feature<ClipboardFeature>();
    if (shelf == null || clipboard == null) {
      return null;
    }

    return clipboard.copies.listen((copy) => unawaited(keep(shelf, copy)));
  }

  static Future<void> keep(ShelfFeature shelf, ClipCopy copy) {
    final content = copy.content;

    return shelf.keepCopy(
      text: content.text,
      files: content.files,
      image: content.image,
      imageMime: content.imageMime,
      fromDeviceId: copy.fromDeviceId,
    );
  }
}
