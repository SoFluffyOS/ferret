import 'package:protocol/photos.dart';

/// Why a page of photos couldn't be read from a phone.
enum PhotoListProblem {
  /// The phone isn't connected.
  offline,

  /// The phone's Ferret has no Photos, or is too old for it.
  unsupported,

  /// The phone didn't answer in time, or the answer was broken.
  failed,
}

/// What a phone answered to a page request.
class PhotoListResult {
  const PhotoListResult({
    this.items = const [],
    this.nextCursor,
    this.access = .PHOTO_ACCESS_UNSPECIFIED,
    this.total = 0,
    this.problem,
  });

  const PhotoListResult.failed(PhotoListProblem this.problem)
    : items = const [],
      nextCursor = null,
      access = .PHOTO_ACCESS_UNSPECIFIED,
      total = 0;

  final List<PhotoItem> items;

  /// Where the next page starts, or null after the last one.
  final String? nextCursor;
  final PhotoAccess access;

  /// How many the phone shares in all, or 0 when it didn't say.
  final int total;
  final PhotoListProblem? problem;
}
