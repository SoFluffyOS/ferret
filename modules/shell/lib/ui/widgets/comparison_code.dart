import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Six digits shown big, split in two groups so they are easy to compare.
class ComparisonCode extends StatelessWidget {
  const ComparisonCode({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final style = context.fluffyTheme.typography.headline3.copyWith(
      color: context.palette.text,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: Spacing.d4,
    );
    final grouped = switch (code.length == 6) {
      true => '${code.substring(0, 3)} ${code.substring(3)}',
      false => code,
    };

    return Center(child: Text(grouped, style: style));
  }
}
