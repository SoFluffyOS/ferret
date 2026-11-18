import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/window_intents.dart';

/// What each window command does right now, for the menus that sit outside
/// the window's key handling. A null action can't apply at the moment.
class WindowCommands {
  const WindowCommands(this._actions);

  final Map<WindowCommand, VoidCallback?> _actions;

  VoidCallback? operator [](WindowCommand command) => _actions[command];

  /// The command's name in menus and the shortcuts list.
  static String label(ShellLocalizations l10n, WindowCommand command) =>
      switch (command) {
        .addDevice => l10n.menuPair,
        .sendFiles => l10n.menuSendFiles,
        .sendClipboard => l10n.menuSendClipboard,
        .openSettings => l10n.settingsTitle,
        .openActivity => l10n.activityTitle,
        .toggleSidebar => l10n.shortcutSidebar,
        .toggleActivityPane => l10n.shortcutActivityPane,
        .nextDevice => l10n.menuNextDevice,
        .previousDevice => l10n.menuPreviousDevice,
        .back => l10n.menuBack,
        .fixConnection => l10n.menuFixConnection,
        .showShortcuts => l10n.menuKeyboardShortcuts,
        .quit => l10n.menuQuit,
      };
}
