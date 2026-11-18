import 'package:interop_localsend/models/json_fields.dart';
import 'package:interop_localsend/models/localsend_file.dart';
import 'package:interop_localsend/models/localsend_info.dart';

/// The body of `/prepare-upload`: who sends, and what.
class PrepareUploadRequest {
  const PrepareUploadRequest({required this.info, required this.files});

  static const maxFiles = 10000;

  final LocalSendInfo info;

  /// Files by id, in the order the sender listed them.
  final Map<String, LocalSendFile> files;

  int get totalBytes => files.values.fold(0, (sum, file) => sum + file.size);

  /// Reads the request, or returns null when it is malformed, empty or
  /// lists more than [maxFiles] files.
  static PrepareUploadRequest? fromJson(Object? json) {
    final fields = JsonFields.object(json);
    final info = LocalSendInfo.fromJson(fields?['info']);
    final entries = JsonFields.object(fields?['files']);
    if (info == null || entries == null) {
      return null;
    }

    if (entries.isEmpty || entries.length > maxFiles) {
      return null;
    }

    final files = <String, LocalSendFile>{};
    for (final entry in entries.entries) {
      final file = LocalSendFile.fromJson(entry.value);
      if (file == null || file.id != entry.key) {
        return null;
      }

      files[entry.key] = file;
    }

    return PrepareUploadRequest(info: info, files: files);
  }

  Map<String, Object?> toJson() => {
    'info': info.toJson(),
    'files': {
      for (final file in files.values) file.id: file.toJson(),
    },
  };
}
