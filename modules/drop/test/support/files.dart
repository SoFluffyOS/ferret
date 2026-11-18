import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drop/drop.dart';
import 'package:path/path.dart' as p;

/// Writes [size] random bytes to [name] in [folder].
Future<File> randomFile(Directory folder, String name, int size) async {
  final random = Random(size);
  final bytes = Uint8List.fromList([
    for (var index = 0; index < size; index++) random.nextInt(256),
  ]);
  final file = File(p.join(folder.path, name));
  await file.writeAsBytes(bytes);
  return file;
}

ReceiveStoreFactory folderStore(Directory folder) =>
    (_) => FolderReceiveStore(() async => folder.path);

/// Part files still in [folder]'s hidden parts folder.
List<String> partFiles(Directory folder) {
  final parts = Directory(p.join(folder.path, '.ferret-partial'));
  if (!parts.existsSync()) {
    return const [];
  }

  return [for (final entity in parts.listSync()) p.basename(entity.path)];
}

/// Waits until [condition] holds, polling briefly.
Future<void> until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Condition not met in $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
