import 'package:feature_kit/feature_kit.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/models/models.dart';
import 'package:find/ui/widgets/find_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One ring to another device: where it stands, why it failed, and Stop,
/// Ring again or Dismiss.
class OutgoingRingRow extends StatelessWidget {
  const OutgoingRingRow({
    super.key,
    required this.ring,
    required this.onStop,
    required this.onRingAgain,
    required this.onDismiss,
  });

  final OutgoingRing ring;
  final VoidCallback onStop;
  final VoidCallback onRingAgain;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.findL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final detail = l10n.outgoingDetail(ring);
    final iconColor = switch (ring.phase) {
      .found => palette.success,
      _ when ring.phase.isProblem => palette.danger,
      _ => palette.text,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Icon(
              outgoingIcon(ring.phase),
              size: Spacing.d20,
              color: iconColor,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    l10n.outgoingTitle(ring),
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                  if (detail != null) ...[
                    Spacing.vertical(Spacing.d2),
                    Text(
                      detail,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!ring.isActive)
              Tappable(
                tooltip: l10n.dismiss,
                onTap: onDismiss,
                child: Padding(
                  padding: EdgeInsets.all(Spacing.d4),
                  child: Icon(
                    LucideIcons.x,
                    size: Spacing.d16,
                    color: palette.mutedText,
                  ),
                ),
              ),
          ],
        ),
        Spacing.v8,
        _action(l10n),
      ],
    );
  }

  Widget _action(FindLocalizations l10n) {
    if (ring.isActive) {
      return Button(
        variant: .secondary,
        label: l10n.stop,
        icon: Icon(LucideIcons.bellOff, size: Spacing.d16),
        onPressed: onStop,
      );
    }

    return Button(
      variant: .ghost,
      label: l10n.ringAgain,
      icon: Icon(LucideIcons.bellRing, size: Spacing.d16),
      onPressed: onRingAgain,
    );
  }
}
