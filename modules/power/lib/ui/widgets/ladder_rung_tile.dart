import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:power/ui/widgets/perk_line.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One step of the ladder: its name, whether it is on, and what it adds.
/// A cell of a `GroupedCard`.
class LadderRungTile extends StatelessWidget {
  const LadderRungTile({
    super.key,
    required this.title,
    required this.stateLabel,
    required this.isOn,
    required this.perks,
    this.children = const [],
  });

  final String title;

  /// Such as "On" or "Not on yet".
  final String stateLabel;
  final bool isOn;
  final List<String> perks;

  /// What to do about a rung that is off, such as a hint and a button.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return GroupedCell(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
              ),
              Spacing.h12,
              Text(
                stateLabel,
                style: typography.caption1.copyWith(
                  color: switch (isOn) {
                    true => palette.success,
                    false => palette.mutedText,
                  },
                ),
              ),
            ],
          ),
          for (final perk in perks) PerkLine(label: perk, isOn: isOn),
          ...children,
        ],
      ),
    );
  }
}
