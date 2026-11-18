import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting that is on or off: what it does, a line of detail, a switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                title,
                style: typography.base2.copyWith(color: palette.text),
              ),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
            ],
          ),
        ),
        Spacing.h12,
        SwitchToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}
