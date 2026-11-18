/// One file in a transfer.
class TransferFile {
  const TransferFile({
    required this.name,
    required this.size,
    this.mime = '',
    this.location,
  });

  /// The file name people see. For received files, the name it was saved
  /// under, which may differ from the sender's when that one was taken.
  final String name;
  final int size;
  final String mime;

  /// Where the file is: the source path when sending, and once saved, the
  /// received file's path or `content://` URI.
  final String? location;

  TransferFile copyWith({String? name, String? location}) => TransferFile(
    name: name ?? this.name,
    size: size,
    mime: mime,
    location: location ?? this.location,
  );
}
