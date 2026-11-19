import 'package:feature_kit/layout/corners.dart';
import 'package:feature_kit/layout/page_insets.dart';
import 'package:feature_kit/layout/text_size_context.dart';
import 'package:feature_kit/theme/theme.dart';
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
        switch (tag) {
          final tag? => Wrap(
            spacing: Spacing.d8,
            runSpacing: Spacing.d4,
            crossAxisAlignment: .center,
            children: [
              titleText,
              Tag(tag, color: palette.warning),
            ],
          ),
          null => titleText,
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
          vertical: Spacing.d8,
        ),
        child: Row(
          children: [
            if (leading case final leading?) ...[leading, Spacing.h12],
            ...switch (stacksValue || !hasValue) {
              true => [Expanded(child: text)],
              false => [
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
            if (trailing case final trailing?) ...[Spacing.h8, trailing],
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
      child: Tappable(
        semanticButton: true,
        onTap: onTap,
        focusNode: focusNode,
        enableAnimation: false,
        enableHover: true,
        // The row draws its own ring, inside the card's corners.
        enableFocusBorder: false,
        builder: (context, state) => DecoratedBox(
          position: .foreground,
          decoration: ShapeDecoration(
            shape: Corners.shape(
              Corners.card,
              side: switch (state) {
                .focus => BorderSide(
                  color: palette.accent,
                  width: Spacing.d2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                _ => BorderSide.none,
              },
            ),
          ),
          child: ColoredBox(color: _fill(palette, state), child: row),
        ),
      ),
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
