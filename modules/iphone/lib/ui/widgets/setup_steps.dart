import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Numbered steps, such as how to pair the iPhone.
class SetupSteps extends StatelessWidget {
  const SetupSteps({super.key, required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(title, style: typography.base1.copyWith(color: palette.text)),
        for (final (index, step) in steps.indexed) ...[
          Spacing.v6,
          Row(
            crossAxisAlignment: .start,
            children: [
              SizedBox(
                width: Spacing.d18,
                child: Text(
                  '${index + 1}.',
                  style: typography.body2.copyWith(color: palette.link),
                ),
              ),
              Expanded(
                child: Text(
                  step,
                  style: typography.body2.copyWith(color: palette.text),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
