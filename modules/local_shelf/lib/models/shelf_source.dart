/// How a shelf item got there.
enum ShelfSource {
  /// Dragged onto the shelf: kept until the person takes it off.
  dropped,

  /// Copied to the clipboard: the oldest of these make room first.
  copied;

  static ShelfSource byName(Object? name) =>
      values.where((source) => source.name == name).firstOrNull ?? .copied;
}
