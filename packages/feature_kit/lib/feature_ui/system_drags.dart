import 'package:flutter/widgets.dart';

/// What a drag in another app carries, judged by its types only: nothing
/// it holds is read before it is dropped.
enum SystemDragKind {
  /// Files, files an app promises (such as photos from Photos), or a
  /// picture.
  files,

  /// Text, such as words selected on a web page.
  text,

  /// A web link, such as a browser tab or a bookmark.
  link,
}

/// A screen, in the system's screen points with y going up from the
/// bottom of the main screen, as macOS counts them.
class SystemScreen {
  const SystemScreen({required this.frame, required this.visible});

  /// The whole screen.
  final Rect frame;

  /// What is left without the menu bar and the Dock.
  final Rect visible;

  /// Whether [point] is in the menu bar band at the top of this screen.
  bool isInMenuBar(Offset point) =>
      point.dy > visible.bottom && point.dy <= frame.bottom;

  @override
  bool operator ==(Object other) =>
      other is SystemScreen && other.frame == frame && other.visible == visible;

  @override
  int get hashCode => Object.hash(frame, visible);
}

/// One moment of a drag going on in another app.
sealed class SystemDragEvent {
  const SystemDragEvent();
}

/// A drag started: [kind] is what it carries, [sourceApp] the app it
/// started in (its bundle id on a Mac), when known.
class SystemDragStarted extends SystemDragEvent {
  const SystemDragStarted({
    required this.kind,
    required this.position,
    required this.screen,
    this.sourceApp,
    this.fn = false,
    this.shift = false,
  });

  final SystemDragKind kind;
  final String? sourceApp;
  final Offset position;
  final SystemScreen screen;

  /// Whether fn is held: the box that shows up by itself skips this drag.
  final bool fn;
  final bool shift;
}

/// The pointer moved with the drag, to [position] on [screen].
class SystemDragMoved extends SystemDragEvent {
  const SystemDragMoved({
    required this.position,
    required this.screen,
    this.fn = false,
    this.shift = false,
  });

  final Offset position;
  final SystemScreen screen;
  final bool fn;
  final bool shift;
}

/// The drag ended: dropped somewhere, or let go.
class SystemDragEnded extends SystemDragEvent {
  const SystemDragEnded();
}

/// Drags going on in other apps, seen from outside: where the pointer is
/// and what kind of thing is dragged, never what it holds. Ferret's own
/// drags don't show here. Watching asks the system for no permission.
abstract interface class SystemDrags {
  Stream<SystemDragEvent> get events;

  /// Starts or stops watching. Nothing is watched until asked.
  Future<void> watch({required bool on});

  /// The apps running now with a window, to pick ones whose drags are left
  /// alone.
  Future<List<SystemApp>> runningApps();
}

/// An app on this computer: its id (a bundle id on a Mac) and its name.
class SystemApp {
  const SystemApp({required this.id, required this.name});

  final String id;
  final String name;
}

/// How a floating panel comes in and goes out. With Reduce Motion on it
/// fades instead.
enum PanelMotion {
  /// Slides in from the screen's right edge.
  fromRight,

  /// Slides in from the screen's left edge.
  fromLeft,

  /// Fades in where it is, such as next to the pointer.
  inPlace,
}

/// A small panel that floats over every app and Space, full-screen apps
/// too, without taking the keyboard or bringing Ferret forward: such as
/// the shelf, shown while something is dragged. One at a time.
abstract interface class FloatingPanel {
  /// False where there is none.
  bool get canShow;

  /// Shows [builder] in a panel at [frame], in [SystemScreen] points, with
  /// corners of [radius]. Shown already, it moves there.
  Future<bool> show({
    required Rect frame,
    required PanelMotion motion,
    required double radius,
    required WidgetBuilder builder,
  });

  /// Takes the panel away, the way it came in.
  Future<void> hide();
}
