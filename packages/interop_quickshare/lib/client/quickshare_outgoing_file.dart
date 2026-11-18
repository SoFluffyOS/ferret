/// A file to send, with a way to read it.
class QuickShareOutgoingFile {
  const QuickShareOutgoingFile({
    required this.name,
    required this.size,
    required this.open,
    this.mimeType = 'application/octet-stream',
  });

  final String name;
  final int size;
  final String mimeType;

  /// Opens the content. It must yield exactly [size] bytes.
  final Stream<List<int>> Function() open;
}
