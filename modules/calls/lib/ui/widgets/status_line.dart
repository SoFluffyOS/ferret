import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// How a status line looks.
enum StatusTone { good, warning, neutral }

/// A short status with a coloured dot, such as "Names and photos".
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.text, required this.tone});

  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final color = switch (tone) {
      .good => palette.success,
      .warning => palette.danger,
      .neutral => palette.mutedText,
    };

    return Row(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Spacing.d6),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: .circle),
            child: SizedBox.square(dimension: Spacing.d8),
          ),
        ),
        Spacing.h8,
        Expanded(
          child: Text(
            text,
            style: typography.body2.copyWith(color: palette.text),
          ),
        ),
      ],
    );
  }
}
