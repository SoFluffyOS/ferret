import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Something the window can be told to do, from a key, a menu or a button.
enum WindowCommand {
  addDevice,
  sendFiles,
  sendClipboard,
  takePhoto,
  openSettings,
  openActivity,
  toggleSidebar,
  toggleActivityPane,
  nextDevice,
  previousDevice,
  back,
  fixConnection,
  showShortcuts,
  sponsor,
  quit,
}

class WindowCommandIntent extends Intent {
  const WindowCommandIntent(this.command);

  final WindowCommand command;
}

/// Opens a section of the selected device by its place in the device list:
/// Overview is 0.
class SelectSectionIntent extends Intent {
  const SelectSectionIntent(this.index);

  final int index;
}

/// The window's keys: Command on a Mac, Control on Windows and Linux.
abstract final class WindowShortcuts {
  /// How many sections have a digit.
  static const sectionCount = 6;

  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];

  static Map<ShortcutActivator, Intent> of(TargetPlatform platform) => {
    for (final command in WindowCommand.values)
      ?activatorOf(command, platform): WindowCommandIntent(command),
    for (var index = 0; index < sectionCount; index++)
      sectionActivator(index, platform): SelectSectionIntent(index),
  };

  static SingleActivator sectionActivator(int index, TargetPlatform platform) =>
      _primary(_digits[index], platform);

  /// The key for [command] on [platform], or null when it has none.
  static SingleActivator? activatorOf(
    WindowCommand command,
    TargetPlatform platform,
  ) => switch (command) {
    .addDevice => _primary(LogicalKeyboardKey.keyN, platform),
    .sendFiles => _primary(LogicalKeyboardKey.keyO, platform),
    .sendClipboard => _primary(LogicalKeyboardKey.keyV, platform, shift: true),
    .takePhoto => switch (platform) {
      .macOS || .iOS => const SingleActivator(
        LogicalKeyboardKey.keyP,
        meta: true,
        control: true,
      ),
      .windows || .linux || .android || .fuchsia => const SingleActivator(
        LogicalKeyboardKey.keyP,
        control: true,
        alt: true,
      ),
    },
    .openSettings => _primary(LogicalKeyboardKey.comma, platform),
    .openActivity => _primary(LogicalKeyboardKey.keyA, platform, shift: true),
    .toggleSidebar => switch (platform) {
      .macOS || .iOS => const SingleActivator(
        LogicalKeyboardKey.keyS,
        meta: true,
        control: true,
      ),
      .linux => const SingleActivator(LogicalKeyboardKey.f9),
      .windows || .android || .fuchsia => const SingleActivator(
        LogicalKeyboardKey.keyB,
        control: true,
      ),
    },
    .toggleActivityPane => _primary(
      LogicalKeyboardKey.digit0,
      platform,
      alt: true,
    ),
    .nextDevice => _primary(LogicalKeyboardKey.arrowDown, platform, alt: true),
    .previousDevice => _primary(
      LogicalKeyboardKey.arrowUp,
      platform,
      alt: true,
    ),
    .back => _primary(LogicalKeyboardKey.bracketLeft, platform),
    .fixConnection || .sponsor => null,
    // A Mac gets Help and Quit from its menu bar.
    .showShortcuts => switch (platform) {
      .macOS || .iOS => null,
      _ => const SingleActivator(
        LogicalKeyboardKey.slash,
        control: true,
        shift: true,
      ),
    },
    .quit => switch (platform) {
      .macOS || .iOS => null,
      _ => const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
    },
  };

  /// How [activator] is written on [platform]: "⇧⌘V" on a Mac,
  /// "Ctrl+Shift+V" elsewhere. Ctrl+Shift+/ reads as "Ctrl+?", the way
  /// GNOME writes it.
  static String describe(SingleActivator activator, TargetPlatform platform) {
    final key = _keyName(activator);
    if (platform == .macOS || platform == .iOS) {
      return [
        if (activator.control) '⌃',
        if (activator.alt) '⌥',
        if (activator.shift) '⇧',
        if (activator.meta) '⌘',
        key,
      ].join();
    }

    final isQuestion =
        activator.trigger == LogicalKeyboardKey.slash && activator.shift;
    return [
      if (activator.control) 'Ctrl',
      if (activator.alt) 'Alt',
      if (activator.shift && !isQuestion) 'Shift',
      switch (isQuestion) {
        true => '?',
        false => key,
      },
    ].join('+');
  }

  /// [label] with the keys that do the same after it, for a tooltip:
  /// "Add a device (⌘N)". Just [label] where there are no keys.
  static String hint(
    String label,
    SingleActivator? activator,
    TargetPlatform platform,
  ) => switch (activator) {
    final SingleActivator activator =>
      '$label (${describe(activator, platform)})',
    null => label,
  };

  static String _keyName(SingleActivator activator) =>
      switch (activator.trigger) {
        LogicalKeyboardKey.arrowDown => '↓',
        LogicalKeyboardKey.arrowUp => '↑',
        LogicalKeyboardKey.comma => ',',
        LogicalKeyboardKey.bracketLeft => '[',
        LogicalKeyboardKey.slash => '/',
        final key => key.keyLabel.toUpperCase(),
      };

  static SingleActivator _primary(
    LogicalKeyboardKey key,
    TargetPlatform platform, {
    bool shift = false,
    bool alt = false,
  }) {
    final usesCommand = platform == .macOS || platform == .iOS;

    return SingleActivator(
      key,
      meta: usesCommand,
      control: !usesCommand,
      shift: shift,
      alt: alt,
    );
  }
}
