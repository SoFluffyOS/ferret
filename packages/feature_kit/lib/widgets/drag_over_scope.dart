import 'package:flutter/widgets.dart';

/// Tells what sits under it that files or text are being dragged over its
/// view right now, such as the popover's bar, which may only show up for a
/// drag.
class DragOverScope extends InheritedWidget {
  const DragOverScope({
    super.key,
    required this.isDragging,
    required super.child,
  });

  final bool isDragging;

  /// False where no scope says otherwise.
  static bool isDraggingIn(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DragOverScope>()?.isDragging ??
      false;

  @override
  bool updateShouldNotify(DragOverScope oldWidget) =>
      oldWidget.isDragging != isDragging;
}
