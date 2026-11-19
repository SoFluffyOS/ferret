/// One file a sender announced in its introduction.
class QuickShareFile {
  const QuickShareFile({
    required this.payloadId,
    required this.name,
    required this.size,
    this.mimeType = 'application/octet-stream',
    this.parentFolder = '',
  });

  /// The id the file's chunks carry on the connection.
  final int payloadId;

  /// The sender's name for the file. Never trusted as a path.
  final String name;
  final int size;
  final String mimeType;

  /// The folder the file sits in when the sender shares a folder, relative
  /// and as the sender wrote it, or empty. Never trusted as a path either.
  final String parentFolder;
}
