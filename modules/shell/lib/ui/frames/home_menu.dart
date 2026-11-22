import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
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
    final scope = ShellScope.maybeOf(context);
    final featureActions = [
      if (scope != null)
        for (final feature in scope.features)
          ...feature.appActions(context, scope.featureContext),
    ];

    // At the header's end: its glyph and its menu line up with the cards.
    return HeaderIconButton(
      icon: LucideIcons.ellipsis,
      tooltip: l10n.homeMore,
      nudge: HeaderIconButton.endNudge,
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
        for (final (index, action) in featureActions.indexed)
          MenuEntry(
            label: WindowCommands.buttonInMenu(l10n, action.fullLabel),
            icon: action.icon,
            startsGroup: index == 0,
            onSelected: action.onPressed ?? () {},
          ),
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
            label: switch (defaultTargetPlatform) {
              // The service keeps Ferret running after the screen closes.
              .android => l10n.settingsClose,
              _ => l10n.settingsQuit,
            },
            icon: switch (defaultTargetPlatform) {
              .android => LucideIcons.x,
              _ => LucideIcons.power,
            },
            onSelected: () => unawaited(context.read<AppQuit>().quit()),
          ),
      ],
    );
  }

  Duration _untilTomorrowMorning() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 8).difference(now);
  }
}
