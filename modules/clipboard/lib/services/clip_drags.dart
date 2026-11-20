import 'dart:io';

import 'package:clipboard/models/models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:protocol/clipboard.dart';

/// Drags a clip from Recent clips into another app: text as text (a link
/// as a web address too), an image as a picture file.
class ClipDrags {
  ClipDrags({
    required DragOut dragOut,
    required Future<String> Function() folder,
  }) : _dragOut = dragOut,
       _folder = folder;

  final DragOut _dragOut;

  /// Where image clips are written to be dragged, such as the app's cache.
  final Future<String> Function() _folder;

  /// Starts dragging [clip] out of the view [viewId]. An image lands as
  /// "[imageName].png". False when it has nothing to drag, such as a
  /// private clip cleared from memory, or no drag could start.
  Future<bool> start(
    int viewId,
    ClipEntry clip, {
    required String imageName,
  }) async {
    if (!clip.hasContent) {
      return false;
    }

    if (clip.isImage) {
      final path = await _writeImage(clip, imageName);
      if (path == null) {
        return false;
      }

      return _dragOut.files(viewId, [path]);
    }

    final text = clip.item.text;
    if (text.isEmpty) {
      return false;
    }

    return _dragOut.text(
      viewId,
      text,
      isLink: clip.item.kind == ClipKind.CLIP_KIND_URL,
    );
  }

  /// Writes [clip]'s picture into a folder of its own, so its file keeps a
  /// plain name. Only the clip dragged last stays on disk.
  Future<String?> _writeImage(ClipEntry clip, String imageName) async {
    final image = clip.item.image;
    if (image.isEmpty) {
      return null;
    }

    final separator = Platform.pathSeparator;
    final root = Directory('${await _folder()}${separator}clips');
    final name = folderNameOf(clip.id);
    if (await root.exists()) {
      await for (final entity in root.list()) {
        final isOlder =
            entity is Directory && entity.path.split(separator).last != name;
        if (isOlder) {
          await entity.delete(recursive: true);
        }
      }
    }

    final folder = Directory('${root.path}$separator$name');
    await folder.create(recursive: true);
    final file = File(
      '${folder.path}$separator${fileNameOf(imageName)}.'
      '${extensionOf(clip.item.imageMime)}',
    );
    if (!await file.exists()) {
      await file.writeAsBytes(image, flush: true);
    }

    return file.path;
  }

  /// A folder name made only of safe characters from [clipId], which
  /// another device chose.
  static String folderNameOf(String clipId) {
    final safe = clipId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (safe.isEmpty || RegExp(r'^_+$').hasMatch(safe)) {
      return 'clip';
    }

    return safe.length > 64 ? safe.substring(0, 64) : safe;
  }

  static String fileNameOf(String name) {
    final safe = name.replaceAll(RegExp(r'[/\\:\x00-\x1f]'), ' ').trim();
    return switch (safe) {
      '' || '.' || '..' => 'Image',
      _ => safe,
    };
  }

  static String extensionOf(String mime) => switch (mime.toLowerCase()) {
    'image/jpeg' || 'image/jpg' => 'jpg',
    'image/gif' => 'gif',
    'image/tiff' => 'tiff',
    'image/heic' => 'heic',
    'image/webp' => 'webp',
    'image/bmp' => 'bmp',
    _ => 'png',
  };
}
