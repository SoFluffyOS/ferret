import 'package:interop_localsend/models/json_fields.dart';

/// One file's metadata in `/prepare-upload`.
class LocalSendFile {
  const LocalSendFile({
    required this.id,
    required this.fileName,
    required this.size,
    this.fileType = defaultType,
    this.sha256,
    this.preview,
    this.modified,
    this.accessed,
  });

  static const defaultType = 'application/octet-stream';

  /// How long a text message's [preview] may be. Longer previews are
  /// dropped; the text still arrives as the file.
  static const maxPreviewLength = 64 * 1024;

  final String id;

  /// The sender's name for the file. Never use it as a path.
  final String fileName;

  /// Bytes.
  final int size;

  /// A MIME type.
  final String fileType;

  /// Hex SHA-256 of the file, when the sender computed it.
  final String? sha256;

  /// For text messages, the text itself.
  final String? preview;
  final DateTime? modified;
  final DateTime? accessed;

  /// Whether this is a text message: a text file that carries its content
  /// as the preview.
  bool get isMessage => fileType.startsWith('text/') && preview != null;

  /// Reads one file entry, or returns null when it is malformed.
  static LocalSendFile? fromJson(Object? json) {
    final fields = JsonFields.object(json);
    if (fields == null) {
      return null;
    }

    final id = JsonFields.raw(fields['id'], max: 256);
    final fileName = JsonFields.raw(fields['fileName'], max: 4096);
    final size = JsonFields.integer(fields['size']);
    if (id == null || fileName == null || size == null || size < 0) {
      return null;
    }

    final metadata = JsonFields.object(fields['metadata']);
    return LocalSendFile(
      id: id,
      fileName: fileName,
      size: size,
      fileType: JsonFields.text(fields['fileType'], max: 128) ?? defaultType,
      sha256: JsonFields.raw(fields['sha256'], max: 128),
      preview: JsonFields.raw(fields['preview'], max: maxPreviewLength),
      modified: _time(metadata?['modified']),
      accessed: _time(metadata?['accessed']),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'fileName': fileName,
    'size': size,
    'fileType': fileType,
    'sha256': ?sha256,
    'preview': ?preview,
    if (modified != null || accessed != null)
      'metadata': {
        'modified': ?_text(modified),
        'accessed': ?_text(accessed),
      },
  };

  /// ISO 8601 in UTC, without the fraction when it is zero, as in the
  /// protocol's examples.
  static String? _text(DateTime? time) =>
      time?.toUtc().toIso8601String().replaceFirst('.000Z', 'Z');

  static DateTime? _time(Object? value) => switch (value) {
    final String text => DateTime.tryParse(text),
    _ => null,
  };
}
