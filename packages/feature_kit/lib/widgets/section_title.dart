import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/text_link.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A small heading above a group, such as "Your devices". It starts where
/// the text of the rows under it starts.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.badge});

  final String text;
  final Widget? trailing;

  /// A small widget right after the title, such as a `BetaTag`.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
      fontWeight: .w600,
    );

    // The line is as high as a link at its end, with or without one, so
    // the title doesn't move when "See all" comes and goes. The space
    // around it is that much less: 16 above the words, 8 below, as drawn.
    // The space goes around each end rather than the row, so a finger's
    // target on the link reaches over all of it.
    final band = EdgeInsets.only(top: Spacing.d12, bottom: Spacing.d4);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: PageInsets.row),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: band,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: TextLink.minHeight),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  heightFactor: 1,
                  // A heading of its own, so TalkBack can jump between
                  // sections, and the title isn't read as the first words
                  // of the card under it.
                  child: Semantics(
                    container: true,
                    header: true,
                    child: switch (badge) {
                      final badge? => Row(
                        children: [
                          Flexible(child: Text(text, style: style)),
                          Spacing.h8,
                          badge,
                        ],
                      ),
                      null => Text(text, style: style),
                    },
                  ),
                ),
              ),
            ),
          ),
          if (trailing case final trailing?)
            Padding(padding: band, child: trailing),
        ],
      ),
    );
  }
}
