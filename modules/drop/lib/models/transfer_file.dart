/// One file in a transfer.
class TransferFile {
  const TransferFile({
    required this.name,
    required this.size,
    this.mime = '',
    this.location,
    this.folder,
    this.modified,
  });

  /// The file name people see. For received files, the name it was saved
  /// under, which may differ from the sender's when that one was taken.
  final String name;
  final int size;
  final String mime;

  /// Where the file is: the source path when sending, and once saved, the
  /// received file's path or `content://` URI.
  final String? location;

  /// The folder the file sits in when a whole folder travels, relative and
  /// separated by `/`, such as `Photos/2024`. Its first part is the folder
  /// that was sent; for received files, the name it was saved under, such
  /// as `Photos (2)`. Null for a file sent on its own.
  final String? folder;

  /// When the file was last modified, where the sender said.
  final DateTime? modified;

  /// The first part of [folder]: the folder that was sent.
  String? get rootFolder => switch (folder) {
    final path? when path.isNotEmpty => path.split('/').first,
    _ => null,
  };

  TransferFile copyWith({String? name, String? location, String? folder}) =>
      TransferFile(
        name: name ?? this.name,
        size: size,
        mime: mime,
        location: location ?? this.location,
        folder: folder ?? this.folder,
        modified: modified,
      );
}
