/// A received file once it was saved.
class ReceivedFile {
  const ReceivedFile({required this.location, required this.name});

  /// A file path or a `content://` URI.
  final String location;

  /// The name it was saved under.
  final String name;
}
