import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A row that opens a page: what it is, its current state as the value, and
/// a chevron. A list of these is also a status page.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.title,
    required this.onTap,
    this.value = '',
    this.attentionLabel,
  });

  final String title;

  /// The current state in a few words, such as "To Downloads", or empty.
  final String value;
  final VoidCallback onTap;

  /// When set, a small warning dot sits before the value: something the
  /// person turned on isn't working. Read out by screen readers.
  final String? attentionLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Tappable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d4,
          vertical: Spacing.d10,
        ),
        child: Row(
          children: [
            Text(title, style: typography.base2.copyWith(color: palette.text)),
            Spacing.h12,
            Expanded(
              child: Text(
                value,
                textAlign: .end,
                overflow: .ellipsis,
                maxLines: 1,
                style: typography.base2.copyWith(color: palette.mutedText),
              ),
            ),
            if (attentionLabel case final label?) ...[
              Spacing.h6,
              Semantics(
                label: label,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.warning,
                    shape: .circle,
                  ),
                  child: SizedBox.square(dimension: Spacing.d8),
                ),
              ),
            ],
            Spacing.h6,
            Icon(
              LucideIcons.chevronRight,
              size: Spacing.d16,
              color: palette.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
