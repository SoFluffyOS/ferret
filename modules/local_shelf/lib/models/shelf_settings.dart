import 'package:core/core.dart';
import 'package:local_shelf/models/shelf_copies_for.dart';

/// The shelf's settings, stored under `shelf.*`.
class ShelfSettings {
  const ShelfSettings(this._store);

  static const keepCopiesKey = 'shelf.keep_copies';
  static const copiesForKey = 'shelf.copies_for';

  final SettingsStore _store;

  /// Puts what is copied here, or arrives from another device, on the
  /// shelf. Off until the person turns it on: the clipboard isn't watched
  /// for the shelf before that.
  bool get keepCopies => _store.get<bool>(keepCopiesKey) ?? false;

  /// How long those copies stay.
  ShelfCopiesFor get copiesFor =>
      ShelfCopiesFor.byName(_store.get<String>(copiesForKey));

  Future<void> setKeepCopies(bool value) => _store.set(keepCopiesKey, value);

  Future<void> setCopiesFor(ShelfCopiesFor value) =>
      _store.set(copiesForKey, value.name);

  /// Fires with the key of each shelf setting that changed.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('shelf.'));
}
