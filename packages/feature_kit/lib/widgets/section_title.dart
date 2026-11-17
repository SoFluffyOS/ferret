import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A small heading above a group, such as "Your devices".
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: context.palette.mutedText,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.d4,
        Spacing.d16,
        Spacing.d4,
        Spacing.d8,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: style)),
          ?trailing,
        ],
      ),
    );
  }
}
