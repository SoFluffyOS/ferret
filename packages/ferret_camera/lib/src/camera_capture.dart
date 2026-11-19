import 'package:ferret_camera/src/capture_outcome.dart';

/// What came back from the camera.
class CameraCapture {
  const CameraCapture(this.outcome, {this.path, this.mimeType});

  const CameraCapture.taken(String this.path, {required String this.mimeType})
    : outcome = .taken;

  /// What the platform sent, or [CaptureOutcome.failed] when it makes no
  /// sense, such as a taken picture without a file.
  factory CameraCapture.fromMap(Object? map) {
    if (map is! Map) {
      return const CameraCapture(.failed);
    }

    final outcome = CaptureOutcome.byNameOr(map['outcome'] as String?);
    final path = map['path'];
    final mimeType = map['mimeType'];
    if (outcome != .taken) {
      return CameraCapture(outcome);
    }

    if (path is! String || path.isEmpty) {
      return const CameraCapture(.failed);
    }

    return CameraCapture.taken(
      path,
      mimeType: switch (mimeType) {
        final String type when type.isNotEmpty => type,
        _ => 'image/jpeg',
      },
    );
  }

  final CaptureOutcome outcome;

  /// The temporary file holding the picture, when [outcome] is taken.
  /// Whoever sends it deletes it afterwards.
  final String? path;

  /// Such as `image/jpeg`, or `application/pdf` for a scan of several
  /// pages.
  final String? mimeType;
}
