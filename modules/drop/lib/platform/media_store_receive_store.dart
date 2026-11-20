import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/services.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Android 10 and newer: parts stay in app storage, and verified files move
/// into the shared Downloads folder through MediaStore.
class MediaStoreReceiveStore implements ReceiveStore {
  MediaStoreReceiveStore({
    required this.plugin,
    required this.folderName,
    required this.appDirectory,
    this.downloadsDirectory = _sharedDownloads,
  });

  final FerretDrop plugin;
  final String Function() folderName;
  final Future<String> Function() appDirectory;

  /// The shared Downloads folder as a path, to see which folder names are
  /// taken. MediaStore can't list folders other apps made.
  final Future<String?> Function() downloadsDirectory;

  static const _maxAttempts = 10000;
  final Set<String> _claimed = {};

  @override
  Future<Directory> partsDirectory() async {
    final parts = Directory(p.join(await appDirectory(), 'drop_partial'));
    await parts.create(recursive: true);
    return parts;
  }

  @override
  Future<String> reserveFolder(String name) async {
    final downloads = await downloadsDirectory();
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final candidate = FileNames.numberedFolder(name, attempt);
      final relative = '${folderName()}/$candidate';
      if (_claimed.contains(relative)) {
        continue;
      }

      if (downloads != null &&
          await FileSystemEntity.type(p.join(downloads, relative)) !=
              FileSystemEntityType.notFound) {
        continue;
      }

      _claimed.add(relative);
      return candidate;
    }

    throw FileSystemException('No free name for the received folder', name);
  }

  @override
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
    String? folder,
    DateTime? modified,
  }) async {
    final saved = await plugin.saveToDownloads(
      sourcePath: part.path,
      fileName: name,
      mimeType: mime,
      folder: [folderName(), ?folder].join('/'),
    );
    return ReceivedFile(location: saved.location, name: saved.name);
  }

  /// Parts and the shared Downloads folder sit on the same storage, so the
  /// parts folder tells for both.
  @override
  Future<int?> freeBytes() async => FreeSpace.of((await partsDirectory()).path);

  @override
  Future<bool> copiesOnSave() async => true;

  /// `/storage/emulated/0/Download`, found from the app's own external
  /// folder, which sits under the same storage root.
  static Future<String?> _sharedDownloads() async {
    const marker = '/Android/data/';
    final own = (await getExternalStorageDirectory())?.path;
    if (own == null || !own.contains(marker)) {
      return null;
    }

    return p.join(own.substring(0, own.indexOf(marker)), 'Download');
  }
}
