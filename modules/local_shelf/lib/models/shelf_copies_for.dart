/// How long copies stay on the shelf. What the person dropped on it stays
/// until they take it off, whatever this says.
enum ShelfCopiesFor {
  /// Until Ferret quits.
  untilQuit(null),
  day(Duration(days: 1)),
  week(Duration(days: 7));

  const ShelfCopiesFor(this.keepsFor);

  /// How long a copy stays, or null when it stays until Ferret quits.
  final Duration? keepsFor;

  static ShelfCopiesFor byName(Object? name) =>
      values.where((value) => value.name == name).firstOrNull ?? untilQuit;
}
