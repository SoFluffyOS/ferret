import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:ferret/wiring/photo_transfers.dart';
import 'package:phone_camera/phone_camera.dart';
import 'package:photos/photos.dart';

/// Carries a phone's picture through drop's transfers, the same way as a
/// saved photo: accepted without asking (this computer asked for it), its
/// Files line taken away once it ends.
class DropCaptureTransfers implements CaptureTransfers {
  DropCaptureTransfers(DropFeature drop) : _photos = DropPhotoTransfers(drop);

  final DropPhotoTransfers _photos;

  @override
  Future<String?> send(String deviceId, String path) =>
      _photos.send(deviceId, [path]);

  @override
  Stream<CaptureTransferProgress> follow(String transferId) =>
      _photos.follow(transferId).map(progressOf);

  /// [progress] as the camera sees it.
  static CaptureTransferProgress progressOf(PhotoTransferProgress progress) =>
      CaptureTransferProgress(
        status: switch (progress.status) {
          .running => .running,
          .done => .done,
          .failed => .failed,
        },
        fraction: progress.fraction,
        paths: progress.paths,
      );
}

/// Puts a phone's picture on this computer's clipboard through the
/// clipboard feature, which then doesn't send it back out.
class ClipboardCapturePaste implements CapturePaste {
  ClipboardCapturePaste(this._clipboard);

  final ClipboardFeature _clipboard;

  @override
  Future<bool> putImage(Uint8List image, {required String mimeType}) =>
      _clipboard.putOnClipboard(.image(image, imageMime: mimeType));
}

/// Joins the camera to drop and the clipboard. Features never import each
/// other, so the app does it here.
abstract final class CameraLinks {
  static void attach(FerretEngine engine) {
    final camera = engine.feature<CameraFeature>();
    if (camera == null) {
      return;
    }

    if (engine.feature<DropFeature>() case final drop?) {
      camera.transfers = DropCaptureTransfers(drop);
    }

    if (engine.feature<ClipboardFeature>() case final clipboard?) {
      camera.paste = ClipboardCapturePaste(clipboard);
    }
  }
}
