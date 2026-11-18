import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/platform/media_store_receive_store.dart';
import 'package:drop/platform/receive_folders.dart';
import 'package:drop/services/services.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_drop/ferret_drop.dart';

/// Picks the right [ReceiveStore] for this device: MediaStore Downloads on
/// Android 10+, otherwise a plain folder.
class PlatformReceiveStore implements ReceiveStore {
  PlatformReceiveStore(this.settings, {FerretDrop? plugin})
    : _plugin = plugin ?? FerretDrop();

  final SettingsStore settings;
  final FerretDrop _plugin;
  Future<ReceiveStore>? _store;

  @override
  Future<Directory> partsDirectory() async =>
      (await _resolve()).partsDirectory();

  @override
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
  }) async => (await _resolve()).save(part, name: name, mime: mime);

  Future<ReceiveStore> _resolve() => _store ??= _pick();

  Future<ReceiveStore> _pick() async {
    if (Platform.isAndroid && await _plugin.canSaveToDownloads()) {
      return MediaStoreReceiveStore(
        plugin: _plugin,
        folderName: () => ReceiveFolders.folderName(settings),
        appDirectory: () async {
          final paths = await AppPaths.get();
          return (await paths.create(paths.cache)).path;
        },
      );
    }

    return FolderReceiveStore(() => ReceiveFolders.path(settings));
  }
}
