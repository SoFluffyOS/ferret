import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/beside_or_below.dart';
import 'package:feature_kit/widgets/focus_rings.dart';
import 'package:feature_kit/widgets/grouped_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One row of a `GroupedCard`: what it is, a line of detail under it, its
/// current state as the value, and a control or a chevron at the end.
/// Every row in Settings is this one, on a phone, in the popover and in a
/// window.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    this.badge,
    this.titleMaxLines,
    this.leading,
    this.value = '',
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.focusNode,
  });

  final String title;

  /// Cuts a title that may be long, such as an app's name. Left out, the
  /// title wraps.
  final int? titleMaxLines;

  /// A line that explains the row, under the title.
  final String? subtitle;

  /// A word next to the title, such as "Experimental".
  final String? tag;

  /// A small widget next to the title, such as a `BetaTag`.
  final Widget? badge;

  /// At the start of the row, such as an `IconTile`.
  final Widget? leading;

  /// The current state in a few words, such as "To Downloads", or empty.
  final String value;

  /// At the end of the row: a switch, a button, a chevron.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The row whose page shows next to the list. It stays filled.
  final bool isSelected;
  final FocusNode? focusNode;

  static double get _vertical => Spacing.d8;

  static bool get _isTouch => switch (defaultTargetPlatform) {
    .android || .iOS || .fuchsia => true,
    .macOS || .windows || .linux => false,
  };

  /// Rows are a finger high on touch screens (48 on Android, 44 on an
  /// iPhone, as each asks), and denser under a pointer.
  static double get minHeight => switch (defaultTargetPlatform) {
    .android || .fuchsia => Spacing.d48,
    .iOS => Spacing.d44,
    .macOS || .windows || .linux => Spacing.d36,
  };

  /// A row's title: body text on touch screens, a size down under a
  /// pointer. For a custom row that sits among these.
  static TextStyle titleStyleOf(BuildContext context) {
    final typography = context.fluffyTheme.typography;

    return switch (_isTouch) {
      true => typography.base1,
      false => typography.base2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final titleStyle = titleStyleOf(context).copyWith(color: palette.text);
    // The grey of a detail line is too faint on the selected row's fill.
    final detailColor = switch (isSelected) {
      true => palette.text,
      false => palette.mutedText,
    };
    final mutedStyle = typography.caption1.copyWith(color: detailColor);
    final valueStyle = typography.base2.copyWith(color: detailColor);
    // Side by side, the value is cut to a few letters once text is set
    // large, so it goes under the title there.
    final stacksValue = context.hasLargeText || subtitle != null;
    final hasValue = value.isNotEmpty;

    final titleText = Text(
      title,
      style: titleStyle,
      maxLines: titleMaxLines,
      overflow: switch (titleMaxLines) {
        null => null,
        _ => TextOverflow.ellipsis,
      },
    );
    final text = Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        switch ((tag, badge)) {
          (null, null) => titleText,
          (final tag, final badge) => Wrap(
            spacing: Spacing.d8,
            runSpacing: Spacing.d4,
            crossAxisAlignment: .center,
            children: [
              titleText,
              if (tag != null) Tag(tag, color: palette.warning),
              ?badge,
            ],
          ),
        },
        if (subtitle case final subtitle?) ...[
          Spacing.vertical(Spacing.d2),
          Text(subtitle, style: mutedStyle),
        ],
        if (stacksValue && hasValue)
          Text(value, overflow: .ellipsis, maxLines: 2, style: valueStyle),
      ],
    );

    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PageInsets.row,
          vertical: _vertical,
        ),
        child: Row(
          children: [
            if (leading case final leading?) ...[leading, Spacing.h12],
            // On a phone a wide control goes under the words instead of
            // squeezing them (a long label at 130% on a 320 dp screen).
            ...switch ((stacksValue || !hasValue, trailing)) {
              (true, final trailing?) when _isTouch => [
                Expanded(
                  child: BesideOrBelow(
                    gap: Spacing.d8,
                    children: [text, _inCorner(context, trailing)],
                  ),
                ),
              ],
              (true, _) => [Expanded(child: text)],
              (false, _) => [
                text,
                Spacing.h12,
                Expanded(
                  child: Text(
                    value,
                    textAlign: .end,
                    overflow: .ellipsis,
                    maxLines: 1,
                    style: valueStyle,
                  ),
                ),
              ],
            },
            if (trailing case final trailing?
                when !_isTouch || (!stacksValue && hasValue)) ...[
              Spacing.h8,
              _inCorner(context, trailing),
            ],
          ],
        ),
      ),
    );

    final onTap = this.onTap;
    if (onTap == null) {
      return ColoredBox(color: _fill(palette, .normal), child: row);
    }

    return Semantics(
      selected: switch (isSelected) {
        true => true,
        false => null,
      },
      child: PrimaryFocusBuilder(
        focusNode: focusNode,
        builder: (context, node) => Tappable(
          semanticButton: true,
          onTap: onTap,
          focusNode: node,
          enableAnimation: false,
          enableHover: true,
          // The row draws its own ring, inside the card's corners, and
          // none while focus is on a control in it.
          enableFocusBorder: false,
          builder: (context, state) => DecoratedBox(
            position: .foreground,
            decoration: ShapeDecoration(
              shape: Corners.shape(
                Corners.card,
                side: switch (state == .focus && node.hasPrimaryFocus) {
                  true => BorderSide(
                    color: palette.accent,
                    width: Spacing.d2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  false => BorderSide.none,
                },
              ),
            ),
            child: ColoredBox(color: _fill(palette, state), child: row),
          ),
        ),
      ),
    );
  }

  /// A control at the end of the card's first or last row sits in the
  /// card's corner: as far from the card's top or bottom as from its side,
  /// so its corner is concentric with the card's. Rows whose control is
  /// shorter than the row, and every row between, keep their height, and
  /// so does a switch, as in the system's own lists: every setting row
  /// would grow on a phone for it.
  Widget _inCorner(BuildContext context, Widget trailing) {
    final edge = GroupedEdge.of(context);
    if (edge == null || !(edge.isFirst || edge.isLast)) {
      return trailing;
    }

    if (trailing is SwitchToggle) {
      return trailing;
    }

    // Both ways, so the control stays in line with the row's title.
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PageInsets.row - _vertical),
      child: trailing,
    );
  }

  Color _fill(FerretPalette palette, TappableState state) {
    if (isSelected) {
      return palette.accent.withValues(alpha: 0.18);
    }

    return switch (state) {
      .hover || .pressed => palette.text.withValues(alpha: 0.06),
      .normal || .focus => const Color(0x00000000),
    };
  }
}
