import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/window_intents.dart';

/// What each window command does right now, for the menus that sit outside
/// the window's key handling. A null action can't apply at the moment.
class WindowCommands {
  const WindowCommands(this._actions, {Map<WindowCommand, String>? labels})
    : _labels = labels ?? const {};

  final Map<WindowCommand, VoidCallback?> _actions;
  final Map<WindowCommand, String> _labels;

  VoidCallback? operator [](WindowCommand command) => _actions[command];

  /// The command's name in a menu right now, such as "Take Photo with
  /// Pixel 7" when it acts on one device.
  String labelOf(ShellLocalizations l10n, WindowCommand command) =>
      _labels[command] ?? label(l10n, command);

  /// The command's name in menus and the shortcuts list.
  static String label(ShellLocalizations l10n, WindowCommand command) =>
      switch (command) {
        .addDevice => l10n.menuPair,
        .sendFiles => l10n.menuSendFiles,
        .sendClipboard => l10n.menuSendClipboard,
        .takePhoto => l10n.menuTakePhoto,
        .openSettings => l10n.settingsTitle,
        .openActivity => l10n.activityTitle,
        .toggleSidebar => l10n.shortcutSidebar,
        .toggleActivityPane => l10n.shortcutActivityPane,
        .nextDevice => l10n.menuNextDevice,
        .previousDevice => l10n.menuPreviousDevice,
        .back => l10n.menuBack,
        .fixConnection => l10n.menuFixConnection,
        .showShortcuts => l10n.menuKeyboardShortcuts,
        .sponsor => l10n.menuSponsor,
        .quit => l10n.menuQuit,
      };
}
