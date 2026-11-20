import 'package:ferret_menubar/src/messages.g.dart';

/// A drag going on in another app, as the Mac sees it from outside.
sealed class MenubarSystemDragEvent {
  const MenubarSystemDragEvent();
}

/// A drag started: what it carries by its types, where, and in which app.
final class MenubarSystemDragStarted extends MenubarSystemDragEvent {
  const MenubarSystemDragStarted(this.drag);

  final MenubarSystemDrag drag;
}

/// The pointer moved with the drag.
final class MenubarSystemDragMoved extends MenubarSystemDragEvent {
  const MenubarSystemDragMoved(this.point);

  final MenubarDragPoint point;
}

/// The drag was dropped or let go.
final class MenubarSystemDragEnded extends MenubarSystemDragEvent {
  const MenubarSystemDragEnded();
}
