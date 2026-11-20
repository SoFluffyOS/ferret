/// When the box shows up by itself during a drag.
enum ShelfBoxShows {
  /// Once the drag comes near the screen's edge.
  atEdge,

  /// As soon as a drag starts.
  onDrag;

  static ShelfBoxShows byName(Object? name) =>
      values.where((value) => value.name == name).firstOrNull ?? atEdge;
}

/// How hard a shake has to be to bring the box.
enum ShakeSensitivity {
  low,
  normal,
  high;

  static ShakeSensitivity byName(Object? name) =>
      values.where((value) => value.name == name).firstOrNull ?? normal;
}

/// An app whose drags never bring the box, by bundle id, with its name to
/// show.
class IgnoredApp {
  const IgnoredApp({required this.id, required this.name});

  final String id;
  final String name;

  static IgnoredApp? fromJson(Object? json) => switch (json) {
    {'id': final String id, 'name': final String name} => IgnoredApp(
      id: id,
      name: name,
    ),
    _ => null,
  };

  Map<String, String> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is IgnoredApp && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The ways to reach the shelf while dragging something in another app,
/// as Settings → Shelf has them.
class ShelfReachOptions {
  const ShelfReachOptions({
    this.boxOnDrag = false,
    this.boxShows = .atEdge,
    this.shake = true,
    this.sensitivity = .normal,
    this.shiftSummons = false,
    this.ignoredApps = const [],
  });

  /// The box comes in from the screen's edge during a drag of files.
  final bool boxOnDrag;
  final ShelfBoxShows boxShows;

  /// A shake during a drag brings the box next to the pointer.
  final bool shake;
  final ShakeSensitivity sensitivity;

  /// Holding ⇧ during a drag brings it too, for anyone who can't shake.
  final bool shiftSummons;

  /// Drags from these apps never bring it.
  final List<IgnoredApp> ignoredApps;

  /// Whether drags need watching at all.
  bool get watchesDrags => boxOnDrag || shake || shiftSummons;

  bool ignores(String? app) =>
      app != null && ignoredApps.any((ignored) => ignored.id == app);
}
