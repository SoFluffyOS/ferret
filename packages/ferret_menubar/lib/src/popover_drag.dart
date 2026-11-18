import 'dart:ui';

/// Something that happened while files were dragged over the popover.
/// Positions are logical pixels from the popover's top left.
sealed class PopoverDrag {
  const PopoverDrag();
}

/// Files came into the popover.
final class PopoverDragEntered extends PopoverDrag {
  const PopoverDragEntered(this.position, this.fileCount);

  final Offset position;
  final int fileCount;
}

/// The pointer moved while dragging files over the popover.
final class PopoverDragMoved extends PopoverDrag {
  const PopoverDragMoved(this.position);

  final Offset position;
}

/// The drag left the popover or was cancelled.
final class PopoverDragExited extends PopoverDrag {
  const PopoverDragExited();
}

/// The files were dropped on the popover at [position].
final class PopoverDragDropped extends PopoverDrag {
  const PopoverDragDropped(this.paths, this.position);

  final List<String> paths;
  final Offset position;
}
