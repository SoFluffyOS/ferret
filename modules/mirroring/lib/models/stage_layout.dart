import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:mirroring/models/toolbar_place.dart';

/// Where the toolbar goes in a space that is not the picture's own
/// window: under the picture or beside it, whichever leaves the picture
/// bigger. The picture gives way to the toolbar, never the other way.
abstract final class StageLayout {
  /// The place for a toolbar next to a picture of [picture]'s shape in
  /// [space]: [belowExtent] is how tall the toolbar is under the picture,
  /// [besideExtent] how wide it is beside it. A small screen keeps it
  /// under the picture, where the thumb is.
  static ToolbarPlace placeFor({
    required Size space,
    required Size picture,
    required double belowExtent,
    required double besideExtent,
    bool isSmall = false,
  }) {
    if (isSmall) {
      return .below;
    }

    final below = _scale(
      Size(space.width, space.height - belowExtent),
      picture,
    );
    final beside = _scale(
      Size(space.width - besideExtent, space.height),
      picture,
    );
    if (beside > below) {
      return .beside;
    }

    return .below;
  }

  /// How big [picture] can be drawn in [room], whole.
  static double _scale(Size room, Size picture) {
    if (picture.isEmpty || room.width <= 0 || room.height <= 0) {
      return 0;
    }

    return math.min(room.width / picture.width, room.height / picture.height);
  }
}
