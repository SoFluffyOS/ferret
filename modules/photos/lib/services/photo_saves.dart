import 'dart:async';

import 'package:photos/models/models.dart';

/// Photos coming to this computer, newest first, for Activity. Keeps the
/// last [keep] finished ones.
class PhotoSaves {
  PhotoSaves({this.keep = 12});

  final int keep;
  final List<PhotoSave> _saves = [];
  final StreamController<void> _changes = .broadcast();

  List<PhotoSave> get all => List.unmodifiable(_saves);

  Stream<void> get changes => _changes.stream;

  PhotoSave? operator [](String id) {
    for (final save in _saves) {
      if (save.id == id) {
        return save;
      }
    }

    return null;
  }

  void add(PhotoSave save) {
    _saves.insert(0, save);
    _trim();
    _changes.add(null);
  }

  void update(String id, PhotoSave Function(PhotoSave save) change) {
    final index = _saves.indexWhere((save) => save.id == id);
    if (index < 0) {
      return;
    }

    _saves[index] = change(_saves[index]);
    _changes.add(null);
  }

  void remove(String id) {
    _saves.removeWhere((save) => save.id == id);
    _changes.add(null);
  }

  /// Follows [progress] into the save [id] until it ends.
  Future<void> follow(String id, Stream<PhotoTransferProgress> progress) async {
    await for (final step in progress) {
      update(
        id,
        (save) => save.copyWith(
          status: step.status,
          fraction: step.fraction,
          paths: step.paths,
          problem: switch (step.status) {
            .failed => PhotoSaveProblem.failed,
            _ => null,
          },
        ),
      );
      if (step.status != .running) {
        return;
      }
    }

    if (this[id]?.status != .running) {
      return;
    }

    update(
      id,
      (save) => save.copyWith(status: .failed, problem: .failed),
    );
  }

  void _trim() {
    final finished = _saves.where((save) => save.status != .running).toList();
    if (finished.length <= keep) {
      return;
    }

    for (final old in finished.skip(keep)) {
      _saves.remove(old);
    }
  }

  Future<void> dispose() => _changes.close();
}
