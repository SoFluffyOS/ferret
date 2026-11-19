/// A file to send, with a way to read it.
class QuickShareOutgoingFile {
  const QuickShareOutgoingFile({
    required this.name,
    required this.size,
    required this.open,
    this.mimeType = 'application/octet-stream',
    this.parentFolder = '',
  });

  final String name;
  final int size;
  final String mimeType;

  /// The folder the file sits in when a folder is shared, or empty.
  final String parentFolder;

  /// Opens the content. It must yield exactly [size] bytes.
  final Stream<List<int>> Function() open;
}
