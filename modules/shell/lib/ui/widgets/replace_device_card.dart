import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Asks whether a device that was just paired replaces an older one with
/// the same name, such as a phone that was reset or swapped.
class ReplaceDeviceCard extends StatelessWidget {
  const ReplaceDeviceCard({
    super.key,
    required this.name,
    required this.oldName,
    required this.onReplace,
    required this.onKeepBoth,
  });

  /// What the new device calls itself, such as "Pixel 7".
  final String name;

  /// What the old one is called here, such as "Pixel 7 (0718)".
  final String oldName;
  final VoidCallback onReplace;
  final VoidCallback onKeepBoth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              l10n.replaceTitle(name),
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.v4,
            Text(
              l10n.replaceBody(oldName),
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
            Spacing.v12,
            Wrap(
              spacing: Spacing.d8,
              runSpacing: Spacing.d8,
              children: [
                GhostButton(
                  mainAxisSize: .min,
                  label: l10n.replaceAction,
                  onPressed: onReplace,
                ),
                GhostButton(
                  mainAxisSize: .min,
                  label: l10n.replaceKeepBoth,
                  onPressed: onKeepBoth,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
