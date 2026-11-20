/// What a shelf item is.
enum ShelfKind {
  file,
  folder,
  image,
  text,
  link;

  static ShelfKind byName(Object? name) =>
      values.where((kind) => kind.name == name).firstOrNull ?? .file;
}
