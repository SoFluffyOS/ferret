import 'package:interop_localsend/models/models.dart';

/// A file to send: what to announce, and how to read it.
class LocalSendOutgoingFile {
  const LocalSendOutgoingFile({required this.file, required this.open});

  final LocalSendFile file;

  /// Opens the content. It must be exactly [LocalSendFile.size] bytes.
  final Stream<List<int>> Function() open;
}
