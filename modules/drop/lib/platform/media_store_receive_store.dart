import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/services.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:path/path.dart' as p;

/// Android 10 and newer: parts stay in app storage, and verified files move
/// into the shared Downloads folder through MediaStore.
class MediaStoreReceiveStore implements ReceiveStore {
  MediaStoreReceiveStore({
    required this.plugin,
    required this.folderName,
    required this.appDirectory,
  });

  final FerretDrop plugin;
  final String Function() folderName;
  final Future<String> Function() appDirectory;

  @override
  Future<Directory> partsDirectory() async {
    final parts = Directory(p.join(await appDirectory(), 'drop_partial'));
    await parts.create(recursive: true);
    return parts;
  }

  @override
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
  }) async {
    final saved = await plugin.saveToDownloads(
      sourcePath: part.path,
      fileName: name,
      mimeType: mime,
      folder: folderName(),
    );
    return ReceivedFile(location: saved.location, name: saved.name);
  }
}
