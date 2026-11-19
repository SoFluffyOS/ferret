import 'package:photos/models/photo_transfer_progress.dart';

/// Why saving photos from a phone didn't work.
enum PhotoSaveProblem {
  offline,
  notAllowed,
  noPermission,
  missing,
  failed,
}

/// Photos coming from a phone to this computer: ones the person saved, or
/// a screenshot that came by itself. One line in Activity.
class PhotoSave {
  const PhotoSave({
    required this.id,
    required this.deviceId,
    required this.count,
    required this.startedAt,
    this.isScreenshot = false,
    this.status = .running,
    this.fraction = 0,
    this.paths = const [],
    this.problem,
  });

  final String id;
  final String deviceId;
  final int count;
  final DateTime startedAt;
  final bool isScreenshot;
  final PhotoTransferStatus status;
  final double fraction;
  final List<String> paths;
  final PhotoSaveProblem? problem;

  PhotoSave copyWith({
    PhotoTransferStatus? status,
    double? fraction,
    List<String>? paths,
    PhotoSaveProblem? problem,
    int? count,
  }) => PhotoSave(
    id: id,
    deviceId: deviceId,
    count: count ?? this.count,
    startedAt: startedAt,
    isScreenshot: isScreenshot,
    status: status ?? this.status,
    fraction: fraction ?? this.fraction,
    paths: paths ?? this.paths,
    problem: problem ?? this.problem,
  );
}
