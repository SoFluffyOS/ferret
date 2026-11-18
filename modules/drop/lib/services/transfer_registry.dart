import 'dart:async';

import 'package:drop/models/models.dart';

/// Every transfer this device knows, newest first, with change events. All
/// transports report here, so the UI and notices see one list.
class TransferRegistry {
  TransferRegistry({this.keepFinished = 20});

  /// How many finished transfers stay in the list.
  final int keepFinished;

  final Map<String, Transfer> _transfers = {};
  final StreamController<Transfer> _updates = .broadcast();
  final StreamController<List<Transfer>> _changes = .broadcast();

  /// Newest first.
  List<Transfer> get all {
    final sorted = [..._transfers.values]
      ..sort((first, second) => second.startedAt.compareTo(first.startedAt));
    return List.unmodifiable(sorted);
  }

  /// Each transfer as it changes.
  Stream<Transfer> get updates => _updates.stream;

  /// The whole list after each change.
  Stream<List<Transfer>> get changes => _changes.stream;

  Transfer? operator [](String id) => _transfers[id];

  /// Adds or replaces [transfer] and tells listeners.
  void put(Transfer transfer) {
    _transfers[transfer.id] = transfer;
    _trimFinished();
    _updates.add(transfer);
    _changes.add(all);
  }

  /// Applies [change] to the transfer with [id], if it is still listed.
  Transfer? update(String id, Transfer Function(Transfer current) change) {
    final current = _transfers[id];
    if (current == null) {
      return null;
    }

    final next = change(current);
    put(next);
    return next;
  }

  void remove(String id) {
    if (_transfers.remove(id) == null) {
      return;
    }

    _changes.add(all);
  }

  /// Drops every finished transfer from the list.
  void clearFinished() {
    _transfers.removeWhere((_, transfer) => !transfer.status.isActive);
    _changes.add(all);
  }

  Future<void> dispose() async {
    await _updates.close();
    await _changes.close();
  }

  void _trimFinished() {
    final finished = [
      for (final transfer in all)
        if (!transfer.status.isActive) transfer,
    ];
    for (final old in finished.skip(keepFinished)) {
      _transfers.remove(old.id);
    }
  }
}
