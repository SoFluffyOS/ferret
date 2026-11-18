import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';

/// Finds the drop target under a point of one of the app's views.
abstract interface class DropTargetFinder {
  FilesDropTarget? find(Offset position);
}

/// Hit-tests one view and takes the innermost widget tagged with a
/// [FilesDropTarget] (see `DropTargetRegion`). [viewId] names the view at
/// the time of the drag; without it the app's only view is tested.
class RenderTreeDropTargetFinder implements DropTargetFinder {
  const RenderTreeDropTargetFinder({this.viewId});

  final int? Function()? viewId;

  @override
  FilesDropTarget? find(Offset position) {
    final binding = WidgetsBinding.instance;
    final tested =
        viewId?.call() ?? binding.platformDispatcher.implicitView?.viewId;
    if (tested == null) {
      return null;
    }

    final result = HitTestResult();
    binding.hitTestInView(result, position, tested);

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
