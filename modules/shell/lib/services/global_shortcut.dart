import 'package:core/core.dart';
import 'package:ferret_menubar/ferret_menubar.dart';

/// The keys that open the menubar popover from any app, kept in settings
/// under [key]: ⌃⌥Space until the person picks others or turns it off.
abstract final class GlobalShortcut {
  static const key = 'shell.global_shortcut';

  /// Stored in place of a shortcut when the person turned it off.
  static const off = 'off';

  /// ⌃⌥Space: Spotlight takes ⌘Space, and ⌃Space switches input sources.
  static final MenubarShortcut fallback = MenubarShortcut(
    keyCode: 49,
    label: '⌃⌥Space',
    control: true,
    option: true,
  );

  /// ⌃⌥V: Recent clips from any app, next to ⌃⌥Space for the popover.
  static final MenubarShortcut recentClips = MenubarShortcut(
    keyCode: 9,
    label: '⌃⌥V',
    control: true,
    option: true,
  );

  /// The shortcut in [settings], the default when none was picked, or
  /// null when it is off.
  static MenubarShortcut? read(SettingsStore settings) {
    final stored = settings.get<Object>(key);

    return switch (stored) {
      off => null,
      {
        'key_code': final int keyCode,
        'label': final String label,
        'command': final bool command,
        'control': final bool control,
        'option': final bool option,
        'shift': final bool shift,
      } =>
        MenubarShortcut(
          keyCode: keyCode,
          label: label,
          command: command,
          control: control,
          option: option,
          shift: shift,
        ),
      _ => fallback,
    };
  }

  /// Keeps [shortcut], or turns the global shortcut off when it is null.
  static Future<void> write(
    SettingsStore settings,
    MenubarShortcut? shortcut,
  ) async {
    final value = switch (shortcut) {
      null => off,
      final shortcut => {
        'key_code': shortcut.keyCode,
        'label': shortcut.label,
        'command': shortcut.command,
        'control': shortcut.control,
        'option': shortcut.option,
        'shift': shortcut.shift,
      },
    };

    await settings.set(key, value);
  }
}
