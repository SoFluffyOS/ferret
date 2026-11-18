/// One file a sender announced in its introduction.
class QuickShareFile {
  const QuickShareFile({
    required this.payloadId,
    required this.name,
    required this.size,
    this.mimeType = 'application/octet-stream',
  });

  /// The id the file's chunks carry on the connection.
  final int payloadId;

  /// The sender's name for the file. Never trusted as a path.
  final String name;
  final int size;
  final String mimeType;
}
