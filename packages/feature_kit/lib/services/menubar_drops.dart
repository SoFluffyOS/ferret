import 'package:core/core.dart';

/// What a quick drop on the menubar icon does: one let go before the
/// popover springs open.
enum IconDrop {
  /// Goes to the only connected device, or the last one used.
  sendToLast,

  /// Stays on this computer, on the shelf.
  shelf,

  /// The popover opens at once, to drop on a device or the shelf there.
  ask;

  static IconDrop byName(String? name) => switch (name) {
    'shelf' => shelf,
    'ask' => ask,
    _ => sendToLast,
  };
}

/// How the menubar icon takes drags. Shown with the shelf's settings, kept
/// here because the app's icon reads them.
class MenubarDrops {
  const MenubarDrops(this._store);

  static const springKey = 'menubar.spring_loading';
  static const iconDropKey = 'menubar.icon_drop';

  final SettingsStore _store;

  /// A drag resting on the icon opens the popover, after the Mac's own
  /// spring-loading delay. On until turned off.
  bool get springLoading => _store.get<bool>(springKey) ?? true;

  IconDrop get iconDrop => IconDrop.byName(_store.get<String>(iconDropKey));

  Future<void> setSpringLoading(bool value) => _store.set(springKey, value);

  Future<void> setIconDrop(IconDrop value) =>
      _store.set(iconDropKey, value.name);

  /// Whether [key] is one of these settings.
  static bool owns(String key) => key == springKey || key == iconDropKey;
}
