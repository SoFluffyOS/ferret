import 'dart:ui';

/// Something that happened while files were dragged over one of the app's
/// views: the popover's or the desktop window's. Positions are logical
/// pixels from that view's top left.
sealed class PopoverDrag {
  const PopoverDrag(this.viewId);

  /// The Flutter view the drag is over.
  final int viewId;
}

/// Files came into the view.
final class PopoverDragEntered extends PopoverDrag {
  const PopoverDragEntered(super.viewId, this.position, this.fileCount);

  final Offset position;
  final int fileCount;
}

/// The pointer moved while dragging files over the view.
final class PopoverDragMoved extends PopoverDrag {
  const PopoverDragMoved(super.viewId, this.position);

  final Offset position;
}

/// The drag left the view or was cancelled.
final class PopoverDragExited extends PopoverDrag {
  const PopoverDragExited(super.viewId);
}

/// The files were dropped on the view at [position].
final class PopoverDragDropped extends PopoverDrag {
  const PopoverDragDropped(super.viewId, this.paths, this.position);

  final List<String> paths;
  final Offset position;
}
