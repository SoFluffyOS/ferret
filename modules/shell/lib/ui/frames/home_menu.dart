import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Home's "more" menu: pause for a while (or resume), the desktop window on
/// a Mac, Settings, and Quit.
/// A menu, so nothing has to float over the popover to pause.
class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key, required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final isPaused = context.select<PauseController, bool>(
      (controller) => controller.isPaused,
    );
    final pause = context.read<PauseController>();
    final canOpenWindow = context.select<AppViews?, bool>(
      (views) => views?.canOpenWindow ?? false,
    );
    final l10n = context.shellL10n;
    final canQuit = defaultTargetPlatform != .iOS;

    return MenuButton(
      icon: LucideIcons.ellipsis,
      tooltip: l10n.homeMore,
      entries: [
        if (isPaused)
          MenuEntry(
            label: l10n.resume,
            icon: LucideIcons.play,
            onSelected: () => unawaited(pause.resume()),
          ),
        if (!isPaused) ...[
          MenuEntry(
            label: l10n.pauseOneHour,
            icon: LucideIcons.pause,
            onSelected: () =>
                unawaited(pause.pause(duration: const Duration(hours: 1))),
          ),
          MenuEntry(
            label: l10n.pauseUntilTomorrow,
            onSelected: () =>
                unawaited(pause.pause(duration: _untilTomorrowMorning())),
          ),
          MenuEntry(
            label: l10n.pauseUntilResume,
            onSelected: () => unawaited(pause.pause()),
          ),
        ],
        if (canOpenWindow)
          MenuEntry(
            label: l10n.homeOpenWindow,
            icon: LucideIcons.appWindow,
            startsGroup: true,
            onSelected: () => unawaited(context.read<AppViews>().openWindow()),
          ),
        MenuEntry(
          label: l10n.settingsTitle,
          icon: LucideIcons.settings,
          startsGroup: !canOpenWindow,
          onSelected: onSettings,
        ),
        if (canQuit)
          MenuEntry(
            label: l10n.settingsQuit,
            icon: LucideIcons.power,
            onSelected: () => unawaited(SystemNavigator.pop()),
          ),
      ],
    );
  }

  Duration _untilTomorrowMorning() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 8).difference(now);
  }
}
