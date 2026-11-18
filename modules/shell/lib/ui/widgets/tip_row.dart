import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One thing to try, shown once: a short line with an icon and a way to
/// wave it off.
class TipRow extends StatelessWidget {
  const TipRow({
    super.key,
    required this.icon,
    required this.text,
    this.dismissLabel,
    this.onDismiss,
  });

  final IconData icon;
  final String text;
  final String? dismissLabel;

  /// Null while the tip says goodbye by itself.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.d12,
        Spacing.d2,
        Spacing.d8,
        Spacing.d8,
      ),
      child: Row(
        children: [
          Icon(icon, size: Spacing.d16, color: palette.accent),
          Spacing.h12,
          Expanded(
            child: Text(
              text,
              style: context.fluffyTheme.typography.base2.copyWith(
                color: palette.text,
              ),
            ),
          ),
          if (onDismiss != null)
            Tappable(
              tooltip: dismissLabel,
              onTap: onDismiss,
              child: Padding(
                padding: EdgeInsets.all(Spacing.d4),
                child: Icon(
                  LucideIcons.x,
                  size: Spacing.d14,
                  color: palette.mutedText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
