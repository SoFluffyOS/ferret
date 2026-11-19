import 'package:feature_kit/layout/page_insets.dart';
import 'package:feature_kit/theme/theme.dart';
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

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        PageInsets.row,
        Spacing.d16,
        PageInsets.row,
        Spacing.d8,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: style)),
          ?trailing,
        ],
      ),
    );
  }
}
