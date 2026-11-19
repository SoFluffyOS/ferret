/// What a photo library item is.
enum PhotoEntryKind {
  photo,
  screenshot,
  video;

  /// The kind named [name], or [photo] for anything unknown.
  static PhotoEntryKind byNameOr(String? name) {
    for (final kind in values) {
      if (kind.name == name) {
        return kind;
      }
    }

    return photo;
  }
}
