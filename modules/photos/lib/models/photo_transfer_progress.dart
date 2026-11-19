/// Where a transfer of photos stands.
enum PhotoTransferStatus { running, done, failed }

/// How a transfer of full photos goes, as the app's file transfer reports
/// it.
class PhotoTransferProgress {
  const PhotoTransferProgress({
    required this.status,
    this.fraction = 0,
    this.paths = const [],
  });

  final PhotoTransferStatus status;

  /// From 0 to 1.
  final double fraction;

  /// Where the files were saved on this device, once done.
  final List<String> paths;
}
