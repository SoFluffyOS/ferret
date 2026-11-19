import 'package:drop/services/folder_paths.dart';
import 'package:drop/services/receive_store.dart';

/// Where the files of one incoming transfer go, folder by folder. Built from
/// what the sender said, checked before anything is accepted, and placed
/// once accepted: each folder that was sent gets a new folder here.
class FolderPlan {
  FolderPlan._(this._parts);

  final List<List<String>> _parts;

  /// Reads the sender's folder for each file, or returns null when any of
  /// them is hostile, so the whole offer is refused.
  static FolderPlan? parse(Iterable<String> folders) {
    final parts = <List<String>>[];
    for (final folder in folders) {
      final cleaned = FolderPaths.parts(folder);
      if (cleaned == null) {
        return null;
      }

      parts.add(cleaned);
    }

    return FolderPlan._(parts);
  }

  bool get hasFolders => _parts.any((parts) => parts.isNotEmpty);

  /// The cleaned folders as the sender named them, to show before the
  /// folder names here are known.
  List<String?> get remote => [
    for (final parts in _parts) FolderPaths.join(parts),
  ];

  /// Claims a new folder here for each folder that was sent and returns the
  /// folder of each file inside the receive folder, null for loose files.
  Future<List<String?>> place(ReceiveStore store) async {
    final roots = <String, String>{};
    for (final parts in _parts) {
      if (parts case [final root, ...] when !roots.containsKey(root)) {
        roots[root] = await store.reserveFolder(root);
      }
    }

    return [
      for (final parts in _parts)
        switch (parts) {
          [final root, ...] => FolderPaths.join(
            FolderPaths.rooted(parts, roots[root] ?? root),
          ),
          _ => null,
        },
    ];
  }
}
