/// Where the transfer carrying a picture stands.
enum CaptureTransferStatus { running, done, failed }

/// How the transfer carrying a picture goes, as the app's file transfer
/// reports it.
class CaptureTransferProgress {
  const CaptureTransferProgress({
    required this.status,
    this.fraction = 0,
    this.paths = const [],
  });

  final CaptureTransferStatus status;

  /// From 0 to 1.
  final double fraction;

  /// Where the file was saved on this device, once done.
  final List<String> paths;
}
