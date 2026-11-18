import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Something the window can be told to do, from a key, a menu or a button.
enum WindowCommand {
  addDevice,
  sendFiles,
  sendClipboard,
  openSettings,
  openActivity,
  toggleSidebar,
  nextDevice,
  previousDevice,
  back,
  fixConnection,
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
    .nextDevice => _primary(LogicalKeyboardKey.arrowDown, platform, alt: true),
    .previousDevice => _primary(
      LogicalKeyboardKey.arrowUp,
      platform,
      alt: true,
    ),
    .back => _primary(LogicalKeyboardKey.bracketLeft, platform),
    .fixConnection => null,
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
