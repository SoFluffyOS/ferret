import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Every key the window answers to, written the way this computer writes
/// them. On a Mac, also the keys that work from any app: the ones set in
/// Settings → Advanced ("Off" when turned off) and each feature's own.
class KeyboardShortcutsPage extends StatelessWidget {
  const KeyboardShortcutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final platform = defaultTargetPlatform;
    final first = WindowShortcuts.describe(
      WindowShortcuts.sectionActivator(0, platform),
      platform,
    );
    final last = WindowShortcuts.describe(
      WindowShortcuts.sectionActivator(
        WindowShortcuts.sectionCount - 1,
        platform,
      ),
      platform,
    );
    final rows = [
      ('$first … $last', l10n.shortcutSections),
      for (final command in WindowCommand.values)
        if (WindowShortcuts.activatorOf(command, platform) case final key?)
          (
            WindowShortcuts.describe(key, platform),
            WindowCommands.label(l10n, command),
          ),
    ];

    final menubar = context.read<FerretMenubar?>();
    if (menubar == null || !menubar.isSupported) {
      return FerretPage(
        title: l10n.shortcutsTitle,
        backLabel: l10n.back,
        children: [_ShortcutCard(rows)],
      );
    }

    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) => FerretPage(
        title: l10n.shortcutsTitle,
        backLabel: l10n.back,
        children: [
          SectionTitle(l10n.shortcutsInWindow),
          _ShortcutCard(rows),
          Spacing.v8,
          SectionTitle(l10n.shortcutsAnyApp),
          _ShortcutCard(_anyAppRows(context, scope)),
        ],
      ),
    );
  }

  List<(String, String)> _anyAppRows(BuildContext context, ShellScope scope) {
    final l10n = context.shellL10n;
    final settings = scope.featureContext.engine.settings;
    String keysOf(MenubarShortcut? shortcut) => switch (shortcut) {
      final shortcut? => shortcut.label,
      null => l10n.settingsShortcutOff,
    };

    return [
      (keysOf(GlobalShortcut.read(settings)), l10n.menuOpen),
      (
        keysOf(
          GlobalShortcut.read(
            settings,
            key: GlobalShortcut.clipsKey,
            fallback: GlobalShortcut.recentClips,
          ),
        ),
        l10n.shortcutRecentClips,
      ),
      for (final feature in scope.features)
        for (final shortcut in feature.globalShortcuts(
          context,
          scope.featureContext,
        ))
          (shortcut.keys, shortcut.label),
    ];
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard(this.rows);

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          for (final (keys, label) in rows) _ShortcutRow(keys, label),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow(this.keys, this.label);

  final String keys;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.d6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: typography.base2.copyWith(color: palette.text),
              ),
            ),
            Spacing.h16,
            Text(
              keys,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
