import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One thing a tier adds: a check when the phone has it, a lock when not.
class PerkLine extends StatelessWidget {
  const PerkLine({super.key, required this.label, required this.isOn});

  final String label;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d4),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Spacing.d2),
            child: Icon(
              switch (isOn) {
                true => LucideIcons.check,
                false => LucideIcons.lock,
              },
              size: Spacing.d12,
              color: switch (isOn) {
                true => palette.success,
                false => palette.mutedText,
              },
            ),
          ),
          Spacing.h8,
          Expanded(
            child: Text(
              label,
              style: typography.caption1.copyWith(
                color: switch (isOn) {
                  true => palette.text,
                  false => palette.mutedText,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
