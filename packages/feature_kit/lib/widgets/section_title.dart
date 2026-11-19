import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/text_link.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A small heading above a group, such as "Your devices". It starts where
/// the text of the rows under it starts.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
      fontWeight: .w600,
    );

    // The line is as high as a link at its end, with or without one, so
    // the title doesn't move when "See all" comes and goes. The space
    // around it is that much less: 16 above the words, 8 below, as drawn.
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        PageInsets.row,
        Spacing.d12,
        PageInsets.row,
        Spacing.d4,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: TextLink.minHeight),
        child: Row(
          children: [
            Expanded(child: Text(text, style: style)),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
