import 'dart:io';

import 'package:drop/models/models.dart';

/// Where received files land. Transports write each file to a part file in
/// [partsDirectory], then [save] moves it in place once it verified. Other
/// transports, such as LocalSend later, use the same store.
abstract interface class ReceiveStore {
  /// A folder for files still arriving. Parts stay there across dropped
  /// sessions so transfers can resume.
  Future<Directory> partsDirectory();

  /// Moves a verified [part] to its final place as [name] (already made
  /// safe), never overwriting an existing file.
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
  });
}
