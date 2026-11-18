import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';

/// Finds the drop target under a point of the app's window.
abstract interface class DropTargetFinder {
  FilesDropTarget? find(Offset position);
}

/// Hit-tests the app's view and takes the innermost widget tagged with a
/// [FilesDropTarget] (see `DropTargetRegion`).
class RenderTreeDropTargetFinder implements DropTargetFinder {
  const RenderTreeDropTargetFinder();

  @override
  FilesDropTarget? find(Offset position) {
    final binding = WidgetsBinding.instance;
    final view = binding.platformDispatcher.implicitView;
    if (view == null) {
      return null;
    }

    final result = HitTestResult();
    binding.hitTestInView(result, position, view.viewId);

    for (final entry in result.path) {
      final renderObject = entry.target;
      if (renderObject case RenderMetaData(
        metaData: final FilesDropTarget target,
      )) {
        return target;
      }
    }

    return null;
  }
}
