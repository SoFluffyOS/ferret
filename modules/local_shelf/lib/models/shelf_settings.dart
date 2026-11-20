import 'package:core/core.dart';
import 'package:local_shelf/models/shelf_copies_for.dart';
import 'package:local_shelf/models/shelf_reach_options.dart';

/// The shelf's settings, stored under `shelf.*`.
class ShelfSettings {
  const ShelfSettings(this._store);

  static const keepCopiesKey = 'shelf.keep_copies';
  static const copiesForKey = 'shelf.copies_for';
  static const boxOnDragKey = 'shelf.box_on_drag';
  static const boxShowsKey = 'shelf.box_shows';
  static const shakeKey = 'shelf.shake';
  static const shakeSensitivityKey = 'shelf.shake_sensitivity';
  static const shiftSummonsKey = 'shelf.shift_summons';
  static const ignoredAppsKey = 'shelf.ignored_apps';

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

  /// The ways to reach the shelf while dragging, with their defaults: the
  /// box that shows up by itself is off, the shake is on.
  ShelfReachOptions get reach => ShelfReachOptions(
    boxOnDrag: _store.get<bool>(boxOnDragKey) ?? false,
    boxShows: ShelfBoxShows.byName(_store.get<String>(boxShowsKey)),
    shake: _store.get<bool>(shakeKey) ?? true,
    sensitivity: ShakeSensitivity.byName(
      _store.get<String>(shakeSensitivityKey),
    ),
    shiftSummons: _store.get<bool>(shiftSummonsKey) ?? false,
    ignoredApps: [
      for (final app in _store.get<List<Object?>>(ignoredAppsKey) ?? const [])
        ?IgnoredApp.fromJson(app),
    ],
  );

  Future<void> setBoxOnDrag(bool value) => _store.set(boxOnDragKey, value);

  Future<void> setBoxShows(ShelfBoxShows value) =>
      _store.set(boxShowsKey, value.name);

  Future<void> setShake(bool value) => _store.set(shakeKey, value);

  Future<void> setShakeSensitivity(ShakeSensitivity value) =>
      _store.set(shakeSensitivityKey, value.name);

  Future<void> setShiftSummons(bool value) =>
      _store.set(shiftSummonsKey, value);

  Future<void> setIgnoredApps(List<IgnoredApp> apps) => _store.set(
    ignoredAppsKey,
    [for (final app in apps) app.toJson()],
  );

  /// Fires with the key of each shelf setting that changed.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('shelf.'));
}
