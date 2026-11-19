import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A command line shown word for word, in fixed-width letters on its own
/// tile, so nothing in it can pass for Ferret's own words.
class CommandBlock extends StatelessWidget {
  const CommandBlock(this.commandLine, {super.key});

  final String commandLine;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.text.withValues(alpha: 0.06),
        shape: Corners.shape(Corners.tile),
      ),
      child: Padding(
        padding: EdgeInsets.all(Spacing.d8),
        child: Text(
          commandLine,
          style: context.fluffyTheme.typography.caption1.copyWith(
            color: palette.text,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Menlo', 'Consolas', 'DejaVu Sans Mono'],
          ),
        ),
      ),
    );
  }
}
