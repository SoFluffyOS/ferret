import 'package:interop_localsend/models/json_fields.dart';

/// The receiver's answer to `/prepare-upload`: a session, and one token for
/// each file it wants.
class PrepareUploadResponse {
  const PrepareUploadResponse({required this.sessionId, required this.files});

  final String sessionId;

  /// Tokens by file id. Files the receiver skipped are missing.
  final Map<String, String> files;

  static PrepareUploadResponse? fromJson(Object? json) {
    final fields = JsonFields.object(json);
    final sessionId = JsonFields.raw(fields?['sessionId'], max: 256);
    final entries = JsonFields.object(fields?['files']);
    if (sessionId == null || entries == null) {
      return null;
    }

    final tokens = <String, String>{};
    for (final entry in entries.entries) {
      final token = JsonFields.raw(entry.value);
      if (token == null) {
        return null;
      }

      tokens[entry.key] = token;
    }

    return PrepareUploadResponse(sessionId: sessionId, files: tokens);
  }

  Map<String, Object?> toJson() => {'sessionId': sessionId, 'files': files};
}
