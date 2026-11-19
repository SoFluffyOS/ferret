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
    this.place,
    this.isSelected = false,
    this.showsChevron = true,
  });

  final String title;

  /// The current state in a few words, such as "To Downloads", or empty.
  /// A row with a [place] shows it under the title, where it is never cut.
  final String value;
  final VoidCallback onTap;

  /// When set, a small warning dot sits before the chevron: something the
  /// person turned on isn't working. Read out by screen readers.
  final String? attentionLabel;

  /// The row's icon and colour, for a row of Settings.
  final ({IconData icon, PlaceColor color})? place;

  /// The row whose page shows next to the list.
  final bool isSelected;

  /// Left out where the page opens next to the list instead of over it.
  final bool showsChevron;

  /// Where the lines between rows with a [place] start: at their text.
  static double get placeIndent => PageInsets.row + IconTile.size + Spacing.d12;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final place = this.place;
    final hasTrailing = showsChevron || attentionLabel != null;

    return GroupedRow(
      title: title,
      leading: switch (place) {
        final place? => IconTile(icon: place.icon, color: place.color),
        null => null,
      },
      subtitle: switch ((place, value)) {
        (null, _) || (_, '') => null,
        (_, final value) => value,
      },
      value: switch (place) {
        null => value,
        _ => '',
      },
      isSelected: isSelected,
      onTap: onTap,
      trailing: switch (hasTrailing) {
        false => null,
        true => Row(
          mainAxisSize: .min,
          children: [
            if (attentionLabel case final label?)
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
            if (attentionLabel != null && showsChevron) Spacing.h6,
            if (showsChevron)
              DirectionalIcon(
                LucideIcons.chevronRight,
                size: Spacing.d16,
                color: palette.mutedText,
              ),
          ],
        ),
      },
    );
  }
}
