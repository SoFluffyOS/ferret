import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Every key the window answers to, written the way this computer writes
/// them.
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

    return FerretPage(
      title: l10n.shortcutsTitle,
      backLabel: l10n.back,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              for (final (keys, label) in rows) _ShortcutRow(keys, label),
            ],
          ),
        ),
      ],
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
