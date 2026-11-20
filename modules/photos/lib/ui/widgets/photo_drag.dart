import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:photos/ui/widgets/photo_sizes.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:protocol/photos.dart';

/// Drags photos from a phone out to Finder or another app. Ones already on
/// this computer go as they are; the rest are promised, so the drag starts
/// at once and each is fetched only once it is dropped.
abstract final class PhotoDrag {
  /// How long a drag waits for a thumbnail to show while dragging.
  static const _pictureWait = Duration(milliseconds: 200);

  static Future<bool> start(
    BuildContext context, {
    required DragOut dragOut,
    required PhotoGalleryViewModel viewModel,
    required List<PhotoItem> items,
  }) async {
    final viewId = View.of(context).viewId;
    final copies = [
      for (final item in items) ?viewModel.localCopy(item.id),
    ];
    if (copies.length == items.length) {
      return dragOut.files(viewId, copies);
    }

    final files = [
      for (final item in items)
        PromisedFile(
          name: fileName(item),
          image: await viewModel
              .thumbnail(item.id, maxPx: PhotoSizes.tile)
              .timeout(_pictureWait, onTimeout: () => null),
          fetch: () => viewModel.fetchLocal(item.id),
        ),
    ];
    return dragOut.promisedFiles(viewId, files);
  }

  /// The name [item] gets where it lands: the phone's own, without any
  /// folder in it.
  static String fileName(PhotoItem item) {
    final name = p.basename(item.name.replaceAll(r'\', '/')).trim();
    if (name.isNotEmpty && name != '.' && name != '..') {
      return name;
    }

    return switch (item.kind) {
      .PHOTO_KIND_VIDEO => 'Video.mp4',
      .PHOTO_KIND_SCREENSHOT => 'Screenshot.png',
      _ => 'Photo.jpg',
    };
  }
}
