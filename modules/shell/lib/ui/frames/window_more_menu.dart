import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Windows and Linux have no menu bar, so the window's ••• holds its
/// commands, each with its keys next to it, ending with the list of all
/// keys and Quit.
class WindowMoreMenu extends StatelessWidget {
  const WindowMoreMenu({super.key});

  static const _groups = [
    [
      WindowCommand.addDevice,
      WindowCommand.sendFiles,
      WindowCommand.sendClipboard,
      WindowCommand.takePhoto,
    ],
    [
      WindowCommand.openActivity,
      WindowCommand.openSettings,
      WindowCommand.toggleSidebar,
      WindowCommand.toggleActivityPane,
    ],
    [WindowCommand.fixConnection, WindowCommand.showShortcuts],
    [WindowCommand.quit],
  ];

  @override
  Widget build(BuildContext context) {
    final commands = context.select<WindowCommands?, WindowCommands?>(
      (commands) => commands,
    );
    if (commands == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;
    final platform = defaultTargetPlatform;
    final entries = <MenuEntry>[];
    for (final group in _groups) {
      var startsGroup = entries.isNotEmpty;
      for (final command in group) {
        final action = commands[command];
        if (action == null) {
          continue;
        }

        entries.add(
          MenuEntry(
            label: commands.labelOf(l10n, command),
            shortcut: switch (WindowShortcuts.activatorOf(command, platform)) {
              final SingleActivator key => WindowShortcuts.describe(
                key,
                platform,
              ),
              null => null,
            },
            startsGroup: startsGroup,
            onSelected: action,
          ),
        );
        startsGroup = false;
      }

      if (group == _groups.first) {
        entries.addAll(_featureEntries(context));
      }
    }

    return MenuButton(
      icon: LucideIcons.ellipsis,
      tooltip: l10n.homeMore,
      opensRight: true,
      entries: entries,
    );
  }

  List<MenuEntry> _featureEntries(BuildContext context) {
    final scope = ShellScope.maybeOf(context);
    final actions = [
      if (scope != null)
        for (final feature in scope.features)
          ...feature.appActions(context, scope.featureContext),
    ];

    return [
      for (final (index, action) in actions.indexed)
        MenuEntry(
          label: action.label,
          startsGroup: index == 0,
          onSelected: action.onPressed ?? () {},
        ),
    ];
  }
}
