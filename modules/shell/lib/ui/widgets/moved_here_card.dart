import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says that Ferret came over from another computer and starts as a new
/// device here, and which devices to pair again.
class MovedHereCard extends StatelessWidget {
  const MovedHereCard({
    super.key,
    required this.here,
    required this.names,
    required this.onDismiss,
  });

  /// The kind of device this is, for the title's "this Mac".
  final String here;

  /// The devices to pair again, such as "Pixel 7".
  final List<String> names;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final muted = typography.base2.copyWith(color: palette.mutedText);

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              l10n.movedTitle(here),
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.v4,
            Text(l10n.movedBody(names.join(', ')), style: muted),
            Spacing.v8,
            Text(l10n.movedReplaceHint, style: muted),
            Spacing.v12,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GhostButton(
                mainAxisSize: .min,
                label: l10n.movedDismiss,
                onPressed: onDismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
